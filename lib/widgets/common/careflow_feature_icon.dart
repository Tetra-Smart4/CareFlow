import 'package:flutter/material.dart';

class CareFlowFeatureIcon extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;
  final double containerSize;
  final double borderRadius;
  final bool hasShadow;
  final Gradient? backgroundGradient;
  final String? semanticLabel;

  const CareFlowFeatureIcon({
    super.key,
    this.icon,
    this.assetPath,
    required this.backgroundColor,
    required this.iconColor,
    this.iconSize = 32.0,
    this.containerSize = 72.0,
    this.borderRadius = 20.0,
    this.hasShadow = true,
    this.backgroundGradient,
    this.semanticLabel,
  }) : assert(icon != null || assetPath != null, 'Must provide either icon or assetPath');

  @override
  Widget build(BuildContext context) {
    Widget iconContent;
    
    if (assetPath != null) {
      iconContent = Image.asset(
        assetPath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
      );
    } else {
      iconContent = Icon(
        icon,
        size: iconSize,
        color: iconColor,
        semanticLabel: semanticLabel,
      );
    }

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: backgroundGradient == null ? backgroundColor : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: iconContent,
    );
  }
}
