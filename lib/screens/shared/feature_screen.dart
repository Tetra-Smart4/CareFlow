import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.medical_services_outlined,
    this.items = const [],
    this.actions = const [],
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> items;
  final List<FeatureAction> actions;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.lightBlue,
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton.icon(
                onPressed: a.onPressed,
                icon: Icon(a.icon),
                label: Text(a.label),
              ),
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (e) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.green,
                  ),
                  title: Text(e),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FeatureAction {
  const FeatureAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}
