import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';

/// CareFlow brand logo icon matching the splash screen design.
///
/// Uses the signature CareFlow gradient (primary blue to primary green),
/// soft elevation shadow, and rounded corner styling from the splash screen.
class CareFlowLogoIcon extends StatelessWidget {
  final double size;
  final double borderRadius;
  final double iconSize;
  final bool hasShadow;
  final bool useAssetImage;

  const CareFlowLogoIcon({
    super.key,
    this.size = 30.0,
    this.borderRadius = 9.0,
    this.iconSize = 17.0,
    this.hasShadow = true,
    this.useAssetImage = false,
  });

  Widget _buildSplashGradientIcon() {
    const Color primaryBlue = Color(0xFF1976D2);
    const Color primaryGreen = Color(0xFF26A69A);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.favorite_rounded,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (useAssetImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/images/careflow_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildSplashGradientIcon(),
        ),
      );
    }

    return _buildSplashGradientIcon();
  }
}

/// Navigation bar / header brand component.
///
/// Renders a clean, well-aligned CareFlow logo icon right next to the "CareFlow" brand name,
/// matching the color scheme, typography, and layout of the application headers.
class CareFlowBrandTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double iconSize;
  final double fontSize;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool useAssetImage;

  const CareFlowBrandTitle({
    super.key,
    this.title = 'CareFlow',
    this.subtitle,
    this.iconSize = 30.0,
    this.fontSize = 20.0,
    this.textColor,
    this.onTap,
    this.useAssetImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CareFlowLogoIcon(
          size: iconSize,
          borderRadius: iconSize * 0.30,
          iconSize: iconSize * 0.58,
          useAssetImage: useAssetImage,
        ),
        const SizedBox(width: 10),
        if (subtitle == null || subtitle!.isEmpty)
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: textColor ?? ColorTokens.darkNavy,
              letterSpacing: -0.4,
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: textColor ?? ColorTokens.darkNavy,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: titleContent,
        ),
      );
    }

    return titleContent;
  }
}
