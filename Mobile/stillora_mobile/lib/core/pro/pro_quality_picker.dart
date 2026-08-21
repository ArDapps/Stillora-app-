import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/video_preset.dart';
import '../design/render_components.dart';
import 'pro_controller.dart';
import 'pro_gate.dart';

/// Visual variants so each section keeps the control it already used.
enum ProQualityPickerStyle {
  /// Stillora's chunky pill chips (Create, Loop, HTML → Video).
  pill,

  /// Material segmented button (Speed, Remove Silence, Reel).
  segmented,
}

/// The export-quality picker for every section that renders video.
///
/// Free users can pick 720p; 1080p / 2K / 4K stay **visible** with a PRO badge
/// and open the upgrade page when tapped, so the value of Pro is obvious
/// without hiding anything. If a Free user arrives holding a Pro tier — the
/// app's historical default was 1080p, and an expired-restore could leave one
/// behind — the selection is corrected down to the Free ceiling once, so what
/// the picker shows is always what will actually be exported.
class ProQualityPicker extends ConsumerStatefulWidget {
  const ProQualityPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.style = ProQualityPickerStyle.pill,
    this.enabled = true,
  });

  final ExportQuality selected;
  final ValueChanged<ExportQuality> onSelected;
  final ProQualityPickerStyle style;
  final bool enabled;

  @override
  ConsumerState<ProQualityPicker> createState() => _ProQualityPickerState();
}

class _ProQualityPickerState extends ConsumerState<ProQualityPicker> {
  /// Guards the auto-correction so it runs at most once per entitlement change
  /// instead of every rebuild.
  bool _clampScheduled = false;

  void _maybeClamp(bool isPro) {
    if (isPro || !widget.selected.requiresPro || _clampScheduled) return;
    _clampScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onSelected(ProLimits.freeExportQuality);
    });
  }

  void _select(ExportQuality quality, bool isPro) {
    if (quality.requiresPro && !isPro) {
      openProUpgrade(context, reason: ProFeature.higherResolution);
      return;
    }
    widget.onSelected(quality);
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    if (isPro) _clampScheduled = false;
    _maybeClamp(isPro);

    final locked = [
      for (final q in ExportQuality.values) q.requiresPro && !isPro,
    ];

    return switch (widget.style) {
      ProQualityPickerStyle.pill => RenderPillSegmented(
        options: [for (final q in ExportQuality.values) q.label],
        badges: [
          for (final isLocked in locked)
            if (isLocked) const ProBadge(compact: true) else null,
        ],
        selectedIndex: ExportQuality.values.indexOf(widget.selected),
        onSelected: widget.enabled
            ? (i) => _select(ExportQuality.values[i], isPro)
            : (_) {},
      ),
      ProQualityPickerStyle.segmented => SizedBox(
        width: double.infinity,
        child: SegmentedButton<ExportQuality>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < ExportQuality.values.length; i++)
              ButtonSegment(
                value: ExportQuality.values[i],
                label: ProLabel(
                  ExportQuality.values[i].label,
                  locked: locked[i],
                  compact: true,
                ),
              ),
          ],
          selected: {widget.selected},
          // Never disable the Pro tiers: a Free user must be able to tap them
          // and find out what the upgrade unlocks.
          onSelectionChanged: widget.enabled
              ? (v) => _select(v.first, isPro)
              : null,
        ),
      ),
    };
  }
}
