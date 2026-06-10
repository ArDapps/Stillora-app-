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
import '../../core/design/stillora_glow.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import 'editor_state.dart';

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
  final List<double> _levels = List<double>.filled(_waveBars, 0.04);
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
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() => _phase = _Phase.permissionDenied);
        }
        return;
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
    } catch (_) {
      if (mounted) {
        _showError('Recording could not start. Please try again.');
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
    _used = true; // the media store copies it; keep the temp until then.
    await ref.read(editorControllerProvider.notifier).setNarration(path);
    if (mounted) context.pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Narration')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff0c0718), Color(0xff060611), Color(0xff030309)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(StilloraSpacing.md),
            children: [
              const _PrivacyNote(),
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
        return _PermissionDenied(onOpenSettings: openAppSettings);
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
        const _MicCircle(active: false),
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
        _MicCircle(active: !isPaused, level: _level),
        const SizedBox(height: StilloraSpacing.lg),
        Text(
          _fmt(_elapsed),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Text(
          isPaused ? 'Paused' : 'Recording…',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StilloraSpacing.md),
        _WaveMeter(levels: _levels, active: !isPaused),
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
    return Column(
      children: [
        StilloraGlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filled(
                    onPressed: _togglePlayback,
                    icon: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(width: StilloraSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your narration',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Duration ${_fmt(_recordedDuration)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: StilloraColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        StilloraPrimaryButton(
          onPressed: _useRecording,
          icon: Icons.check_rounded,
          label: 'Use This Recording',
        ),
        const SizedBox(height: StilloraSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reRecord,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Re-record'),
              ),
            ),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _removeAudio,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove Audio'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(StilloraRadius.xl),
        border: Border.all(color: StilloraColors.glassStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.lock_rounded,
              color: Color(0xff22d3ee),
              size: 20,
            ),
            const SizedBox(width: StilloraSpacing.sm),
            Expanded(
              child: Text(
                'Your recording stays on your device and is used only to create '
                'your video.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onOpenSettings});

  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.mic_off_rounded,
            color: StilloraColors.error,
            size: 44,
          ),
          const SizedBox(height: StilloraSpacing.sm),
          Text(
            'Microphone access is off',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: StilloraSpacing.xs),
          Text(
            'Stillora needs microphone access to record your narration. Turn it '
            'on in Settings, then come back to record.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StilloraColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          StilloraPrimaryButton(
            onPressed: () => onOpenSettings(),
            icon: Icons.settings_rounded,
            label: 'Open Settings',
          ),
        ],
      ),
    );
  }
}

class _MicCircle extends StatelessWidget {
  const _MicCircle({required this.active, this.level = 0});

  final bool active;

  /// Live input level (0..1); the circle and its glow swell with the voice.
  final double level;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StilloraPulse(
        builder: (context, t) {
          final glow = active ? t : 0.0;
          final voice = active ? level : 0.0;
          return AnimatedScale(
            scale: 1 + voice * 0.12,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 132,
              height: 132,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: stilloraBrandGradient,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffd946ef).withValues(
                      alpha: 0.25 + glow * 0.25 + voice * 0.4,
                    ),
                    blurRadius: 28 + glow * 18 + voice * 30,
                    spreadRadius: 2 + voice * 6,
                  ),
                ],
              ),
              child: Icon(
                active ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A live audio waveform driven by the recorder's amplitude. Each bar animates
/// to its target height so the row ripples as the user speaks.
class _WaveMeter extends StatelessWidget {
  const _WaveMeter({required this.levels, required this.active});

  final List<double> levels;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 64.0;
    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < levels.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: 4,
              height: (8 + levels[i] * (maxHeight - 8)).clamp(4.0, maxHeight),
              decoration: BoxDecoration(
                gradient: active ? stilloraBrandGradient : null,
                color: active
                    ? null
                    : StilloraColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
