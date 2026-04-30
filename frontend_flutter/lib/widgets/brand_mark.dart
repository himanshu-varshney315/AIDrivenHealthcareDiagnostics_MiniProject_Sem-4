import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AyuvaMarkTone { light, dark, soft }

class AyuvaBrandMark extends StatelessWidget {
  final double size;
  final AyuvaMarkTone tone;
  final bool showShadow;

  const AyuvaBrandMark({
    super.key,
    this.size = 56,
    this.tone = AyuvaMarkTone.light,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = tone == AyuvaMarkTone.dark;
    final bool soft = tone == AyuvaMarkTone.soft;
    final Color symbolColor = dark ? AppTheme.clinicalGreen : Colors.white;
    final Color surfaceColor = soft ? AppTheme.scrub : Colors.white;
    final double radius = size * 0.29;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark || soft ? surfaceColor : null,
        gradient: dark || soft
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.brandGradient,
              ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark
              ? AppTheme.border
              : Colors.white.withValues(alpha: soft ? 0.0 : 0.18),
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.navy.withValues(alpha: dark ? 0.08 : 0.18),
                  blurRadius: size * 0.36,
                  offset: Offset(0, size * 0.16),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-size * 0.08, -size * 0.03),
            child: Icon(
              Icons.eco_rounded,
              color: symbolColor.withValues(alpha: 0.92),
              size: size * 0.47,
            ),
          ),
          Transform.translate(
            offset: Offset(size * 0.13, size * 0.1),
            child: Icon(
              Icons.add_rounded,
              color: symbolColor,
              size: size * 0.32,
            ),
          ),
        ],
      ),
    );
  }
}
