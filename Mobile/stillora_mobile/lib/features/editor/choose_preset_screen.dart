import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/stillora_colors.dart';
import '../../core/design/stillora_surface.dart';
import 'editor_state.dart';
import 'video_preset.dart';

class ChoosePresetScreen extends ConsumerWidget {
  const ChoosePresetScreen({super.key});

  static const routePath = '/choose-preset';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Format')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: stilloraBackgroundGradient,
        ),
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
                            'Presets',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StilloraStepBadge(label: 'Step 3'),
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
                                preset.label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: selected
                                          ? StilloraColors.primary
                                          : StilloraColors.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                preset.ratioLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
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
                      'Resize',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ResizeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ResizeMode.fit,
                          icon: Icon(Icons.fit_screen_rounded),
                          label: Text('Fit'),
                        ),
                        ButtonSegment(
                          value: ResizeMode.fill,
                          icon: Icon(Icons.fullscreen_rounded),
                          label: Text('Fill'),
                        ),
                      ],
                      selected: {editor.resizeMode},
                      onSelectionChanged: (value) =>
                          controller.setResizeMode(value.first),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StilloraPrimaryButton(
                  onPressed: () => context.pop(),
                  icon: Icons.check_rounded,
                  label: 'Done',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
