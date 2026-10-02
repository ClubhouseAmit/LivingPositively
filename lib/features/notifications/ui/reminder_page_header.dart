import 'package:flutter/material.dart' hide Text;
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// The introduction to the reminders settings page.
class ReminderPageHeader extends StatelessWidget {
  const ReminderPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.14),
            colors.secondary.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _titleAndSubtitle(context, locale)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleAndSubtitle(
    BuildContext context,
    AppLocalizations locale,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.headlineMedium,
          children: [
            TextSpan(
              text: locale.reminderTitleFirst,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            TextSpan(
              text: ' ${locale.reminderTitleSecond}',
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        locale.reminderPageSubtitle,
        style: AppTextStyle.bodySmall,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ],
  );
}
