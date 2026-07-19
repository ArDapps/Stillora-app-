import 'package:flutter/material.dart';

import '../design/stillora_colors.dart';

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
    this.label = 'Start over',
    this.confirmMessage =
        'This clears the media and settings on this tab. This cannot be undone.',
  });

  /// Called once the user confirms. Wire this to the controller's reset/clear.
  final VoidCallback onReset;

  final bool enabled;
  final String label;
  final String confirmMessage;

  Future<void> _confirm(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start over?'),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
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
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: StilloraColors.onSurfaceVariant,
      ),
    );
  }
}
