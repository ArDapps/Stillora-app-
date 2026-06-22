import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact numeric "seconds" input used in place of duration sliders, so users
/// can type any number of seconds directly. Stays in sync when the value is
/// changed elsewhere (e.g. ± steppers) without fighting the cursor while typing.
class SecondsInputField extends StatefulWidget {
  const SecondsInputField({
    super.key,
    required this.seconds,
    required this.onChanged,
    this.min = 1,
    this.label = 'Duration',
  });

  final int seconds;
  final ValueChanged<int> onChanged;
  final int min;
  final String label;

  @override
  State<SecondsInputField> createState() => _SecondsInputFieldState();
}

class _SecondsInputFieldState extends State<SecondsInputField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.seconds.toString());

  @override
  void didUpdateWidget(SecondsInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seconds != oldWidget.seconds &&
        widget.seconds.toString() != _controller.text) {
      _controller.text = widget.seconds.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) return;
    widget.onChanged(parsed < widget.min ? widget.min : parsed);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: 'seconds',
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: _apply,
      onEditingComplete: () => FocusScope.of(context).unfocus(),
    );
  }
}
