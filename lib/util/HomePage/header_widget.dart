import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/theme/spacing.dart';

class HeaderWidget extends StatelessWidget {
  final String userName;
  final String greetingMessage;
  final VoidCallback? onMenuTap;
  final Widget? menuWidget;

  const HeaderWidget({
    required this.userName,
    required this.greetingMessage,
    this.onMenuTap,
    this.menuWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final appLocale = AppLocalizations.of(context);
                    final greeting = appLocale != null
                        ? appLocale.greetings(userName).trim()
                        : (userName.isEmpty ? 'Hi,' : 'Hi $userName,');
                    return Text(
                      greeting,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  greetingMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (menuWidget != null)
                menuWidget!
              else
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                  onPressed: onMenuTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

