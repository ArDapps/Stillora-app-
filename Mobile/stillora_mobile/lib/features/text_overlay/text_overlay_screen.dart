import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_spacing.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/ad_widget.dart';
import '../editor/video_preset.dart';
import '../export/export_cancellation.dart';
import 'text_layer_renderer.dart';
import 'text_overlay_state.dart';

/// "Text" section: load a video, then stack one or more animated text overlays
/// on top. Each layer is dragged into place on a live preview, timed with a
/// start/end window, and dissolved in/out with a fade. Text is rendered to a
/// transparent PNG at the export resolution and burned in, keeping the base
/// video's own audio.
class TextOverlayView extends ConsumerWidget {
  const TextOverlayView({super.key});

  Future<void> _runExport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!textOverlayExportSupported) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Text export runs on iPhone, macOS and Windows/Linux today. '
            'Android export is coming next.',
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExportingDialog(
        onCancel: () =>
            ref.read(textOverlayControllerProvider.notifier).cancel(),
      ),
    );
    try {
      final result =
          await ref.read(textOverlayControllerProvider.notifier).export();
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Add a video and at least one text layer first.'
                : 'Saved to Library · ${result.width}×${result.height}',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isExportCancellation(e) ? 'Export cancelled' : 'Export failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(textOverlayControllerProvider);
    final controller = ref.read(textOverlayControllerProvider.notifier);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: stilloraBackgroundGradient),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Add animated text on top of your clip. Type it, drag it anywhere, '
              'set when it appears and how it fades. Your video keeps its sound.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (!st.hasBase)
              _PickBaseCard(onPick: controller.pickBaseVideo)
            else ...[
              Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 420, maxWidth: 460),
                  child: AspectRatio(
                    aspectRatio: st.aspectRatio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: StilloraColors.surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.circular(StilloraRadius.full),
                        border: Border.all(
                          color: StilloraColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(StilloraRadius.full),
                        child: _TextOverlayPreview(
                          st: st,
                          onTransform: controller.setTransform,
                          onSelect: controller.select,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BaseInfoRow(st: st, onReplace: controller.pickBaseVideo),
              const SizedBox(height: 16),
              _AddTextRow(controller: controller),
              const SizedBox(height: 12),
              if (st.hasLayers) ...[
                _TimelineStrip(st: st, onSelect: controller.select),
                const SizedBox(height: 16),
                _LayerList(st: st, controller: controller),
                const SizedBox(height: 16),
                if (st.selectedLayer != null)
                  _PropertyEditor(
                    index: st.selected,
                    layer: st.selectedLayer!,
                    baseDuration: st.baseDurationSeconds,
                    controller: controller,
                  ),
              ] else
                _LayersHint(),
              const SizedBox(height: 16),
              _ResolutionSelector(
                selected: st.quality,
                onSelected: controller.setQuality,
              ),
              const SizedBox(height: 16),
              _ExportSection(st: st, onExport: () => _runExport(context, ref)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const AdSlotWidget(placement: 'USER_DASHBOARD_LEFT'),
          ],
        ),
      ),
    );
  }
}

/// Plays the base video (muted, looping) and draws every text layer on top,
/// applying each layer's fade at the current playback position so the preview
/// matches the export. The selected layer stays faintly visible even outside
/// its window so it can still be grabbed. Drag a layer to move it; centre-snap
/// guides appear when it lines up with the middle of the frame.
class _TextOverlayPreview extends StatefulWidget {
  const _TextOverlayPreview({
    required this.st,
    required this.onTransform,
    required this.onSelect,
  });

  final TextOverlayState st;
  final void Function(int index, double x, double y) onTransform;
  final ValueChanged<int> onSelect;

  @override
  State<_TextOverlayPreview> createState() => _TextOverlayPreviewState();
}

class _TextOverlayPreviewState extends State<_TextOverlayPreview> {
  VideoPlayerController? _base;
  String? _basePath;
  double _positionSeconds = 0;
  bool _snapV = false;
  bool _snapH = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _TextOverlayPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _onTick() {
    final c = _base;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position.inMilliseconds / 1000.0;
    if ((pos - _positionSeconds).abs() >= 0.04) {
      setState(() => _positionSeconds = pos);
    }
  }

  void _sync() {
    if (widget.st.baseVideoPath != _basePath) {
      _base?.removeListener(_onTick);
      _base?.dispose();
      _basePath = widget.st.baseVideoPath;
      _base = null;
      _positionSeconds = 0;
      final path = _basePath;
      if (path != null) {
        final c = VideoPlayerController.file(File(path));
        _base = c;
        c.initialize().then((_) {
          c.setLooping(true);
          c.setVolume(0);
          c.addListener(_onTick);
          c.play();
          if (mounted) setState(() {});
        }).catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    _base?.removeListener(_onTick);
    _base?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final layers = st.layers;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            if (_base?.value.isInitialized ?? false)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _base!.value.size.width,
                    height: _base!.value.size.height,
                    child: VideoPlayer(_base!),
                  ),
                ),
              ),
            // Centre-snap alignment guides.
            if (_snapV)
              Positioned(
                left: w / 2 - 0.5,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: StilloraColors.secondary),
              ),
            if (_snapH)
              Positioned(
                top: h / 2 - 0.5,
                left: 0,
                right: 0,
                child: Container(height: 1, color: StilloraColors.secondary),
              ),
            for (var i = 0; i < layers.length; i++)
              _DraggableText(
                key: ValueKey(layers[i].id),
                layer: layers[i],
                selected: i == st.selected,
                positionSeconds: _positionSeconds,
                frameWidth: w,
                frameHeight: h,
                onTap: () => widget.onSelect(i),
                onMove: (dx, dy) {
                  final rawX = layers[i].x + dx / w;
                  final rawY = layers[i].y + dy / h;
                  final snapV = (rawX - 0.5).abs() < 0.02;
                  final snapH = (rawY - 0.5).abs() < 0.02;
                  if (snapV != _snapV || snapH != _snapH) {
                    setState(() {
                      _snapV = snapV;
                      _snapH = snapH;
                    });
                  }
                  widget.onTransform(
                    i,
                    snapV ? 0.5 : rawX,
                    snapH ? 0.5 : rawY,
                  );
                },
                onMoveEnd: () {
                  if (_snapV || _snapH) {
                    setState(() {
                      _snapV = false;
                      _snapH = false;
                    });
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

/// A single text layer positioned by its normalised centre and draggable. Its
/// opacity tracks the fade at [positionSeconds]; the selected layer keeps a
/// faint minimum so it stays grabbable when it's outside its time window.
class _DraggableText extends StatelessWidget {
  const _DraggableText({
    super.key,
    required this.layer,
    required this.selected,
    required this.positionSeconds,
    required this.frameWidth,
    required this.frameHeight,
    required this.onTap,
    required this.onMove,
    required this.onMoveEnd,
  });

  final TextLayer layer;
  final bool selected;
  final double positionSeconds;
  final double frameWidth;
  final double frameHeight;
  final VoidCallback onTap;
  final void Function(double dx, double dy) onMove;
  final VoidCallback onMoveEnd;

  @override
  Widget build(BuildContext context) {
    final fontSize = layer.fontScale * frameHeight;
    final fadeOpacity = layer.opacityAt(positionSeconds);
    final opacity =
        fadeOpacity > 0 ? fadeOpacity : (selected ? 0.35 : 0.0);

    final bg = layer.backgroundColor;
    Widget textWidget = Text(
      layer.text.isEmpty ? ' ' : layer.text,
      textAlign: layer.align,
      style: textLayerStyle(layer, fontSize: fontSize),
    );
    if (layer.strokeWidth > 0) {
      // Cheap outline for the preview: a stroked copy stacked under the fill.
      textWidget = Stack(
        children: [
          Text(
            layer.text.isEmpty ? ' ' : layer.text,
            textAlign: layer.align,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: layer.fontWeight,
              fontFamily: layer.fontFamily,
              height: 1.15,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = layer.strokeWidth * fontSize * 0.5
                ..strokeJoin = StrokeJoin.round
                ..color = layer.strokeColor,
            ),
          ),
          textWidget,
        ],
      );
    }
    if (bg != null) {
      textWidget = Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.28,
          vertical: fontSize * 0.16,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(fontSize * 0.18),
        ),
        child: textWidget,
      );
    }

    return Positioned(
      left: layer.x * frameWidth,
      top: layer.y * frameHeight,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        // A fully-invisible layer (not selected, outside its window) must not
        // intercept drags meant for the layers beneath it.
        child: IgnorePointer(
          ignoring: opacity <= 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onPanStart: (_) => onTap(),
            onPanUpdate: (d) => onMove(d.delta.dx, d.delta.dy),
            onPanEnd: (_) => onMoveEnd(),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                decoration: selected
                    ? BoxDecoration(
                        border: Border.all(
                          color: StilloraColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                padding: const EdgeInsets.all(4),
                child: textWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BaseInfoRow extends StatelessWidget {
  const _BaseInfoRow({required this.st, required this.onReplace});

  final TextOverlayState st;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final res = st.outputResolution;
    final measured = st.baseWidth > 0;
    return StilloraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.movie_creation_rounded,
              size: 20, color: StilloraColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              measured
                  ? 'Base video · ${res.width}×${res.height} · '
                      '${_fmt(st.baseDurationSeconds)}'
                  : 'Reading video…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onReplace, child: const Text('Replace')),
        ],
      ),
    );
  }
}

/// "Add Text" plus one-tap style presets (Title / Subtitle / Caption / CTA).
class _AddTextRow extends StatelessWidget {
  const _AddTextRow({required this.controller});

  final TextOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => controller.addText(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add text'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in TextPreset.values)
              ActionChip(
                avatar: const Icon(Icons.title_rounded, size: 16),
                label: Text(preset.label),
                onPressed: () => controller.addText(preset),
              ),
          ],
        ),
      ],
    );
  }
}

/// A compact timeline: one bar per layer spanning the clip, with its visible
/// window highlighted so you can see when each text appears.
class _TimelineStrip extends StatelessWidget {
  const _TimelineStrip({required this.st, required this.onSelect});

  final TextOverlayState st;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = st.baseDurationSeconds <= 0
        ? 1.0
        : st.baseDurationSeconds.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timeline', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < st.layers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: Text(
                      st.layers[i].text.isEmpty ? 'Text' : st.layers[i].text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: i == st.selected
                                ? StilloraColors.primary
                                : StilloraColors.onSurfaceVariant,
                            fontWeight: i == st.selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        final start =
                            (st.layers[i].start / total).clamp(0.0, 1.0);
                        final end = (st.layers[i].end <= 0
                                ? 1.0
                                : st.layers[i].end / total)
                            .clamp(0.0, 1.0);
                        return SizedBox(
                          height: 14,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: StilloraColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              Positioned(
                                left: start * w,
                                width: ((end - start) * w).clamp(2.0, w),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      StilloraColors.brandMagenta,
                                      StilloraColors.brandViolet,
                                    ]),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LayerList extends StatelessWidget {
  const _LayerList({required this.st, required this.controller});

  final TextOverlayState st;
  final TextOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layers', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < st.layers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: StilloraSpacing.xs),
            child: StilloraGlassCard(
              onTap: () => controller.select(i),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    size: 20,
                    color: i == st.selected
                        ? StilloraColors.primary
                        : StilloraColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      st.layers[i].text.isEmpty ? 'Empty text' : st.layers[i].text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        i == 0 ? null : () => controller.reorder(i, i - 1),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    tooltip: 'Move up',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                  IconButton(
                    onPressed: i == st.layers.length - 1
                        ? null
                        : () => controller.reorder(i, i + 2),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    tooltip: 'Move down',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                  IconButton(
                    onPressed: () => controller.duplicateLayer(i),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Duplicate',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                  IconButton(
                    onPressed: () => controller.removeLayer(i),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Full property editor for the selected layer: content, font, size, colours,
/// stroke, shadow, alignment, opacity, timing and fade.
class _PropertyEditor extends StatelessWidget {
  const _PropertyEditor({
    required this.index,
    required this.layer,
    required this.baseDuration,
    required this.controller,
  });

  final int index;
  final TextLayer layer;
  final int baseDuration;
  final TextOverlayController controller;

  void _u(TextLayer Function(TextLayer) f) => controller.updateLayer(index, f);

  @override
  Widget build(BuildContext context) {
    final maxEnd = baseDuration <= 0 ? 1.0 : baseDuration.toDouble();
    final start = layer.start.clamp(0.0, maxEnd);
    final end = (layer.end <= 0 ? maxEnd : layer.end).clamp(start, maxEnd);
    final span = end - start;
    return StilloraGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit text', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('text_${layer.id}'),
            initialValue: layer.text,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => _u((l) => l.copyWith(text: v)),
          ),
          const SizedBox(height: 14),

          // Font family.
          _FieldLabel('Font'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final font in kTextFontFamilies)
                ChoiceChip(
                  label: Text(font.$1),
                  selected: layer.fontFamily == font.$2,
                  onSelected: (_) =>
                      _u((l) => l.copyWith(fontFamily: font.$2)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Weight.
          _FieldLabel('Weight'),
          Wrap(
            spacing: 8,
            children: [
              for (final w in const [
                FontWeight.w400,
                FontWeight.w600,
                FontWeight.w700,
                FontWeight.w900,
              ])
                ChoiceChip(
                  label: Text(_weightLabel(w)),
                  selected: layer.fontWeight == w,
                  onSelected: (_) => _u((l) => l.copyWith(fontWeight: w)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Alignment.
          _FieldLabel('Alignment'),
          Wrap(
            spacing: 8,
            children: [
              _alignChip(Icons.format_align_left_rounded, TextAlign.left),
              _alignChip(Icons.format_align_center_rounded, TextAlign.center),
              _alignChip(Icons.format_align_right_rounded, TextAlign.right),
            ],
          ),
          const SizedBox(height: 12),

          _SliderRow(
            label: 'Size',
            value: layer.fontScale,
            min: minFontScale,
            max: maxFontScale,
            display: '${(layer.fontScale * 100).round()}%',
            onChanged: (v) => _u((l) => l.copyWith(fontScale: v)),
          ),
          _SliderRow(
            label: 'Opacity',
            value: layer.opacity,
            min: 0,
            max: 1,
            display: '${(layer.opacity * 100).round()}%',
            onChanged: (v) => _u((l) => l.copyWith(opacity: v)),
          ),

          const SizedBox(height: 8),
          _FieldLabel('Text colour'),
          _SwatchRow(
            selected: layer.color,
            includeNone: false,
            onPick: (c) => _u((l) => l.copyWith(color: c!)),
          ),
          const SizedBox(height: 12),
          _FieldLabel('Background'),
          _SwatchRow(
            selected: layer.backgroundColor,
            includeNone: true,
            onPick: (c) => _u((l) => l.copyWith(backgroundColor: c)),
          ),
          const SizedBox(height: 12),

          // Stroke.
          _SliderRow(
            label: 'Outline',
            value: layer.strokeWidth,
            min: 0,
            max: 0.3,
            display: layer.strokeWidth == 0
                ? 'Off'
                : '${(layer.strokeWidth * 100).round()}%',
            onChanged: (v) => _u((l) => l.copyWith(strokeWidth: v)),
          ),
          if (layer.strokeWidth > 0) ...[
            _FieldLabel('Outline colour'),
            _SwatchRow(
              selected: layer.strokeColor,
              includeNone: false,
              onPick: (c) => _u((l) => l.copyWith(strokeColor: c!)),
            ),
            const SizedBox(height: 8),
          ],

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Drop shadow'),
            value: layer.shadow,
            onChanged: (v) => _u((l) => l.copyWith(shadow: v)),
          ),

          const Divider(height: 24),

          // Timing.
          _FieldLabel('Shows ${_fmt(start.round())} – ${_fmt(end.round())}'),
          RangeSlider(
            min: 0,
            max: maxEnd,
            divisions: baseDuration > 0 ? baseDuration : null,
            values: RangeValues(start, end),
            labels: RangeLabels(_fmt(start.round()), _fmt(end.round())),
            onChanged: (v) => controller.setWindow(index, v.start, v.end),
          ),
          _SliderRow(
            label: 'Fade in',
            value: layer.fadeIn.clamp(0.0, span <= 0 ? 1.0 : span),
            min: 0,
            max: span <= 0 ? 1.0 : span,
            display: '${layer.fadeIn.toStringAsFixed(1)}s',
            onChanged: (v) => _u((l) => l.copyWith(fadeIn: v)),
          ),
          _SliderRow(
            label: 'Fade out',
            value: layer.fadeOut.clamp(0.0, span <= 0 ? 1.0 : span),
            min: 0,
            max: span <= 0 ? 1.0 : span,
            display: '${layer.fadeOut.toStringAsFixed(1)}s',
            onChanged: (v) => _u((l) => l.copyWith(fadeOut: v)),
          ),
        ],
      ),
    );
  }

  Widget _alignChip(IconData icon, TextAlign a) => ChoiceChip(
        label: Icon(icon, size: 18),
        selected: layer.align == a,
        onSelected: (_) => _u((l) => l.copyWith(align: a)),
      );
}

String _weightLabel(FontWeight w) => switch (w) {
      FontWeight.w400 => 'Regular',
      FontWeight.w600 => 'Medium',
      FontWeight.w700 => 'Bold',
      FontWeight.w900 => 'Black',
      _ => 'Bold',
    };

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
        ),
      );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  )),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(display,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Preset colour swatches (plus an optional "none" for background/stroke).
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.selected,
    required this.includeNone,
    required this.onPick,
  });

  final Color? selected;
  final bool includeNone;
  final ValueChanged<Color?> onPick;

  static const _palette = <Color>[
    Colors.white,
    Colors.black,
    Color(0xffd946ef),
    Color(0xff8b5cf6),
    Color(0xff22d3ee),
    Color(0xffef4444),
    Color(0xfff59e0b),
    Color(0xff22c55e),
    Color(0xff3b82f6),
    Color(0xfff9a8d4),
  ];

  @override
  Widget build(BuildContext context) {
    final isPreset = selected != null &&
        _palette.any((c) => c.toARGB32() == selected!.toARGB32());
    // When the chosen colour isn't one of the presets, it came from the custom
    // picker — show it as an extra selected swatch so it isn't lost.
    final customChosen = selected != null && !isPreset;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (includeNone)
          _swatch(
            color: null,
            selected: selected == null,
            onTap: () => onPick(null),
          ),
        for (final c in _palette)
          _swatch(
            color: c,
            selected: selected != null &&
                selected!.toARGB32() == c.toARGB32(),
            onTap: () => onPick(c),
          ),
        if (customChosen)
          _swatch(color: selected, selected: true, onTap: () {}),
        // "＋" opens a full picker with RGB sliders and a hex field.
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<Color>(
              context: context,
              builder: (_) => _ColorPickerDialog(initial: selected ?? Colors.white),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const SweepGradient(colors: [
                Color(0xffef4444),
                Color(0xfff59e0b),
                Color(0xff22c55e),
                Color(0xff22d3ee),
                Color(0xff3b82f6),
                Color(0xffd946ef),
                Color(0xffef4444),
              ]),
              shape: BoxShape.circle,
              border: Border.all(color: StilloraColors.glassStroke, width: 1.5),
            ),
            child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _swatch({
    required Color? color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? StilloraColors.primary : StilloraColors.glassStroke,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: color == null
            ? const Icon(Icons.block_rounded, size: 16, color: Colors.white54)
            : null,
      ),
    );
  }
}

class _LayersHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'No text yet. Tap “Add text” (or a preset) to drop a layer on the clip.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StilloraColors.onSurfaceVariant,
          ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({required this.st, required this.onExport});

  final TextOverlayState st;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final res = st.outputResolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(
          'Output ${res.width} × ${res.height} · ${_fmt(st.baseDurationSeconds)} '
          '· keeps original audio',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StilloraColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        StilloraPrimaryButton(
          onPressed: st.canExport ? onExport : null,
          icon: Icons.movie_filter_rounded,
          label: 'Export MP4',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: StilloraColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Text is burned in with its timing & fade on iPhone, macOS and '
                'Windows/Linux. Android export is coming next.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StilloraColors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickBaseCard extends StatelessWidget {
  const _PickBaseCard({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return StilloraGlassCard(
      onTap: onPick,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          const Icon(Icons.video_call_rounded,
              color: StilloraColors.primary, size: 34),
          const SizedBox(height: 10),
          Text(
            'Choose a video to caption',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Then add animated text and drag it into place.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StilloraColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ResolutionSelector extends StatelessWidget {
  const _ResolutionSelector({required this.selected, required this.onSelected});

  final ExportQuality? selected;
  final ValueChanged<ExportQuality?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resolution', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Original'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final q in ExportQuality.values)
              ChoiceChip(
                label: Text(q.label),
                selected: selected == q,
                onSelected: (_) => onSelected(q),
              ),
          ],
        ),
      ],
    );
  }
}

class _ExportingDialog extends StatefulWidget {
  const _ExportingDialog({required this.onCancel});

  final Future<void> Function() onCancel;

  @override
  State<_ExportingDialog> createState() => _ExportingDialogState();
}

class _ExportingDialogState extends State<_ExportingDialog> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: StilloraColors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(StilloraSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: StilloraSpacing.sm),
            Text(
              _cancelling ? 'Cancelling…' : 'Exporting…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: StilloraSpacing.sm),
            OutlinedButton.icon(
              onPressed: _cancelling
                  ? null
                  : () async {
                      setState(() => _cancelling = true);
                      await widget.onCancel();
                    },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel export'),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}

/// A dependency-free colour picker: RGB sliders plus a hex field, with a live
/// preview. Returns the chosen [Color] (opaque) via `Navigator.pop`.
class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});

  final Color initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late int _r = (widget.initial.r * 255).round();
  late int _g = (widget.initial.g * 255).round();
  late int _b = (widget.initial.b * 255).round();
  late final TextEditingController _hex =
      TextEditingController(text: _toHex(_r, _g, _b));

  Color get _color => Color.fromARGB(255, _r, _g, _b);

  static String _toHex(int r, int g, int b) =>
      '#${r.toRadixString(16).padLeft(2, '0')}'
              '${g.toRadixString(16).padLeft(2, '0')}'
              '${b.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  void _syncHexFromRgb() {
    _hex.value = TextEditingValue(text: _toHex(_r, _g, _b));
  }

  void _applyHex(String raw) {
    var s = raw.trim().replaceAll('#', '');
    if (s.length == 3) {
      s = s.split('').map((c) => '$c$c').join();
    }
    if (s.length != 6) return;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return;
    setState(() {
      _r = (v >> 16) & 0xff;
      _g = (v >> 8) & 0xff;
      _b = v & 0xff;
    });
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: StilloraColors.surfaceContainer,
      title: const Text('Pick a colour'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: StilloraColors.glassStroke),
              ),
            ),
            const SizedBox(height: 14),
            _channel('R', _r, Colors.red, (v) {
              setState(() => _r = v);
              _syncHexFromRgb();
            }),
            _channel('G', _g, Colors.green, (v) {
              setState(() => _g = v);
              _syncHexFromRgb();
            }),
            _channel('B', _b, Colors.blue, (v) {
              setState(() => _b = v);
              _syncHexFromRgb();
            }),
            const SizedBox(height: 8),
            TextField(
              controller: _hex,
              decoration: const InputDecoration(
                labelText: 'Hex',
                prefixText: '',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: _applyHex,
              onChanged: (v) {
                final s = v.trim().replaceAll('#', '');
                if (s.length == 6 || s.length == 3) _applyHex(v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Use colour'),
        ),
      ],
    );
  }

  Widget _channel(
    String label,
    int value,
    Color tint,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: tint,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text('$value', textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
