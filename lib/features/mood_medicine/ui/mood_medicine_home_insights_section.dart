import 'package:flutter/material.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/spacing.dart';

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
    this.isAvailable = true,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool shouldStackAction =
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
                  myText(title, theme.textTheme.titleMedium, TextAlign.start),
                  const SizedBox(height: AppSpacing.xs),
                  myText(subtitle, theme.textTheme.bodyMedium, TextAlign.start),
                ],
              ),
            );

            // This compact text-only CTA intentionally remains a TextButton:
            // ConfirmationButton is full-width and LinkButton requires an
            // icon, so neither shared primitive matches this card's design.
            final Widget action = TextButton(
              key: const Key('moodMedicineHomeInsights'),
              onPressed: isAvailable ? onPressed : null,
              child: myAutoSizedText(
                actionLabel,
                theme.textTheme.labelLarge,
                TextAlign.center,
                theme.textTheme.labelLarge?.fontSize ?? 14,
                1,
              ),
            );

            if (shouldStackAction) {
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
