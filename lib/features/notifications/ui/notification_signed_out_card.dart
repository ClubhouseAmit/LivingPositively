import 'package:flutter/material.dart' hide Text;
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/auth_page.dart';

class NotificationSignedOutCard extends StatelessWidget {
  const NotificationSignedOutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text(
            locale.authNotSignedInTitle,
            style: AppTextStyle.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs + AppSpacing.hairline * 2),
          Text(
            locale.authNotSignedInBody,
            style: AppTextStyle.bodySmall,
            color: Colors.grey,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AuthPage(fromNotifications: true),
              ),
            ),
            icon: const Icon(Icons.login_outlined),
            label: Text(locale.authNotSignedInButton),
          ),
        ],
      ),
    );
  }
}
