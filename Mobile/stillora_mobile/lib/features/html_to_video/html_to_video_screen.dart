import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/platform/media_actions.dart';
import '../../core/platform/platform_info.dart';
import 'html_to_video_controller.dart';
import 'html_to_video_service.dart';

// Accent + panel colours tuned to match the web "New render" design.
const _accent = Color(0xff8b5cf6);
const _panel = Color(0xff101019);
const _panelBorder = Color(0x14ffffff);

enum _InputMode { paste, file, url }

/// An output canvas size offered for the HTML → MP4 render.
class _SizeOption {
  const _SizeOption(this.label, this.chip, this.ratio, this.width, this.height);
  final String label;
  final String chip;
  final String ratio;
  final int width;
  final int height;
  double get aspect => width / height;
}

const _sizeOptions = [
  _SizeOption('Vertical', 'Vertical · 9:16', '9:16', 1080, 1920),
  _SizeOption('Square', 'Square · 1:1', '1:1', 1080, 1080),
  _SizeOption('Landscape', 'Landscape · 16:9', '16:9', 1920, 1080),
  _SizeOption('Portrait', 'Portrait · 4:5', '4:5', 1080, 1350),
];

const _fpsChoices = [24, 30, 60];

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

  _InputMode _mode = _InputMode.paste;
  String? _pickedFileName;
  String? _pickedHtml;
  _SizeOption _size = _sizeOptions.first;
  int _durationSeconds = 10;
  int _fps = 30;

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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
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

  String? _resolveHtml() {
    switch (_mode) {
      case _InputMode.paste:
        final text = _htmlController.text.trim();
        return text.isEmpty ? null : text;
      case _InputMode.file:
        return _pickedHtml;
      case _InputMode.url:
        return null;
    }
  }

  void _startConvert() {
    final html = _resolveHtml();
    final url = _mode == _InputMode.url ? _urlController.text.trim() : null;

    if (_mode == _InputMode.url && (url == null || url.isEmpty)) {
      setState(() => _validationError = 'Enter a URL to render.');
      return;
    }
    if (_mode != _InputMode.url && (html == null || html.isEmpty)) {
      setState(() {
        _validationError = _mode == _InputMode.file
            ? 'Pick an .html file first.'
            : 'Paste some HTML first.';
      });
      return;
    }

    setState(() => _validationError = null);
    ref.read(htmlToVideoControllerProvider.notifier).convert(
          HtmlToVideoRequest(
            html: html,
            url: url,
            width: _size.width,
            height: _size.height,
            durationMs: _durationSeconds * 1000,
            fps: _fps,
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

  Future<void> _save() async {
    final file = _resultFile;
    if (file == null) return;
    final name = 'stillora_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final outcome = isDesktopPlatform
        ? await MediaActions.saveVideoToFile(file.path, suggestedName: name)
        : await MediaActions.saveToCameraRoll(file.path);
    if (!mounted || outcome == SaveOutcome.cancelled) return;
    final message = switch (outcome) {
      SaveOutcome.saved =>
        isDesktopPlatform ? 'Video saved.' : 'Saved to your camera roll.',
      SaveOutcome.permissionDenied => 'Photos permission was denied.',
      SaveOutcome.missingFile => 'The video file is missing.',
      SaveOutcome.failed => 'Could not save the video.',
      SaveOutcome.cancelled => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share() async {
    final file = _resultFile;
    if (file == null) return;
    final ok = await MediaActions.shareVideo(context, file.path);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The video file is missing.')),
    );
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
    if (desktop) {
      return Padding(
        padding: const EdgeInsets.all(StilloraSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _leftColumn(desktop: true),
                ),
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
          ..._leftColumn(desktop: false),
          const SizedBox(height: StilloraSpacing.md),
          _PreviewPane(
            size: _size,
            fps: _fps,
            player: _player,
            hasResult: _resultFile != null,
            converting: _converting,
          ),
          const SizedBox(height: StilloraSpacing.sm),
          _convertButton(),
          if (_resultFile != null) ...[
            const SizedBox(height: StilloraSpacing.sm),
            _resultActions(),
          ],
        ],
      ),
    );
  }

  List<Widget> _leftColumn({required bool desktop}) {
    final durationCard = _StepCard(
      number: '3',
      title: 'Duration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_durationSeconds s',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              const Text(
                'up to 60s',
                style: TextStyle(color: StilloraColors.onSurfaceVariant),
              ),
            ],
          ),
          Slider(
            value: _durationSeconds.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '$_durationSeconds s',
            onChanged: (value) =>
                setState(() => _durationSeconds = value.round()),
          ),
        ],
      ),
    );

    final fpsCard = _StepCard(
      number: '4',
      title: 'Frame rate',
      child: _PillSegmented(
        options: [for (final f in _fpsChoices) '$f'],
        selectedIndex: _fpsChoices.indexOf(_fps),
        onSelected: (i) => setState(() => _fps = _fpsChoices[i]),
      ),
    );

    return [
      const _Eyebrow(),
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
      _StepCard(
        number: '1',
        title: 'Source',
        trailing: const _TagPill('required'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModeSelector(
              mode: _mode,
              onChanged: (mode) => setState(() {
                _mode = mode;
                _validationError = null;
              }),
            ),
            const SizedBox(height: StilloraSpacing.sm),
            _buildInput(),
          ],
        ),
      ),
      const SizedBox(height: StilloraSpacing.sm),
      _StepCard(
        number: '2',
        title: 'Output size',
        trailing: _TagPill('${_size.width}×${_size.height}'),
        footer: 'Reels · TikTok · Stories · YouTube',
        child: _FormatGrid(
          options: _sizeOptions,
          selected: _size,
          onSelected: (option) => setState(() => _size = option),
        ),
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
      if (_displayError != null) ...[
        const SizedBox(height: StilloraSpacing.sm),
        _ErrorBanner(message: _displayError!),
      ],
    ];
  }

  Widget _rightColumn() {
    return Column(
      children: [
        Expanded(
          child: _PreviewPane(
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
      ],
    );
  }

  Widget _convertButton() {
    if (_converting) {
      return SizedBox(
        height: 56,
        child: Row(
          children: [
            const Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Rendering…'),
                ],
              ),
            ),
            const SizedBox(width: StilloraSpacing.xs),
            OutlinedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: _startConvert,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Convert to MP4'),
      ),
    );
  }

  void _cancel() {
    ref.read(htmlToVideoControllerProvider.notifier).cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversion cancelled')),
    );
  }

  Widget _resultActions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _save,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Save'),
          ),
        ),
        const SizedBox(width: StilloraSpacing.xs),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  static InputDecoration _fieldDecoration(String hint, {Widget? prefixIcon}) {
    const radius = BorderRadius.all(Radius.circular(StilloraRadius.xl));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: StilloraColors.onSurfaceVariant),
      prefixIcon: prefixIcon,
      alignLabelWithHint: true,
      filled: true,
      fillColor: StilloraColors.surfaceDim,
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _panelBorder),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _accent, width: 1.5),
      ),
      border: const OutlineInputBorder(borderRadius: radius),
    );
  }

  Widget _buildInput() {
    switch (_mode) {
      case _InputMode.paste:
        return TextField(
          controller: _htmlController,
          minLines: 5,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: StilloraColors.onSurface,
          ),
          decoration: _fieldDecoration('<html>…</html>'),
        );
      case _InputMode.file:
        return _DropZone(fileName: _pickedFileName, onTap: _pickFile);
      case _InputMode.url:
        return TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: const TextStyle(color: StilloraColors.onSurface),
          decoration: _fieldDecoration(
            'https://example.com/animation.html',
            prefixIcon: const Icon(Icons.link),
          ),
        );
    }
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.auto_awesome, size: 14, color: _accent),
        SizedBox(width: 6),
        Text(
          'NEW RENDER',
          style: TextStyle(
            color: _accent,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// A numbered panel matching the web design: number badge + title + optional
/// trailing pill, with an optional muted footer line.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.child,
    this.trailing,
    this.footer,
  });

  final String number;
  final String title;
  final Widget child;
  final Widget? trailing;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberBadge(number),
              const SizedBox(width: StilloraSpacing.xs),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: StilloraColors.onSurface,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: StilloraSpacing.sm),
          child,
          if (footer != null) ...[
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              footer!,
              style: const TextStyle(
                color: StilloraColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.number);
  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: Color(0xffd8c9ff),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StilloraColors.surfaceDim,
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(color: _panelBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: StilloraColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// Two-column grid of selectable output-size tiles.
class _FormatGrid extends StatelessWidget {
  const _FormatGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_SizeOption> options;
  final _SizeOption selected;
  final ValueChanged<_SizeOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + 2 < options.length ? StilloraSpacing.xs : 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FormatTile(
                    option: options[i],
                    selected: options[i] == selected,
                    onTap: () => onSelected(options[i]),
                  ),
                ),
                const SizedBox(width: StilloraSpacing.xs),
                Expanded(
                  child: i + 1 < options.length
                      ? _FormatTile(
                          option: options[i + 1],
                          selected: options[i + 1] == selected,
                          onTap: () => onSelected(options[i + 1]),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SizeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _accent.withValues(alpha: 0.12) : StilloraColors.surfaceDim,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _accent : _panelBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? _accent : StilloraColors.outline,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: StilloraColors.onSurface,
                      ),
                    ),
                    Text(
                      option.ratio,
                      style: const TextStyle(
                        color: StilloraColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded segmented control with a solid accent active segment.
class _PillSegmented extends StatelessWidget {
  const _PillSegmented({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StilloraColors.surfaceDim,
        borderRadius: BorderRadius.circular(StilloraRadius.full),
        border: Border.all(color: _panelBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? _accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(StilloraRadius.full),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex
                          ? Colors.white
                          : StilloraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StilloraColors.surfaceDim,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _panelBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.description_outlined, size: 30, color: _accent),
              const SizedBox(height: StilloraSpacing.xs),
              Text(
                fileName ?? 'Drop an .html file',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: StilloraColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'or click to browse · .html .htm',
                style: TextStyle(
                  color: StilloraColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The right-hand preview panel: format chip, framed canvas, and spec footer.
class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.size,
    required this.fps,
    required this.player,
    required this.hasResult,
    required this.converting,
  });

  final _SizeOption size;
  final int fps;
  final VideoPlayerController? player;
  final bool hasResult;
  final bool converting;

  @override
  Widget build(BuildContext context) {
    final showVideo = hasResult && player != null;
    return Container(
      padding: const EdgeInsets.all(StilloraSpacing.md),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  size.chip,
                  style: const TextStyle(
                    color: Color(0xffd8c9ff),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${size.width} × ${size.height}',
                style: const TextStyle(
                  color: StilloraColors.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: StilloraSpacing.md),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: size.aspect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(StilloraRadius.full),
                  child: showVideo
                      ? VideoPlayer(player!)
                      : _PreviewPlaceholder(converting: converting),
                ),
              ),
            ),
          ),
          const SizedBox(height: StilloraSpacing.md),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: StilloraColors.surfaceDim,
              borderRadius: BorderRadius.circular(StilloraRadius.xl),
              border: Border.all(color: _panelBorder),
            ),
            child: Row(
              children: [
                const Text(
                  'stillora.mp4',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: StilloraColors.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${size.height >= 1080 ? '1080p' : '720p'} · H.264 · $fps fps',
                  style: const TextStyle(
                    color: StilloraColors.onSurfaceVariant,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.converting});
  final bool converting;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HatchPainter(),
      child: ColoredBox(
        color: const Color(0xff15151f),
        child: Center(
          child: converting
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: StilloraSpacing.sm),
                    Text(
                      'Rendering…',
                      style: TextStyle(color: StilloraColors.onSurfaceVariant),
                    ),
                  ],
                )
              : const Text(
                  'your video renders here',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 8;
    const gap = 26.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final _InputMode mode;
  final ValueChanged<_InputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PillSegmented(
      options: const ['Paste', 'File', 'URL'],
      selectedIndex: _InputMode.values.indexOf(mode),
      onSelected: (i) => onChanged(_InputMode.values[i]),
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
