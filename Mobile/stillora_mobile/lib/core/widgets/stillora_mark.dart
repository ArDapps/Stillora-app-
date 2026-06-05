import 'package:flutter/material.dart';

import '../design/stillora_glow.dart';

class StilloraMark extends StatelessWidget {
  const StilloraMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return StilloraPulse(
      builder: (context, t) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: stilloraBrandGradient,
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffd946ef).withValues(alpha: 0.3 + t * 0.3),
                blurRadius: size * 0.3 + t * size * 0.25,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xff22d3ee).withValues(alpha: 0.25 + t * 0.3),
                blurRadius: size * 0.4 + t * size * 0.3,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: size * 0.56,
          ),
        );
      },
    );
  }
}
