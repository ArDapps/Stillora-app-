import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/render_components.dart';
import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_surface.dart';
import '../../core/widgets/desktop_shell.dart';
import 'editor_state.dart';
import 'video_preset.dart';
import 'video_styles.dart';
import '../../core/pro/pro_quality_picker.dart';
import '../../core/i18n/app_strings.dart';

class ChoosePresetScreen extends ConsumerWidget {
  const ChoosePresetScreen({super.key});

  static const routePath = '/choose-preset';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);

    return SidebarScaffold(
      desktopTitle: context.strings.edChooseFormat,
      appBar: AppBar(title: Text(context.strings.edChooseFormat)),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: stilloraBackgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    Text(
                      'Create',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: StilloraColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.strings.edPresets,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StilloraStepBadge(label: context.strings.edStep3),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.45,
                          ),
                      itemCount: videoPresets.length,
                      itemBuilder: (context, index) {
                        final preset = videoPresets[index];
                        final selected = editor.preset == preset;
                        return StilloraGlassCard(
                          selected: selected,
                          onTap: () => controller.setPreset(preset),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                preset.icon,
                                size: 22,
                                color: selected
                                    ? StilloraColors.primary
                                    : StilloraColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.labelOf(context.strings),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: selected
                                          ? StilloraColors.primary
                                          : StilloraColors.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                preset.ratioLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: StilloraColors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.strings.edResize,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    RenderPillSegmented(
                      options: [
                        context.strings.loopFit,
                        context.strings.loopFill,
                      ],
                      selectedIndex: editor.resizeMode == ResizeMode.fit
                          ? 0
                          : 1,
                      onSelected: (i) => controller.setResizeMode(
                        i == 0 ? ResizeMode.fit : ResizeMode.fill,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.strings.toolQuality,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    ProQualityPicker(
                      selected: editor.exportQuality,
                      onSelected: controller.setExportQuality,
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final res = scaledResolution(
                          editor.preset,
                          editor.exportQuality,
                        );
                        return Text(
                          '${res.width} × ${res.height}'
                          '  ·  ≈ ${formatFileSize(editor.estimatedExportBytes)}'
                          '  ·  ${editor.exportQuality.note(context.strings)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: StilloraColors.onSurfaceVariant,
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    StylePickerRow<ClipEffect>(
                      title: context.strings.edEffect,
                      values: ClipEffect.values,
                      selected: editor.effect,
                      labelOf: (e) => e.label(context.strings),
                      iconOf: (e) => e.icon,
                      onSelected: controller.setEffect,
                    ),
                    const SizedBox(height: 16),
                    StylePickerRow<FrameTransition>(
                      title: context.strings.edTransition,
                      values: FrameTransition.values,
                      selected: editor.transition,
                      labelOf: (t) => t.label(context.strings),
                      iconOf: (t) => t.icon,
                      onSelected: controller.setTransition,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StilloraPrimaryButton(
                  onPressed: () => context.pop(),
                  icon: Icons.check_rounded,
                  label: context.strings.edDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
