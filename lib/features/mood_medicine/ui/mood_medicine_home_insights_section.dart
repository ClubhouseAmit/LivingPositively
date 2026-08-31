import 'package:flutter/material.dart';

/// Home entry point for the Mood Medicine insights dashboard.
///
/// Home supplies the already-localized display strings and navigation callback;
/// this feature-local section owns only the presentation of the entry point.
final class MoodMedicineHomeInsightsSection extends StatelessWidget {
  const MoodMedicineHomeInsightsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.insights_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            TextButton(
              key: const Key('moodMedicineHomeInsights'),
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
