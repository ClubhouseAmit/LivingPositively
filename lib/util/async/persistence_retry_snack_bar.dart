import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// Shows the shared localized retry prompt for a failed persistence action.
///
/// Callers retain ownership of [retry] and of any error reporting that occurs
/// while it runs. This helper only keeps the user-facing persistence retry UI
/// consistent across the form surfaces.
void showPersistenceRetrySnackBar(
  BuildContext context,
  Future<void> Function() retry,
) {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final AppLocalizations? appLocale = AppLocalizations.of(context);
  if (messenger == null || appLocale == null) {
    return;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(appLocale.asyncErrorMessage),
        action: SnackBarAction(
          label: appLocale.asyncRetryButton,
          onPressed: () {
            unawaited(retry());
          },
        ),
      ),
    );
}
