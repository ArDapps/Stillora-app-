import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Stillora brand mark, rendered from the shared SVG icon so the logo
/// stays identical across web, mobile, and desktop.
class StilloraMark extends StatelessWidget {
  const StilloraMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/stillora-icon.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'Stillora',
    );
  }
}
