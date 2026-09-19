import 'package:flutter/material.dart';
import 'package:mazilon/design_system/primitives/app_card.dart';
import 'package:mazilon/design_system/primitives/app_text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/util/theme/spacing.dart';

/// Home entry point for the Mood Medicine insights dashboard.
///
/// Home supplies the already-localized display strings and navigation callback;
/// this feature-local section owns only the presentation of the entry point.
///
/// The card remains visible when Mood Medicine is unavailable so the feature
/// stays discoverable, but its action is disabled and the callback is not
/// invoked in that state.
///
/// Design-system proof (step 4): the card is now `AppCard`, not `Card` —
/// this widget is exactly the one from the screenshot that started the
/// design-system work, where a bare `Card()` rendered Material 3's default
/// radius/elevation instead of `AppRadii.card`/`AppShadows.card`. The action
/// button stays a plain `TextButton`, unmigrated: it's a compact text-only
/// CTA with no button chrome, and `AppButton` is a filled button — the same
/// mismatch this file's own comment already noted against `ConfirmationButton`
/// and `LinkButton`. Forcing it into `AppButton` would be the wrong fix.
final class MoodMedicineHomeInsightsSection extends StatelessWidget {
  /// Creates the localized Home entry point for Mood Medicine insights.
  ///
  /// [onPressed] is required even when [isAvailable] is `false`; it is kept as
  /// the callback for when the feature becomes available and is never invoked
  /// while the card is unavailable.
  const MoodMedicineHomeInsightsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
    this.isAvailable = true,
  });

  /// Localized title displayed on the Home insights card.
  final String title;

  /// Localized supporting text displayed below [title].
  final String subtitle;

  /// Localized label for the card's action button.
  final String actionLabel;

  /// Callback used to open Mood Medicine insights when [isAvailable] is true.
  ///
  /// This callback must not be invoked when the card is unavailable.
  final VoidCallback onPressed;

  /// Whether the Mood Medicine action is available.
  ///
  /// Defaults to `true`. When `false`, the localized card remains visible for
  /// discoverability while its action button is disabled.
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool shouldStackAction =
              constraints.maxWidth < 480 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.2;
          final Widget icon = const Icon(
            Icons.insights_outlined,
            color: AppColors.primary,
          );
          final Widget copy = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, style: AppTextStyle.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                AppText(subtitle, style: AppTextStyle.bodySmall),
              ],
            ),
          );

          // This compact text-only CTA intentionally remains a TextButton:
          // AppButton is a filled button and LinkButton requires an icon, so
          // neither shared primitive matches this card's design.
          final Widget action = TextButton(
            key: const Key('moodMedicineHomeInsights'),
            onPressed: isAvailable ? onPressed : null,
            child: Text(
              actionLabel,
              style: theme.textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          );

          if (shouldStackAction) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.md),
                    copy,
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                    ),
                    child: action,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.md),
              copy,
              Flexible(child: action),
            ],
          );
        },
      ),
    );
  }
}
