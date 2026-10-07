import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, this.success = false});
  final String text;
  final bool success;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: success
          ? AppColors.green.withValues(alpha: .10)
          : AppColors.lightBlue,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: success ? AppColors.green : AppColors.primary,
      ),
    ),
  );
}
