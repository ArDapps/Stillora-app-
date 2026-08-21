import 'package:flutter/material.dart';

import '../design/stillora_colors.dart';
import '../i18n/app_strings.dart';

/// The one "Start over" control every section shares: clears the tab's inputs
/// back to a blank slate after a confirmation, so a mis-picked file or a tangle
/// of settings is one click away from a fresh start.
///
/// Greyed out (rather than hidden) when there is nothing to reset, so the
/// control never jumps around as the user loads and clears media.
class StartOverButton extends StatelessWidget {
  const StartOverButton({
    super.key,
    required this.onReset,
    this.enabled = true,
    this.label,
    this.confirmMessage,
  });

  /// Called once the user confirms. Wire this to the controller's reset/clear.
  final VoidCallback onReset;

  final bool enabled;
  final String? label;

  /// Section-specific warning; falls back to the generic tab wording.
  final String? confirmMessage;

  Future<void> _confirm(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.startOverConfirm),
        content: Text(confirmMessage ?? context.strings.startOverTabWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.strings.reset),
          ),
        ],
      ),
    );
    if (shouldReset == true) onReset();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: enabled ? () => _confirm(context) : null,
      icon: const Icon(Icons.restart_alt_rounded, size: 18),
      label: Text(label ?? context.strings.startOver),
      style: TextButton.styleFrom(
        foregroundColor: StilloraColors.onSurfaceVariant,
      ),
    );
  }
}
