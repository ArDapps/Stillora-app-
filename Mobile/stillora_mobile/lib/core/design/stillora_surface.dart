import 'dart:ui';

import 'package:flutter/material.dart';

import 'stillora_colors.dart';
import 'stillora_glow.dart';
import 'stillora_spacing.dart';

class StilloraGlassCard extends StatelessWidget {
  const StilloraGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(StilloraSpacing.sm),
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? StilloraColors.primary
        : StilloraColors.glassStroke;

    return ClipRRect(
      borderRadius: BorderRadius.circular(StilloraRadius.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: StilloraColors.surfaceContainer.withValues(alpha: 0.62),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            side: BorderSide(color: borderColor, width: selected ? 2 : 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class StilloraSectionHeader extends StatelessWidget {
  const StilloraSectionHeader({
    super.key,
    required this.title,
    required this.step,
    this.subtitle,
  });

  final String title;
  final String step;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: StilloraSpacing.xs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StilloraColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        StilloraStepBadge(label: step),
      ],
    );
  }
}

class StilloraStepBadge extends StatelessWidget {
  const StilloraStepBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return StilloraPulse(
      builder: (context, t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: stilloraBrandGradient,
            borderRadius: BorderRadius.circular(StilloraRadius.full),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff8b5cf6).withValues(alpha: 0.4 + t * 0.4),
                blurRadius: 8 + t * 12,
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        );
      },
    );
  }
}

class StilloraPrimaryButton extends StatelessWidget {
  const StilloraPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return StilloraGlowButton(label: label, icon: icon, onPressed: onPressed);
  }
}
