import 'dart:async';

import 'package:flutter/material.dart' hide Card, Dialog, Text, TextButton;
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/features/personal_plan/ui/share/LP_alert_dialog.dart';
import 'package:mazilon/features/shell/ui/persistence_retry_snack_bar.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// Confirmation route for the destructive settings reset flow.
///
/// Busy state lives with the route so its actions and system back navigation
/// stay blocked until the reset attempt either succeeds or exposes a retry.
class ResetConfirmationDialog extends StatefulWidget {
  const ResetConfirmationDialog({
    super.key,
    required this.gender,
    required this.onAttemptReset,
  });

  final String gender;
  final Future<bool> Function() onAttemptReset;

  @override
  State<ResetConfirmationDialog> createState() =>
      ResetConfirmationDialogState();
}

class ResetConfirmationDialogState extends State<ResetConfirmationDialog> {
  bool _resetInProgress = false;

  Future<void> _attemptReset(BuildContext snackBarContext) async {
    if (_resetInProgress) {
      return;
    }

    setState(() {
      _resetInProgress = true;
    });
    final bool resetSucceeded = await widget.onAttemptReset();
    if (!mounted || !snackBarContext.mounted || resetSucceeded) {
      return;
    }

    setState(() {
      _resetInProgress = false;
    });
    showPersistenceRetrySnackBar(
      snackBarContext,
      () => _attemptReset(snackBarContext),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocale = AppLocalizations.of(context)!;
    return ScaffoldMessenger(
      child: PopScope(
        canPop: !_resetInProgress,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Builder(
            builder: (BuildContext snackBarContext) => LPAlertDialog(
              key: const Key('user-settings-reset-dialog'),
              title: appLocale.confirmResetTitle,
              actions: <Widget>[
                Button(
                  key: const Key('user-settings-reset-cancel'),
                  label: appLocale.closeButton(widget.gender),
                  variant: ButtonVariant.secondary,
                  fullWidth: false,
                  onPressed: _resetInProgress
                      ? null
                      : () => Navigator.of(snackBarContext).pop(),
                ),
                Button(
                  key: const Key('user-settings-reset-confirm'),
                  label: appLocale.confirmButton(widget.gender),
                  fullWidth: false,
                  onPressed: _resetInProgress
                      ? null
                      : () {
                          unawaited(_attemptReset(snackBarContext));
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
