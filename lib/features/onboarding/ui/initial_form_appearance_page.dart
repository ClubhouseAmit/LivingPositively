import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/features/appearance/ui/appearance_settings.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

/// Dedicated onboarding step for choosing the app's appearance.
class InitialFormAppearancePage extends WizardStep {
  const InitialFormAppearancePage({
    required super.key,
    required this.next,
  });

  final VoidCallback next;

  @override
  String primaryActionLabel(BuildContext context) {
    final user = Provider.of<UserInformation>(context, listen: false);
    return AppLocalizations.of(context)!.nextButton(user.gender);
  }

  @override
  WizardStepState<InitialFormAppearancePage> createState() =>
      _InitialFormAppearancePageState();
}

class _InitialFormAppearancePageState
    extends WizardStepState<InitialFormAppearancePage> {
  Future<void>? _pendingSave;
  bool _exitRequested = false;

  Future<void> _saveCurrentAppearance() {
    final user = Provider.of<UserInformation>(context, listen: false);
    return user.updateDarkModeSettings(
      preference: user.darkModePreference,
      startHour: user.darkModeStartHour,
      startMinute: user.darkModeStartMinute,
      endHour: user.darkModeEndHour,
      endMinute: user.darkModeEndMinute,
    );
  }

  void _showSaveError() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.asyncErrorMessage),
        action: SnackBarAction(
          label: l10n.asyncRetryButton,
          onPressed: () => unawaited(_retryAndAdvance()),
        ),
      ),
    );
  }

  Future<void> _retryAndAdvance() async {
    _exitRequested = false;
    try {
      final save = _saveCurrentAppearance();
      _pendingSave = save;
      await save;
      if (mounted) widget.next();
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  @override
  Future<void> onPrimaryAction() async {
    _exitRequested = false;
    try {
      await _pendingSave;
      if (mounted && !_exitRequested) widget.next();
    } catch (_) {
      if (mounted) _showSaveError();
      rethrow;
    }
  }

  @override
  Future<void> persistBeforeExit() async {
    _exitRequested = true;
    await _pendingSave;
  }

  @override
  Future<void> retryPersistBeforeExit() async {
    _exitRequested = true;
    final save = _saveCurrentAppearance();
    _pendingSave = save;
    await save;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = Provider.of<UserInformation>(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxl,
        children: [
          Column(
            key: const Key('intro-title-block'),
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.lg,
            children: [
              Text(
                l10n.onboardingAppearanceTitle,
                style: AppTextStyle.headlineMedium,
                color: colorScheme.onSurface,
                textAlign: TextAlign.center,
              ),
              Text(
                l10n.onboardingAppearanceSubtitle,
                style: AppTextStyle.bodyLarge,
                color: colorScheme.outline,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          AppearanceSettings(
            key: const Key('onboarding-appearance-settings'),
            userInformation: user,
            showTitle: false,
            onSaveStarted: (save) => _pendingSave = save,
          ),
        ],
      ),
    );
  }
}
