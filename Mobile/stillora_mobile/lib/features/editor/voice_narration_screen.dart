import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/desktop_shell.dart';
import 'widgets/voice_narration_widgets.dart';

enum _Phase { idle, permissionDenied, recording, paused, recorded }

class VoiceNarrationScreen extends ConsumerStatefulWidget {
  const VoiceNarrationScreen({super.key});

  static const routePath = '/voice-narration';

  @override
  ConsumerState<VoiceNarrationScreen> createState() =>
      _VoiceNarrationScreenState();
}

class _VoiceNarrationScreenState extends ConsumerState<VoiceNarrationScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Stopwatch _stopwatch = Stopwatch();

  _Phase _phase = _Phase.idle;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String? _recordingPath;
  Duration _recordedDuration = Duration.zero;
  bool _isPlaying = false;
  bool _used = false;
  bool _busy = false;

  // Live input level (0..1) and a rolling history of bars for the waveform.
  static const int _waveBars = 32;
  StreamSubscription<Amplitude>? _ampSub;
  final List<double> _levels = List<double>.filled(
    _waveBars,
    0.04,
    growable: true,
  );
  double _level = 0;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    // Drop the temp recording if the user left without using it.
    if (!_used) {
      _deleteRecordingFile();
    }
    super.dispose();
  }

  Future<void> _deleteRecordingFile() async {
    final path = _recordingPath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup; never surface a deletion failure.
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  /// Subscribes to the recorder's amplitude so the waveform reacts to the user's
  /// voice. dBFS (~-50 quiet … 0 loud) is mapped to a 0..1 bar height.
  void _startMeter() {
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 90))
        .listen((amp) {
          if (!mounted) return;
          const floor = 50.0; // dBFS below this reads as silence.
          final level = ((amp.current + floor) / floor).clamp(0.0, 1.0);
          setState(() {
            _level = level;
            _levels
              ..removeAt(0)
              ..add(0.04 + level * 0.96);
          });
        });
  }

  void _stopMeter({bool reset = false}) {
    _ampSub?.cancel();
    _ampSub = null;
    if (reset && mounted) {
      setState(() {
        _level = 0;
        for (var i = 0; i < _levels.length; i++) {
          _levels[i] = 0.04;
        }
      });
    }
  }

  Future<void> _startRecording() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // The `record` plugin manages the native mic authorization itself; on
      // desktop `permission_handler` can report "granted" without the OS having
      // actually authorized capture, so trust the recorder's own check first.
      final allowed = await _recorder.hasPermission();
      if (!allowed) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            setState(() => _phase = _Phase.permissionDenied);
          }
          return;
        }
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/stillora_narration_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      _recordingPath = path;
      _stopwatch
        ..reset()
        ..start();
      _startTicker();
      _startMeter();
      if (mounted) {
        setState(() {
          _phase = _Phase.recording;
          _elapsed = Duration.zero;
        });
      }
    } catch (e, s) {
      debugPrint('[VoiceNarration] start failed: $e\n$s');
      if (mounted) {
        _showError('Recording could not start: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pause() async {
    await _recorder.pause();
    _stopwatch.stop();
    _ticker?.cancel();
    _stopMeter();
    if (mounted) setState(() => _phase = _Phase.paused);
  }

  Future<void> _resume() async {
    await _recorder.resume();
    _stopwatch.start();
    _startTicker();
    _startMeter();
    if (mounted) setState(() => _phase = _Phase.recording);
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    _stopMeter(reset: true);
    _stopwatch.stop();
    final path = await _recorder.stop();
    _recordedDuration = _stopwatch.elapsed;
    if (path != null) {
      _recordingPath = path;
    }
    if (mounted) {
      setState(() => _phase = _Phase.recorded);
    }
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    _stopMeter(reset: true);
    _stopwatch.stop();
    try {
      await _recorder.cancel();
    } catch (_) {
      // ignore
    }
    await _deleteRecordingFile();
    _recordingPath = null;
    if (mounted) {
      setState(() {
        _phase = _Phase.idle;
        _elapsed = Duration.zero;
      });
    }
  }

  Future<void> _reRecord() async {
    await _player.stop();
    await _deleteRecordingFile();
    _recordingPath = null;
    _recordedDuration = Duration.zero;
    if (mounted) {
      setState(() {
        _phase = _Phase.idle;
        _isPlaying = false;
        _elapsed = Duration.zero;
      });
    }
  }

  Future<void> _removeAudio() async {
    await _reRecord();
    if (mounted) context.pop();
  }

  Future<void> _togglePlayback() async {
    final path = _recordingPath;
    if (path == null) return;
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(path));
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  Future<void> _useRecording() async {
    final path = _recordingPath;
    if (path == null) return;
    await _player.stop();
    _used = true; // the caller copies it out of temp; keep the file until then.
    // Return the recording path to whoever opened the recorder (Create, Speed,
    // Remove Silence, HTML…) so it can be reused everywhere, not just narration.
    if (mounted) context.pop(path);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      desktopTitle: 'Voice Narration',
      appBar: AppBar(title: const Text('Voice Narration')),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(StilloraSpacing.md),
            children: [
              const VoiceNarrationPrivacyNote(),
              const SizedBox(height: StilloraSpacing.lg),
              _buildPhase(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.permissionDenied:
        return VoiceNarrationPermissionDenied(onOpenSettings: openAppSettings);
      case _Phase.recorded:
        return _buildRecorded();
      case _Phase.recording:
      case _Phase.paused:
        return _buildRecording();
      case _Phase.idle:
        return _buildIdle();
    }
  }

  Widget _buildIdle() {
    return Column(
      children: [
        const VoiceNarrationMicCircle(active: false),
        const SizedBox(height: StilloraSpacing.lg),
        Text(
          'Record your voice',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          'Tap the button and start speaking. You can pause, re-record, or '
          'remove it before adding it to your video.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StilloraSpacing.lg),
        StilloraPrimaryButton(
          onPressed: _busy ? null : _startRecording,
          icon: Icons.fiber_manual_record_rounded,
          label: 'Start Recording',
        ),
      ],
    );
  }

  Widget _buildRecording() {
    final isPaused = _phase == _Phase.paused;
    return Column(
      children: [
        VoiceNarrationMicCircle(active: !isPaused, level: _level),
        const SizedBox(height: StilloraSpacing.lg),
        Text(
          _fmt(_elapsed),
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          isPaused ? 'Paused' : 'Recording…',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StilloraSpacing.md),
        VoiceNarrationWaveMeter(levels: _levels, active: !isPaused),
        const SizedBox(height: StilloraSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isPaused ? _resume : _pause,
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(isPaused ? 'Resume' : 'Pause'),
              ),
            ),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: _stop,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
              ),
            ),
          ],
        ),
        const SizedBox(height: StilloraSpacing.sm),
        TextButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildRecorded() {
    return VoiceNarrationRecordedPanel(
      isPlaying: _isPlaying,
      durationLabel: _fmt(_recordedDuration),
      onTogglePlayback: _togglePlayback,
      onUse: _useRecording,
      onReRecord: _reRecord,
      onRemove: _removeAudio,
    );
  }
}
