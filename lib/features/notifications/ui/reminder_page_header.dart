import 'package:flutter/material.dart' hide Text;
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

/// The reference layout's introduction and wide-screen clock-format control.
class ReminderPageHeader extends StatefulWidget {
  const ReminderPageHeader({
    required this.onFormatChanged,
    required this.onFailure,
    super.key,
  });

  final VoidCallback onFormatChanged;
  final VoidCallback onFailure;

  @override
  State<ReminderPageHeader> createState() => _ReminderPageHeaderState();
}

class _ReminderPageHeaderState extends State<ReminderPageHeader> {
  bool _busy = false;

  Future<void> _changeFormat() async {
    if (_busy) return;
    final user = context.read<UserInformation>();
    final repository = NotificationRepository.forService(user.service);
    setState(() => _busy = true);
    try {
      await repository.setUse24HourFormat(!repository.use24HourFormat);
      widget.onFormatChanged();
    } catch (_) {
      widget.onFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;
    final repository = NotificationRepository.forService(
      context.watch<UserInformation>().service,
    );
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
              if (MediaQuery.sizeOf(context).width >= 600) ...[
                const SizedBox(width: AppSpacing.sm),
                _formatChip(context, locale, repository),
              ],
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

  Widget _formatChip(
    BuildContext context,
    AppLocalizations locale,
    NotificationRepository repository,
  ) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: _busy ? null : _changeFormat,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.badge),
        ),
        child: Text(
          repository.use24HourFormat
              ? locale.reminderHourFormat
              : locale.reminderAmPmFormat,
          style: AppTextStyle.labelSmall,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}
