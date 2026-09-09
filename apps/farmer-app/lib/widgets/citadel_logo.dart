import 'package:flutter/material.dart';

/// Canonical Citadel brand mark used throughout the application.
class CitadelLogo extends StatelessWidget {
  static const assetPath = 'assets/citadel_logo_bg_remove.png';

  final double size;
  final BoxFit fit;

  const CitadelLogo({
    super.key,
    this.size = 40,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Citadel logo',
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        cacheWidth: (size * 3).round(),
        cacheHeight: (size * 3).round(),
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
