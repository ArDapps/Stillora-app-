import 'package:flutter/material.dart';

class StilloraMark extends StatelessWidget {
  const StilloraMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.movie_creation_rounded,
        color: colorScheme.onPrimary,
        size: size * 0.52,
      ),
    );
  }
}
