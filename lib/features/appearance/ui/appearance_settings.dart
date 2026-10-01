import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/userInformation.dart';

/// Shared appearance controls used during onboarding and in user settings.
class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({
    super.key,
    required this.userInformation,
    this.showTitle = true,
    this.onSaveStarted,
  });

  final UserInformation userInformation;
  final bool showTitle;
  final ValueChanged<Future<void>>? onSaveStarted;

  void _selectPreference(DarkModePreference preference) {
    final save = userInformation.updateDarkModeSettings(preference: preference);
    onSaveStarted?.call(save);
    unawaited(_reportSaveFailure(save, 'saving the appearance preference'));
  }

  Future<void> _reportSaveFailure(
    Future<void> save,
    String description,
  ) async {
    try {
      await save;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription(description),
        ),
      );
    }
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isStart
            ? userInformation.darkModeStartHour
            : userInformation.darkModeEndHour,
        minute: isStart
            ? userInformation.darkModeStartMinute
            : userInformation.darkModeEndMinute,
      ),
    );
    if (selectedTime == null || !context.mounted) return;

    try {
      final save = userInformation.updateDarkModeSettings(
        startHour: isStart ? selectedTime.hour : null,
        startMinute: isStart ? selectedTime.minute : null,
        endHour: isStart ? null : selectedTime.hour,
        endMinute: isStart ? null : selectedTime.minute,
      );
      onSaveStarted?.call(save);
      await save;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('saving the appearance schedule'),
        ),
      );
    }
  }

  Widget _scheduleControls(BuildContext context, AppLocalizations l10n) {
    final startTime = TimeOfDay(
      hour: userInformation.darkModeStartHour,
      minute: userInformation.darkModeStartMinute,
    );
    final endTime = TimeOfDay(
      hour: userInformation.darkModeEndHour,
      minute: userInformation.darkModeEndMinute,
    );
    return Visibility(
      visible:
          userInformation.darkModePreference == DarkModePreference.scheduled,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Expanded(
            child: _ScheduleButton(
              buttonKey: const Key('darkModeStartTimeButton'),
              label: '${l10n.darkModeStartTime}: ${startTime.format(context)}',
              onPressed: () => unawaited(_selectTime(context, isStart: true)),
            ),
          ),
          Expanded(
            child: _ScheduleButton(
              buttonKey: const Key('darkModeEndTimeButton'),
              label: '${l10n.darkModeEndTime}: ${endTime.format(context)}',
              onPressed: () => unawaited(_selectTime(context, isStart: false)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final preference = userInformation.darkModePreference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        if (showTitle)
          Text(
            l10n.darkModeSettingsTitle,
            style: AppTextStyle.titleSmall,
            color: colorScheme.outline,
            textAlign: TextAlign.start,
          ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            _AppearanceOption(
              optionKey: const Key('darkModeAlwaysLightOption'),
              icon: Icons.light_mode_outlined,
              label: l10n.darkModeAlwaysLight,
              selected: preference == DarkModePreference.alwaysLight,
              onTap: () => _selectPreference(DarkModePreference.alwaysLight),
            ),
            _AppearanceOption(
              optionKey: const Key('darkModeAlwaysDarkOption'),
              icon: Icons.dark_mode_outlined,
              label: l10n.darkModeAlwaysDark,
              selected: preference == DarkModePreference.alwaysDark,
              onTap: () => _selectPreference(DarkModePreference.alwaysDark),
            ),
            _AppearanceOption(
              optionKey: const Key('darkModeScheduledOption'),
              icon: Icons.schedule_outlined,
              label: l10n.darkModeSleepPromoting,
              selected: preference == DarkModePreference.scheduled,
              onTap: () => _selectPreference(DarkModePreference.scheduled),
            ),
          ],
        ),
        _scheduleControls(context, l10n),
      ],
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.optionKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key optionKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.outline;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          key: optionKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.input),
          child: SizedBox(
            height: AppSpacing.xxxl + AppSpacing.xxl,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.input),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    Icon(icon, size: AppSpacing.xl, color: foreground),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyle.labelSmall,
                        color: foreground,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleButton extends StatelessWidget {
  const _ScheduleButton({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: buttonKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.input),
        child: SizedBox(
          height: AppSpacing.input,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.surfaceContainerHighest),
              borderRadius: BorderRadius.circular(AppRadii.input),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  style: AppTextStyle.labelSmall,
                  color: colorScheme.onSurface,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
