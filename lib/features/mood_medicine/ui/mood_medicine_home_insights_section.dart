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
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stackAction =
                constraints.maxWidth < 480 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2;
            final Widget icon = Icon(
              Icons.insights_outlined,
              color: theme.colorScheme.primary,
            );
            final Widget copy = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            );
            final Widget action = TextButton(
              key: const Key('moodMedicineHomeInsights'),
              onPressed: onPressed,
              child: Text(actionLabel),
            );

            if (stackAction) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [icon, const SizedBox(width: 12), copy]),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: action,
                  ),
                ],
              );
            }

            return Row(
              children: [icon, const SizedBox(width: 12), copy, action],
            );
          },
        ),
      ),
    );
  }
}
