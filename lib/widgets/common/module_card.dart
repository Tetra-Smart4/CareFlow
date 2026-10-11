import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import 'careflow_feature_icon.dart';

class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  (Color, Color) _getColors() {
    final t = title.toLowerCase();
    if (t.contains('appointment')) return (ColorTokens.primaryBlue, const Color(0xFFEAF3FE));
    if (t.contains('doctor') || t.contains('consult')) return (ColorTokens.careGreen, const Color(0xFFE9F8F0));
    if (t.contains('medicin') || t.contains('adherence')) return (const Color(0xFF1E9E78), const Color(0xFFE0F8F1));
    if (t.contains('report') || t.contains('record') || t.contains('history')) return (const Color(0xFF6D55C7), const Color(0xFFF0EDFF));
    if (t.contains('prescription')) return (const Color(0xFF6D55C7), const Color(0xFFF0EDFF));
    if (t.contains('emergency')) return (ColorTokens.error, const Color(0xFFFDEDF1));
    if (t.contains('follow')) return (const Color(0xFFE08A26), const Color(0xFFFFF3E3));
    if (t.contains('queue')) return (ColorTokens.primaryBlue, const Color(0xFFEAF3FE));
    if (t.contains('bill') || t.contains('revenue')) return (const Color(0xFF6D55C7), const Color(0xFFF0EDFF));
    if (t.contains('profile')) return (ColorTokens.primaryBlue, const Color(0xFFEAF3FE));
    if (t.contains('check') || t.contains('patient')) return (ColorTokens.careGreen, const Color(0xFFE9F8F0));
    return (ColorTokens.primaryBlue, const Color(0xFFEAF3FE));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDFE8EF)),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.primaryBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CareFlowFeatureIcon(
                  icon: icon,
                  iconColor: colors.$1,
                  backgroundColor: colors.$2,
                  containerSize: 42,
                  iconSize: 22,
                  borderRadius: 12,
                  hasShadow: false,
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ColorTokens.darkNavy),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: ColorTokens.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
