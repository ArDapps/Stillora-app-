import 'dart:io';

import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/widgets/render_panel.dart';
import '../../core/widgets/ad_widget.dart';
import '../../core/widgets/duration_slider.dart';
import '../../core/widgets/start_over_button.dart';
import '../../core/platform/platform_info.dart';
import '../editor/video_preset.dart';
import 'html_to_video_controller.dart';
import 'html_to_video_options.dart';
import 'html_to_video_service.dart';
import 'widgets/audio_step_card.dart';
import 'widgets/html_input_controls.dart';
import 'widgets/html_preview_pane.dart';
import 'widgets/output_size_card.dart';
import 'widgets/render_controls.dart';

/// "HTML → Video" tab: paste markup, pick an .html file, or enter a URL, then
/// render an animated HTML page into a share-ready MP4 via the backend.
class HtmlToVideoView extends ConsumerStatefulWidget {
  const HtmlToVideoView({super.key});

  @override
  ConsumerState<HtmlToVideoView> createState() => _HtmlToVideoViewState();
}

class _HtmlToVideoViewState extends ConsumerState<HtmlToVideoView> {
  final _htmlController = TextEditingController();
  final _urlController = TextEditingController();

  InputMode _mode = InputMode.paste;
  String? _pickedFileName;
  String? _pickedHtml;
  SizeOption _size = sizeOptions.first;
  ExportQuality _quality = defaultExportQuality;
  int _durationSeconds = 10;
  int _fps = 30;

  // Optional soundtrack / voice-over muxed onto the rendered video.
  String? _audioPath;
  String? _audioName;

  /// The picked aspect ratio scaled to the chosen quality tier.
  ({int width, int height}) get _outputSize =>
      scaleDimensionsToQuality(_size.width, _size.height, _quality);

  String? _validationError;
  VideoPlayerController? _player;
  String? _playerPath;

  // Conversion state lives in a provider so it keeps running across tab
  // switches and notifies the whole app on completion.
  bool get _converting => ref.read(htmlToVideoControllerProvider).isLoading;
  File? get _resultFile =>
      ref.read(htmlToVideoControllerProvider).asData?.value;
  String? get _displayError {
    if (_validationError != null) return _validationError;
    final state = ref.read(htmlToVideoControllerProvider);
    return state.hasError ? _convertErrorMessage(state.error) : null;
  }

  String _convertErrorMessage(Object? error) => error is HtmlToVideoException
      ? error.message
      : 'Something went wrong. Try again.';

  @override
  void dispose() {
    _htmlController.dispose();
    _urlController.dispose();
    _player?.dispose();
    super.dispose();
  }

  /// Whether there is anything worth clearing — drives the "Start over" button.
  bool get _hasInput =>
      _htmlController.text.trim().isNotEmpty ||
      _urlController.text.trim().isNotEmpty ||
      _pickedHtml != null ||
      _audioPath != null ||
      _resultFile != null;

  /// Puts the tab back to a blank slate: source, audio, output settings and the
  /// last render. The conversion provider is reset too so the preview clears.
  void _startOver() {
    _htmlController.clear();
    _urlController.clear();
    setState(() {
      _mode = InputMode.paste;
      _pickedFileName = null;
      _pickedHtml = null;
      _size = sizeOptions.first;
      _quality = defaultExportQuality;
      _durationSeconds = 10;
      _fps = 30;
      _audioPath = null;
      _audioName = null;
      _validationError = null;
    });
    ref.read(htmlToVideoControllerProvider.notifier).clear();
  }

  Future<void> _pickFile() async {
    final result = await pickImportFiles(
      type: FileType.custom,
      allowedExtensions: const ['html', 'htm'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    setState(() {
      _pickedFileName = result!.files.single.name;
      _pickedHtml = content;
      _validationError = null;
    });
  }

  void _removeAudio() => setState(() {
    _audioPath = null;
    _audioName = null;
  });

  String? _resolveHtml() {
    switch (_mode) {
      case InputMode.paste:
        final text = _htmlController.text.trim();
        return text.isEmpty ? null : text;
      case InputMode.file:
        return _pickedHtml;
      case InputMode.url:
        return null;
    }
  }

  void _startConvert() {
    final html = _resolveHtml();
    final url = _mode == InputMode.url ? _urlController.text.trim() : null;

    if (_mode == InputMode.url && (url == null || url.isEmpty)) {
      setState(() => _validationError = 'Enter a URL to render.');
      return;
    }
    if (_mode != InputMode.url && (html == null || html.isEmpty)) {
      setState(() {
        _validationError = _mode == InputMode.file
            ? 'Pick an .html file first.'
            : 'Paste some HTML first.';
      });
      return;
    }

    setState(() => _validationError = null);
    ref
        .read(htmlToVideoControllerProvider.notifier)
        .convert(
          HtmlToVideoRequest(
            html: html,
            url: url,
            width: _outputSize.width,
            height: _outputSize.height,
            durationMs: _durationSeconds * 1000,
            fps: _fps,
            audioPath: _audioPath,
          ),
        );
  }

  /// Keeps the preview player pointed at the latest rendered file.
  Future<void> _syncPlayer(File? file) async {
    if (file == null) {
      final old = _player;
      if (old != null) {
        setState(() {
          _player = null;
          _playerPath = null;
        });
        await old.dispose();
      }
      return;
    }
    if (file.path == _playerPath) return;
    final old = _player;
    final player = VideoPlayerController.file(file);
    await player.initialize();
    await player.setLooping(true);
    await player.play();
    if (!mounted) {
      await player.dispose();
      return;
    }
    setState(() {
      _player = player;
      _playerPath = file.path;
    });
    await old?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch keeps the UI in sync with the background job; listen drives the
    // preview player whenever a new render finishes (even from another tab).
    ref.watch(htmlToVideoControllerProvider);
    ref.listen(htmlToVideoControllerProvider, (previous, next) {
      _syncPlayer(next.asData?.value);
    });

    final desktop = useDesktopLayout(context);
    final startOver = Align(
      alignment: Alignment.centerRight,
      child: StartOverButton(
        onReset: _startOver,
        enabled: _hasInput && !_converting,
        confirmMessage:
            'This clears the HTML/URL, audio, output settings and the last '
            'render. This cannot be undone.',
      ),
    );

    if (desktop) {
      return Padding(
        padding: const EdgeInsets.all(StilloraSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  startOver,
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _leftColumn(desktop: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: StilloraSpacing.lg),
            Expanded(flex: 4, child: _rightColumn()),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(StilloraSpacing.sm),
        children: [
          startOver,
          ..._leftColumn(desktop: false),
          const SizedBox(height: StilloraSpacing.md),
          // Bounded height on mobile: PreviewPane uses an Expanded internally,
          // which needs a finite height inside the scrolling ListView.
          SizedBox(
            height: 380,
            child: PreviewPane(
              size: _size,
              fps: _fps,
              player: _player,
              hasResult: _resultFile != null,
              converting: _converting,
            ),
          ),
          const SizedBox(height: StilloraSpacing.sm),
          _convertButton(),
          if (_resultFile != null) ...[
            const SizedBox(height: StilloraSpacing.sm),
            _resultActions(),
          ],
          const SizedBox(height: 16),
          const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
        ],
      ),
    );
  }

  List<Widget> _leftColumn({required bool desktop}) {
    final durationCard = RenderStepCard(
      number: '3',
      title: 'Duration',
      child: DurationSlider(
        seconds: _durationSeconds,
        min: 1,
        maxSeconds: 60,
        label: 'Length',
        onChanged: (value) => setState(() => _durationSeconds = value),
      ),
    );

    final fpsCard = RenderStepCard(
      number: '4',
      title: 'Frame rate',
      child: RenderPillSegmented(
        options: [for (final f in fpsChoices) '$f'],
        selectedIndex: fpsChoices.indexOf(_fps),
        onSelected: (i) => setState(() => _fps = fpsChoices[i]),
      ),
    );

    final audioCard = AudioStepCard(
      audioName: _audioName,
      hasAudio: _audioPath != null,
      converting: _converting,
      onRemove: _removeAudio,
      onPicked: (path) => setState(() {
        _audioPath = path;
        _audioName = path.split(RegExp(r'[/\\]')).last;
      }),
    );

    return [
      const RenderEyebrow('NEW RENDER'),
      const SizedBox(height: StilloraSpacing.sm),
      Text(
        'HTML to share-ready video',
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
      const SizedBox(height: StilloraSpacing.xs),
      const Text(
        'Paste markup, drop an .html file, or enter a URL — pick a size and '
        'duration, export a clean MP4 in seconds.',
        style: TextStyle(color: StilloraColors.onSurfaceVariant, height: 1.4),
      ),
      const SizedBox(height: StilloraSpacing.md),
      RenderStepCard(
        number: '1',
        title: 'Source',
        trailing: const RenderTagPill('required'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModeSelector(
              mode: _mode,
              onChanged: (mode) => setState(() {
                _mode = mode;
                _validationError = null;
              }),
            ),
            const SizedBox(height: StilloraSpacing.sm),
            HtmlSourceInput(
              mode: _mode,
              htmlController: _htmlController,
              urlController: _urlController,
              pickedFileName: _pickedFileName,
              onPickFile: _pickFile,
            ),
          ],
        ),
      ),
      const SizedBox(height: StilloraSpacing.sm),
      OutputSizeCard(
        size: _size,
        quality: _quality,
        durationSeconds: _durationSeconds,
        fps: _fps,
        hasAudio: _audioPath != null,
        onSizeChanged: (option) => setState(() => _size = option),
        onQualityChanged: (value) => setState(() => _quality = value),
      ),
      const SizedBox(height: StilloraSpacing.sm),
      if (desktop)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: durationCard),
              const SizedBox(width: StilloraSpacing.sm),
              Expanded(child: fpsCard),
            ],
          ),
        )
      else ...[
        durationCard,
        const SizedBox(height: StilloraSpacing.sm),
        fpsCard,
      ],
      const SizedBox(height: StilloraSpacing.sm),
      audioCard,
      if (_displayError != null) ...[
        const SizedBox(height: StilloraSpacing.sm),
        RenderErrorBanner(message: _displayError!),
      ],
    ];
  }

  Widget _rightColumn() {
    return Column(
      children: [
        Expanded(
          child: PreviewPane(
            size: _size,
            fps: _fps,
            player: _player,
            hasResult: _resultFile != null,
            converting: _converting,
          ),
        ),
        const SizedBox(height: StilloraSpacing.sm),
        _convertButton(),
        if (_resultFile != null) ...[
          const SizedBox(height: StilloraSpacing.sm),
          _resultActions(),
        ],
        const SizedBox(height: 16),
        const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
      ],
    );
  }

  Widget _convertButton() => ConvertButton(
    converting: _converting,
    onConvert: _startConvert,
    onCancel: _cancel,
  );

  void _cancel() {
    ref.read(htmlToVideoControllerProvider.notifier).cancel();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Conversion cancelled')));
  }

  Widget _resultActions() {
    final file = _resultFile;
    if (file == null) return const SizedBox.shrink();
    return ResultActions(
      onSave: () => saveRenderedVideo(context, file),
      onShare: () => shareRenderedVideo(context, file),
    );
  }
}
