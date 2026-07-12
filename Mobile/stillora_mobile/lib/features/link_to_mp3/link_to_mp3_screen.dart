import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/platform/media_actions.dart';
import '../../core/platform/platform_info.dart';
import '../../core/widgets/ad_widget.dart';
import 'link_to_mp3_controller.dart';
import 'link_to_mp3_service.dart';

/// A selectable audio-track language. `code` is null for "Original" (let the
/// server pick the default track).
class _Language {
  const _Language(this.label, this.code);
  final String label;
  final String? code;
}

/// Offered audio-track languages. Only matters for videos with more than one
/// audio track (e.g. dubbed uploads); single-track videos ignore it.
const _languages = <_Language>[
  _Language('Original', null),
  _Language('English', 'en'),
  _Language('Spanish', 'es'),
  _Language('French', 'fr'),
  _Language('German', 'de'),
  _Language('Arabic', 'ar'),
  _Language('Hindi', 'hi'),
  _Language('Portuguese', 'pt'),
  _Language('Russian', 'ru'),
  _Language('Japanese', 'ja'),
  _Language('Korean', 'ko'),
  _Language('Chinese', 'zh'),
  _Language('Italian', 'it'),
  _Language('Turkish', 'tr'),
  _Language('Indonesian', 'id'),
];

/// "MP3 Converter" section: paste a YouTube or TikTok link and pull its audio
/// down as an MP3. The download + transcode happen on the shared backend (see
/// [LinkToMp3Service]); the finished file can be previewed, saved, or shared.
class LinkToMp3View extends ConsumerStatefulWidget {
  const LinkToMp3View({super.key});

  @override
  ConsumerState<LinkToMp3View> createState() => _LinkToMp3ViewState();
}

class _LinkToMp3ViewState extends ConsumerState<LinkToMp3View> {
  final _urlController = TextEditingController();

  // The preview player is created lazily on first play so simply rendering the
  // section never touches the audio plugin.
  AudioPlayer? _player;

  String? _validationError;
  String? _language; // null = Original / default track.
  bool _playing = false;
  String? _playingPath;

  // Progress feedback for the (unknown-duration, no server progress events)
  // conversion: an elapsed-time counter drives an indeterminate bar + staged
  // status text so the user can see it's actively working.
  Timer? _ticker;
  final _stopwatch = Stopwatch();
  int _elapsedSec = 0;

  static const _stageMessages = [
    'Fetching the video…',
    'Extracting the audio…',
    'Encoding to MP3…',
    'Almost there…',
  ];

  String get _stageText {
    final i = (_elapsedSec ~/ 8).clamp(0, _stageMessages.length - 1);
    return _stageMessages[i];
  }

  String get _elapsedLabel {
    final m = _elapsedSec ~/ 60;
    final s = _elapsedSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _startTicker() {
    _stopwatch
      ..reset()
      ..start();
    _elapsedSec = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec = _stopwatch.elapsed.inSeconds);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    _player = player;
    return player;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _urlController.dispose();
    _player?.dispose();
    super.dispose();
  }

  bool get _converting =>
      ref.read(linkToMp3ControllerProvider).isLoading;
  Mp3Result? get _result =>
      ref.read(linkToMp3ControllerProvider).asData?.value;

  String? get _displayError {
    if (_validationError != null) return _validationError;
    final state = ref.read(linkToMp3ControllerProvider);
    if (!state.hasError) return null;
    final error = state.error;
    return error is LinkToMp3Exception
        ? error.message
        : 'Something went wrong. Try again.';
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _urlController.text = text;
    setState(() => _validationError = null);
  }

  void _start() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _validationError = 'Paste a YouTube or TikTok link.');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.host.contains('.')) {
      setState(() => _validationError = 'That doesn’t look like a valid link.');
      return;
    }
    setState(() => _validationError = null);
    _stopPreview();
    _startTicker();
    ref
        .read(linkToMp3ControllerProvider.notifier)
        .convert(url, language: _language);
  }

  void _cancel() {
    ref.read(linkToMp3ControllerProvider.notifier).cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversion cancelled')),
    );
  }

  Future<void> _stopPreview() async {
    await _player?.stop();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _togglePreview(Mp3Result result) async {
    final player = _ensurePlayer();
    if (_playing && _playingPath == result.file.path) {
      await player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    if (_playingPath != result.file.path) {
      await player.stop();
      _playingPath = result.file.path;
    }
    await player.play(DeviceFileSource(result.file.path));
    if (mounted) setState(() => _playing = true);
  }

  Future<void> _save(Mp3Result result) async {
    final name = '${result.title}.mp3';
    final outcome = await MediaActions.saveAudioToFile(
      result.file.path,
      suggestedName: name,
    );
    if (!mounted || outcome == SaveOutcome.cancelled) return;
    final message = switch (outcome) {
      SaveOutcome.saved => 'Audio saved.',
      SaveOutcome.permissionDenied => 'Permission was denied.',
      SaveOutcome.missingFile => 'The audio file is missing.',
      SaveOutcome.failed => 'Could not save the audio.',
      SaveOutcome.cancelled => '',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share(Mp3Result result) async {
    final ok = await MediaActions.shareAudio(context, result.file.path);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The audio file is missing.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the UI in sync with the background job (which survives tab switches).
    ref.watch(linkToMp3ControllerProvider);
    // Stop the elapsed-time ticker the moment the job finishes (success, error,
    // or cancel) — even if it completed while the user was on another tab.
    ref.listen(linkToMp3ControllerProvider, (previous, next) {
      if (!next.isLoading) _stopTicker();
    });
    final result = _result;
    final error = _displayError;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Paste a YouTube or TikTok link and download its audio as an MP3.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),

        // Link input.
        Text('Link', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        StilloraGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.link_rounded,
                  color: StilloraColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  enabled: !_converting,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onChanged: (_) {
                    if (_validationError != null) {
                      setState(() => _validationError = null);
                    }
                  },
                  style: const TextStyle(color: StilloraColors.onSurface),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'https://youtube.com/watch?v=…',
                    hintStyle:
                        TextStyle(color: StilloraColors.onSurfaceVariant),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _converting ? null : _paste,
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('Paste'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Works with youtube.com, youtu.be and tiktok.com links.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),

        // Audio-track language (for dubbed / multi-language videos).
        Text('Video language',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        StilloraGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.translate_rounded,
                  color: StilloraColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _language,
                    isExpanded: true,
                    dropdownColor: StilloraColors.surfaceDim,
                    borderRadius: BorderRadius.circular(StilloraRadius.md),
                    style: const TextStyle(color: StilloraColors.onSurface),
                    onChanged: _converting
                        ? null
                        : (value) => setState(() => _language = value),
                    items: [
                      for (final lang in _languages)
                        DropdownMenuItem<String?>(
                          value: lang.code,
                          child: Text(lang.label),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Only affects videos that have more than one audio track.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),

        if (error != null) ...[
          _ErrorBanner(message: error),
          const SizedBox(height: 16),
        ],

        // Convert / progress.
        if (_converting)
          _ConvertingCard(
            elapsedLabel: _elapsedLabel,
            stageText: _stageText,
            onCancel: _cancel,
          )
        else
          StilloraPrimaryButton(
            onPressed: _start,
            icon: Icons.audiotrack_rounded,
            label: 'Convert to MP3',
          ),

        if (result != null) ...[
          const SizedBox(height: 20),
          _ResultCard(
            result: result,
            playing: _playing && _playingPath == result.file.path,
            onTogglePreview: () => _togglePreview(result),
            onSave: () => _save(result),
            onShare: () => _share(result),
          ),
        ],

        const SizedBox(height: 16),
        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
      ],
    );

    final body = useDesktopLayout(context)
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: content,
            ),
          )
        : content;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(top: false, child: body),
    );
  }
}

/// The finished MP3: title, a play/pause preview, and save + share actions.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.playing,
    required this.onTogglePreview,
    required this.onSave,
    required this.onShare,
  });

  final Mp3Result result;
  final bool playing;
  final VoidCallback onTogglePreview;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onTogglePreview,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                tooltip: playing ? 'Pause' : 'Play',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'MP3 · ready',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: StilloraColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isDesktopPlatform) ...[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onSave,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(isDesktopPlatform ? 'Share' : 'Save / Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// In-progress card: indeterminate bar, a staged status line, and a live
/// elapsed-time counter so the user can see the (30–60s) conversion is working.
class _ConvertingCard extends StatelessWidget {
  const _ConvertingCard({
    required this.elapsedLabel,
    required this.stageText,
    required this.onCancel,
  });

  final String elapsedLabel;
  final String stageText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Converting…',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                elapsedLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: StilloraColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            child: const LinearProgressIndicator(minHeight: 6),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  stageText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Keep this screen open — longer videos can take up to a minute.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.sm),
      decoration: BoxDecoration(
        color: StilloraColors.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(StilloraRadius.xl),
        border: Border.all(color: StilloraColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: StilloraColors.error),
          const SizedBox(width: StilloraSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: StilloraColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
