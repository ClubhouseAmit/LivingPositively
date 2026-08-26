import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/gender.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';

import 'package:mazilon/l10n/app_localizations.dart';

// Geometry of the settings screen, taken from the pen.dev design
// "Settings Screen" (node h94Ks). Colours are NOT taken from it — every
// colour below resolves through the `AppColors`/`ColorScheme` tokens in
// DESIGN.md, per the user's instruction to use the brand primary for the
// action button.
//
// Note: the design's corner radii (12 for fields, 14 for buttons) are
// narrower than DESIGN.md's 20/16/10 tokens. The design's values are used
// here because implementing this screen is the request; see the summary.

/// Gap between the screen's top-level sections.
const double _kSectionGap = 8;

/// Inset around the content stack: 0 top, 20 sides, 12 bottom.

/// Horizontal inset the content stack gives up on each side.
const double _kContentInsetX = 40;

/// Widest the content stack gets — beyond this it stays phone-width and
/// centres, rather than stretching a one-column form across a tablet.
const double _kContentMaxWidth = 393;

/// Gap between a field's label and its control.
const double _kLabelToField = 4;

/// Height of a text/dropdown field.
const double _kFieldHeight = 42;

/// Corner radius shared by fields, the appearance cards, and the divider-less
/// containers on this screen.
const double _kFieldRadius = 12;

/// Inside horizontal padding of a field.
const double _kFieldPaddingX = 16;

/// Field label size (`Label` in the design's Form Field component).
const double _kLabelSize = 13;

/// Field value size (`Value` in the design's Form Field component).
const double _kValueSize = 15;

/// Appearance option card height.
const double _kModeOptionHeight = 56;

/// Gap between the three appearance option cards.
const double _kModeOptionGap = 8;

/// Gap between the appearance section's title and its option cards.
const double _kModeTitleToOptions = 6;

/// Height and radius of the two action buttons at the bottom.
const double _kActionButtonHeight = 44;
const double _kActionButtonRadius = 14;
const double _kActionLabelSize = 16;

/// Fields carry no visible outline in this design — the fill alone separates
/// them from the page. Focus and error states still need a border, so those
/// are the only ones drawn.
const OutlineInputBorder _kFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(_kFieldRadius)),
  borderSide: BorderSide.none,
);

class UserSettings extends StatefulWidget {
  final String username;
  final String age;
  final String gender;

  final Function changeLocale;
  final PhonePageData phonePageData;

  const UserSettings({
    super.key,
    required this.username,
    required this.age,
    required this.gender,
    required this.phonePageData,
    required this.changeLocale,
  });
  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends LPExtendedState<UserSettings> {
  late ImagePickerService pickerService;

  final _settingsFormKey = GlobalKey<FormState>();

  String? dropdownValueAge = '18-30';
  TextEditingController _namecontroller = TextEditingController();
  bool enteredBefore = false;
  bool hasFilled = false;
  Gender? selectedGender;
  List<String> ages = ['18-', '18-30', '30-40', '40-55', '55+'];
  List<String> genders = [];
  List<String> locales = AppLocalizations.supportedLocales
      .map((e) => e.languageCode)
      .toList();
  List<String> localesNames = AppLocalizations.supportedLocales
      .map((e) => languageName(e.languageCode))
      .toList();
  Future<void> updateLocale(
    String locale,
    UserInformation userInfoProvider,
  ) async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.setItem("localeName", PersistentMemoryType.String, locale);

    setState(() {
      widget.changeLocale(locale);
      userInfoProvider.updateLocaleName(locale);
    });
  }

  // -- Design primitives (pen.dev "Settings Screen") -----------------------

  TextStyle _labelStyle(ColorScheme colorScheme) => TextStyle(
    fontSize: _kLabelSize.sp,
    fontWeight: AppFontWeight.medium,
    letterSpacing: 0.3,
    color: colorScheme.outline,
  );

  TextStyle _valueStyle(ColorScheme colorScheme) => TextStyle(
    fontSize: _kValueSize.sp,
    fontWeight: AppFontWeight.regular,
    color: colorScheme.onSurface,
  );

  BoxDecoration _fieldDecoration(ColorScheme colorScheme) => BoxDecoration(
    color: colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(_kFieldRadius),
  );

  InputDecorationTheme _fieldInputTheme(ColorScheme colorScheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        isDense: true,
        // Tight, not a floor: `DropdownMenu` hands its trailing chevron to the
        // decorator as an `IconButton` suffix, whose 48 minimum tap target
        // would otherwise make every dropdown taller than the name field.
        // Bounding both the decorator and the suffix keeps all five controls
        // on exactly the same height.
        constraints: const BoxConstraints.tightFor(height: _kFieldHeight),
        suffixIconConstraints: const BoxConstraints.tightFor(
          width: 32,
          height: _kFieldHeight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _kFieldPaddingX,
          vertical: 10,
        ),
        border: _kFieldBorder,
        enabledBorder: _kFieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      );

  /// A label stacked above its control — the design's `Form Field` component.
  Widget _field(ColorScheme colorScheme, String label, Widget control) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: _kLabelToField,
      children: [
        Text(
          label,
          style: _labelStyle(colorScheme),
          textAlign: TextAlign.start,
        ),
        control,
      ],
    );
  }

  Widget _divider(ColorScheme colorScheme) =>
      Container(height: 1, color: colorScheme.surfaceContainerHighest);

  /// Field-styled `DropdownMenu` matching the design's picker rows.
  Widget _dropdown(
    ColorScheme colorScheme,
    double width, {
    required String? initialSelection,
    required List<String> options,
    required bool Function(String option) isSelected,
    required ValueChanged<String?> onSelected,
  }) {
    return DropdownMenu<String>(
      width: width,
      initialSelection: initialSelection,
      textStyle: _valueStyle(colorScheme),
      inputDecorationTheme: _fieldInputTheme(colorScheme),
      trailingIcon: Icon(
        Icons.keyboard_arrow_down,
        size: 20,
        color: colorScheme.outline,
      ),
      selectedTrailingIcon: Icon(
        Icons.keyboard_arrow_up,
        size: 20,
        color: colorScheme.outline,
      ),
      dropdownMenuEntries: [
        ...options.map(
          (option) => buildDropdownMenuEntry(
            option,
            isSelected(option) ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
      onSelected: onSelected,
    );
  }

  Future<void> _selectDarkModeTime(
    UserInformation userInfo, {
    required bool isStart,
  }) async {
    final initialTime = TimeOfDay(
      hour: isStart ? userInfo.darkModeStartHour : userInfo.darkModeEndHour,
      minute: isStart
          ? userInfo.darkModeStartMinute
          : userInfo.darkModeEndMinute,
    );
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime == null || !mounted) {
      return;
    }

    _runSettingsWrite(
      () => userInfo.updateDarkModeSettings(
        startHour: isStart ? selectedTime.hour : null,
        startMinute: isStart ? selectedTime.minute : null,
        endHour: isStart ? null : selectedTime.hour,
        endMinute: isStart ? null : selectedTime.minute,
      ),
    );
  }

  /// One card in the appearance segmented control (design nodes dP4Pe /
  /// wycvf / m1OpYb): icon over label, primary-tinted when selected.
  Widget _modeOption(
    ColorScheme colorScheme, {
    required Key optionKey,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final foreground = selected ? colorScheme.primary : colorScheme.outline;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          key: optionKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kFieldRadius),
          child: Container(
            height: _kModeOptionHeight,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              // The design tints the selected card with a light wash of its
              // accent; deriving it from `primary` keeps that relationship in
              // both themes instead of pinning a second literal colour.
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(_kFieldRadius),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(icon, size: 20, color: foreground),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rubix',
                      fontSize: 11.5.sp,
                      fontWeight: selected
                          ? AppFontWeight.semiBold
                          : AppFontWeight.regular,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeSettings(
    UserInformation userInfo,
    ColorScheme colorScheme,
  ) {
    final preference = userInfo.darkModePreference;
    final isScheduled = preference == DarkModePreference.scheduled;
    final startTime = TimeOfDay(
      hour: userInfo.darkModeStartHour,
      minute: userInfo.darkModeStartMinute,
    );
    final endTime = TimeOfDay(
      hour: userInfo.darkModeEndHour,
      minute: userInfo.darkModeEndMinute,
    );

    void select(DarkModePreference value) {
      _runSettingsWrite(
        () => userInfo.updateDarkModeSettings(preference: value),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: _kModeTitleToOptions,
      children: [
        Text(
          appLocale.darkModeSettingsTitle,
          style: _labelStyle(colorScheme),
          textAlign: TextAlign.start,
        ),
        Row(
          spacing: _kModeOptionGap,
          children: [
            _modeOption(
              colorScheme,
              optionKey: const Key('darkModeAlwaysLightOption'),
              icon: Icons.light_mode_outlined,
              label: appLocale.darkModeAlwaysLight,
              selected: preference == DarkModePreference.alwaysLight,
              onTap: () => select(DarkModePreference.alwaysLight),
            ),
            _modeOption(
              colorScheme,
              optionKey: const Key('darkModeAlwaysDarkOption'),
              icon: Icons.dark_mode_outlined,
              label: appLocale.darkModeAlwaysDark,
              selected: preference == DarkModePreference.alwaysDark,
              onTap: () => select(DarkModePreference.alwaysDark),
            ),
            _modeOption(
              colorScheme,
              optionKey: const Key('darkModeScheduledOption'),
              icon: Icons.schedule_outlined,
              label: appLocale.darkModeSleepPromoting,
              selected: isScheduled,
              onTap: () => select(DarkModePreference.scheduled),
            ),
          ],
        ),
        Visibility(
          visible: isScheduled,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Row(
            spacing: _kModeOptionGap,
            children: [
              Expanded(
                child: _scheduleButton(
                  colorScheme,
                  buttonKey: const Key('darkModeStartTimeButton'),
                  label:
                      '${appLocale.darkModeStartTime}: ${startTime.format(context)}',
                  onPressed: () => _selectDarkModeTime(userInfo, isStart: true),
                ),
              ),
              Expanded(
                child: _scheduleButton(
                  colorScheme,
                  buttonKey: const Key('darkModeEndTimeButton'),
                  label:
                      '${appLocale.darkModeEndTime}: ${endTime.format(context)}',
                  onPressed: () =>
                      _selectDarkModeTime(userInfo, isStart: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The schedule pickers have no counterpart in the design (which offers a
  /// "System" option instead); they borrow this screen's field geometry so
  /// they read as part of the appearance block.
  Widget _scheduleButton(
    ColorScheme colorScheme, {
    required Key buttonKey,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(_kFieldHeight),
        maximumSize: const Size.fromHeight(_kFieldHeight),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: _kFieldPaddingX),
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.surfaceContainerHighest),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
        ),
      ),
      child: Text(
        label,
        style: _valueStyle(colorScheme).copyWith(fontSize: 12.sp),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _reportResetFailure(Object error, StackTrace stackTrace) {
    if (!GetIt.instance.isRegistered<IncidentLoggerService>()) {
      debugPrint('Reset failed: $error');
      return;
    }

    unawaited(
      Future<void>.sync(
        () => GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        ),
      ).catchError((Object loggerError, StackTrace loggerStackTrace) {
        debugPrint('Reset failure reporting failed: $loggerError');
      }),
    );
  }

  void _runSettingsWrite(Future<void> Function() write) {
    unawaited(
      Future<void>.sync(write).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _reportResetFailure(error, stackTrace);
        if (mounted) {
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(appLocale.asyncErrorMessage)));
        }
      }),
    );
  }

  // Remove locally persisted data after the server-side reminder state is safe.
  Future<void> resetData(UserInformation userInfo) async {
    LocaleService localeService = GetIt.instance<LocaleService>();
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance
    final previousDefaultReminder = userInfo.getNotificationPreference(
      'default',
    );
    NotificationPreference? cancelledRemoteReminder;
    var remoteReminderCancelled = false;

    final firebaseUser = GetIt.instance.isRegistered<FirebaseAuth>()
        ? GetIt.instance<FirebaseAuth>().currentUser
        : null;
    try {
      if (firebaseUser != null && !firebaseUser.isAnonymous) {
        final cancelled =
            await FcmScheduledNotificationService.cancelDefaultForReset(
              userInformation: userInfo,
              onRemoteScheduleCancelled: (remotePreference) {
                cancelledRemoteReminder = remotePreference;
              },
            );
        if (!cancelled) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text(appLocale.resetReminderCancellationFailed),
              ),
            );
          }
          return;
        }
        remoteReminderCancelled = true;
      }
      await service.reset(); // Reset the persistent memory service
    } catch (error, stackTrace) {
      if (remoteReminderCancelled) {
        final reminderRestored =
            await FcmScheduledNotificationService.restoreDefaultReminderAfterResetFailure(
              userInformation: userInfo,
              previousPreference:
                  cancelledRemoteReminder ?? previousDefaultReminder,
            );
        if (!reminderRestored) {
          _reportResetFailure(
            StateError('Unable to restore the cancelled reminder.'),
            StackTrace.current,
          );
        }
      }
      _reportResetFailure(error, stackTrace);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(appLocale.resetDataFailed)));
      }
      return;
    }
    enteredBefore = false;
    hasFilled = false;

    try {
      runZonedGuarded<void>(widget.phonePageData.reset, _reportResetFailure);

      runZonedGuarded<void>(
        () => userInfo.reset(localeService.getLocale()),
        _reportResetFailure,
      );

      runZonedGuarded<void>(() {
        final authenticatedUser = GetIt.instance.isRegistered<FirebaseAuth>()
            ? GetIt.instance<FirebaseAuth>().currentUser
            : null;
        if (authenticatedUser != null && !authenticatedUser.isAnonymous) {
          userInfo.updateLoggedIn(true);
          userInfo.updateAuthDecisionMade(true);
          userInfo.updateUserId(authenticatedUser.uid);
          userInfo.updateEmail(authenticatedUser.email ?? '');
          userInfo.updateDisplayName(authenticatedUser.displayName ?? '');
        }
      }, _reportResetFailure);

      try {
        await Future<void>.sync(pickerService.deleteImages);
      } catch (error, stackTrace) {
        _reportResetFailure(error, stackTrace);
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => FirstPage(
              phonePageData: widget.phonePageData,
              firsttime: !enteredBefore,
              changeLocale: widget.changeLocale,
              hasFilled: hasFilled,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<bool> signOut(UserInformation userInfo) async {
    final firebaseUser = GetIt.instance.isRegistered<FirebaseAuth>()
        ? GetIt.instance<FirebaseAuth>().currentUser
        : null;
    final previousDefaultReminder = userInfo.getNotificationPreference(
      'default',
    );
    NotificationPreference? cancelledRemoteReminder;
    var reminderCancelled = false;
    if (firebaseUser != null && !firebaseUser.isAnonymous) {
      final cancelled =
          await FcmScheduledNotificationService.cancelDefaultForSignOut(
            userInformation: userInfo,
            onRemoteScheduleCancelled: (remotePreference) {
              cancelledRemoteReminder = remotePreference;
            },
          );
      if (!cancelled) {
        _reportResetFailure(
          StateError('Unable to cancel the reminder before sign-out.'),
          StackTrace.current,
        );
        if (mounted) {
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(appLocale.asyncErrorMessage)));
        }
        return false;
      }
      reminderCancelled = true;
    }

    try {
      await AuthService.signOut();
    } catch (error, stackTrace) {
      if (reminderCancelled) {
        final reminderRestored =
            await FcmScheduledNotificationService.restoreDefaultReminderAfterResetFailure(
              userInformation: userInfo,
              previousPreference:
                  cancelledRemoteReminder ?? previousDefaultReminder,
            );
        if (!reminderRestored) {
          _reportResetFailure(
            StateError('Unable to restore the cancelled reminder.'),
            StackTrace.current,
          );
        }
      }
      _reportResetFailure(error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(appLocale.asyncErrorMessage)));
      }
      return false;
    }

    userInfo.updateLoggedIn(false);
    userInfo.updateAuthDecisionMade(false);
    userInfo.updateUserId('');
    userInfo.updateEmail('');
    userInfo.updateDisplayName('');

    if (!mounted) return true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => FirstPage(
          phonePageData: widget.phonePageData,
          firsttime: !enteredBefore,
          changeLocale: widget.changeLocale,
          hasFilled: hasFilled,
        ),
      ),
      (Route<dynamic> route) => false,
    );
    return true;
  }

  @override
  void initState() {
    dropdownValueAge = widget.age;

    super.initState();
    _namecontroller = TextEditingController(text: widget.username);
    pickerService = GetIt.instance<ImagePickerService>();
  }

  @override
  void dispose() {
    super.dispose();
    _namecontroller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final appLocale = AppLocalizations.of(context);

    genders = Gender.labels(appLocale);
    final userInfoProvider = Provider.of<UserInformation>(context);

    final gender = userInfoProvider.gender;
    // The content stack is phone-width (or narrower) and gives up 20 on each
    // side; the controls inside get whatever is left.
    final contentWidth = math.min(
      _kContentMaxWidth,
      MediaQuery.sizeOf(context).width,
    );
    final settingsFieldWidth = math.max(0.0, contentWidth - _kContentInsetX);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedGenderLabel =
        selectedGender?.label(appLocale) ??
        Gender.of(userInfoProvider).label(appLocale);
    final selectedLocaleName = locales.contains(userInfoProvider.localeName)
        ? localesNames[locales.indexOf(userInfoProvider.localeName)]
        : localesNames.first;

    final canPop = Navigator.of(context).canPop();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        // Design node F4VwZQ ("Nav Bar"): flat surface, centred 17/600 title,
        // and a circular back chip on the reading-start side.
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          // 8 of padding above and below the 36-high back chip, down from the
          // design's 12, to buy back another 8 of body height.
          toolbarHeight: 40,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: canPop
              ? Center(
                  child: SizedBox.square(
                    dimension: 36,
                    child: Material(
                      color: colorScheme.surfaceContainerHighest,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          title: Text(
            appLocale.userSettingsTitle(gender),
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: AppFontWeight.semiBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Design node Ye170 ("Content"): vertical layout with flex vertical justification.
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Form(
                key: _settingsFormKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: _kSectionGap,
                                  children: [
                                    _field(
                                      colorScheme,
                                      appLocale.userSettingsName(gender),
                                      TextFormField(
                                        controller: _namecontroller,
                                        style: _valueStyle(colorScheme),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: colorScheme
                                              .surfaceContainerHighest,
                                          isDense: true,
                                          constraints:
                                              const BoxConstraints.tightFor(
                                                height: _kFieldHeight,
                                              ),
                                          suffixIconConstraints:
                                              const BoxConstraints(
                                                minHeight: _kFieldHeight,
                                                maxHeight: _kFieldHeight,
                                              ),
                                          suffixIcon:
                                              SpeechDictationSuffixAction
                                                  .isSupportedPlatform
                                              ? SpeechDictationSuffixAction(
                                                  controller: _namecontroller,
                                                )
                                              : null,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: _kFieldPaddingX,
                                                vertical: 10,
                                              ),
                                          border: _kFieldBorder,
                                          enabledBorder: _kFieldBorder,
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              _kFieldRadius,
                                            ),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              _kFieldRadius,
                                            ),
                                            borderSide: BorderSide(
                                              color: colorScheme.error,
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      _kFieldRadius,
                                                    ),
                                                borderSide: BorderSide(
                                                  color: colorScheme.error,
                                                  width: 1.5,
                                                ),
                                              ),
                                        ),
                                        validator: (text) {
                                          if ((text ?? '').trim().isEmpty) {
                                            return appLocale.nameRequiredError;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    //AGE:
                                    _field(
                                      colorScheme,
                                      appLocale.userSettingsAge(gender),
                                      _dropdown(
                                        colorScheme,
                                        settingsFieldWidth,
                                        initialSelection: dropdownValueAge,
                                        options: ages,
                                        isSelected: (age) =>
                                            dropdownValueAge == age,
                                        onSelected: (newValue) {
                                          setState(() {
                                            if (newValue != null) {
                                              dropdownValueAge = newValue;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    //GENDER:
                                    _field(
                                      colorScheme,
                                      appLocale.userSettingsGender(gender),
                                      _dropdown(
                                        colorScheme,
                                        settingsFieldWidth,
                                        initialSelection: selectedGenderLabel,
                                        options: genders,
                                        isSelected: (option) =>
                                            selectedGenderLabel == option,
                                        onSelected: (newValue) {
                                          setState(() {
                                            if (newValue != null) {
                                              selectedGender = Gender.fromLabel(
                                                newValue,
                                                appLocale,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    //LANGUAGE:
                                    _field(
                                      colorScheme,
                                      appLocale.selectLanguage(gender),
                                      _dropdown(
                                        colorScheme,
                                        settingsFieldWidth,
                                        initialSelection: selectedLocaleName,
                                        options: localesNames,
                                        isSelected: (locale) =>
                                            languageCode(locale) ==
                                            userInfoProvider.localeName,
                                        onSelected: (newValue) {
                                          if (newValue != null) {
                                            _runSettingsWrite(
                                              () => updateLocale(
                                                languageCode(newValue),
                                                userInfoProvider,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    _divider(colorScheme),
                                    CountrySelectorWidget(
                                      text: appLocale.locationSelect(gender),
                                      disclaimerText: appLocale
                                          .locationDisclaimer(gender),
                                      labelStyle: _labelStyle(colorScheme),
                                      labelGap: _kLabelToField,
                                      fieldDecoration: _fieldDecoration(
                                        colorScheme,
                                      ),
                                      fieldHeight: _kFieldHeight,
                                      helpButtonSize: 20,
                                    ),
                                    _divider(colorScheme),
                                    _buildDarkModeSettings(
                                      userInfoProvider,
                                      colorScheme,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: _kSectionGap,
                                  children: [
                                    _divider(colorScheme),
                                    SizedBox(
                                      height: _kActionButtonHeight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              _kActionButtonRadius,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          FocusScope.of(context).unfocus();
                                          if (!_settingsFormKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          final navigator = Navigator.of(
                                            context,
                                          );
                                          final scaffoldMessenger =
                                              ScaffoldMessenger.maybeOf(
                                                context,
                                              );
                                          final asyncErrorMessage =
                                              appLocale.asyncErrorMessage;

                                          userInfoProvider.updateName(
                                            _namecontroller.text.trim(),
                                          );
                                          userInfoProvider.updateAge(
                                            dropdownValueAge == ""
                                                ? userInfoProvider.age
                                                : dropdownValueAge!,
                                          );
                                          if (selectedGender
                                              case final selectedGender?) {
                                            try {
                                              await selectedGender.applyTo(
                                                userInfoProvider,
                                              );
                                            } catch (error, stackTrace) {
                                              _reportResetFailure(
                                                error,
                                                stackTrace,
                                              );
                                              if (mounted) {
                                                scaffoldMessenger?.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      asyncErrorMessage,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                          }
                                          if (!mounted) return;
                                          navigator.pop();
                                        },
                                        child: Text(
                                          appLocale.confirmButton(gender),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: _kActionLabelSize.sp,
                                            fontWeight: AppFontWeight.semiBold,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (userInfoProvider.loggedIn)
                                      SizedBox(
                                        height: _kActionButtonHeight,
                                        child: TextButton(
                                          key: const Key(
                                            'userSettingsSignOutButton',
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                colorScheme.surface,
                                            foregroundColor:
                                                colorScheme.onSurface,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _kActionButtonRadius,
                                                  ),
                                              side: BorderSide(
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          onPressed: () {
                                            showDialog<void>(
                                              context: context,
                                              builder: (dialogContext) {
                                                var isSigningOut = false;
                                                return StatefulBuilder(
                                                  builder: (dialogContext, setDialogState) => PopScope(
                                                    canPop: !isSigningOut,
                                                    child: AlertDialog(
                                                      title: Text(
                                                        appLocale
                                                            .authSignOutConfirmTitle,
                                                      ),
                                                      content: Text(
                                                        appLocale
                                                            .authSignOutConfirmBody,
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              isSigningOut
                                                              ? null
                                                              : () => Navigator.of(
                                                                  dialogContext,
                                                                ).pop(),
                                                          child: Text(
                                                            appLocale
                                                                .closeButton(
                                                                  gender,
                                                                ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              isSigningOut
                                                              ? null
                                                              : () async {
                                                                  setDialogState(
                                                                    () =>
                                                                        isSigningOut =
                                                                            true,
                                                                  );
                                                                  final signedOut =
                                                                      await signOut(
                                                                        userInfoProvider,
                                                                      );
                                                                  if (!signedOut &&
                                                                      dialogContext
                                                                          .mounted) {
                                                                    setDialogState(
                                                                      () => isSigningOut =
                                                                          false,
                                                                    );
                                                                  }
                                                                },
                                                          child: isSigningOut
                                                              ? const SizedBox(
                                                                  width: 20,
                                                                  height: 20,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  appLocale
                                                                      .authSignOut,
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: Text(
                                            appLocale.authSignOut,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: _kActionLabelSize.sp,
                                              fontWeight:
                                                  AppFontWeight.semiBold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    SizedBox(
                                      height: _kActionButtonHeight,
                                      child: TextButton(
                                        key: const Key(
                                          'userSettingsResetButton',
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: colorScheme.surface,
                                          foregroundColor: colorScheme.error,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              _kActionButtonRadius,
                                            ),
                                            side: BorderSide(
                                              color: colorScheme.error,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (dialogContext) {
                                              var isResetting = false;
                                              return StatefulBuilder(
                                                builder: (dialogContext, setDialogState) => PopScope(
                                                  canPop: !isResetting,
                                                  child: Dialog(
                                                    child: SizedBox(
                                                      width:
                                                          MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              1000
                                                          ? 800
                                                          : MediaQuery.of(
                                                              context,
                                                            ).size.width,
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          children: [
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            Text(
                                                              appLocale
                                                                  .confirmResetTitle,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18.sp,
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.fromLTRB(
                                                                    50,
                                                                    0,
                                                                    50,
                                                                    0,
                                                                  ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: <Widget>[
                                                                  TextButton(
                                                                    onPressed:
                                                                        isResetting
                                                                        ? null
                                                                        : () => Navigator.of(
                                                                            dialogContext,
                                                                          ).pop(),
                                                                    child: Text(
                                                                      appLocale
                                                                          .closeButton(
                                                                            gender,
                                                                          ),
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            16.sp,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed:
                                                                        isResetting
                                                                        ? null
                                                                        : () async {
                                                                            if (isResetting) {
                                                                              return;
                                                                            }
                                                                            setDialogState(
                                                                              () => isResetting = true,
                                                                            );
                                                                            try {
                                                                              await resetData(
                                                                                userInfoProvider,
                                                                              );
                                                                            } catch (
                                                                              error,
                                                                              stackTrace
                                                                            ) {
                                                                              _reportResetFailure(
                                                                                error,
                                                                                stackTrace,
                                                                              );
                                                                            } finally {
                                                                              if (dialogContext.mounted) {
                                                                                setDialogState(
                                                                                  () => isResetting = false,
                                                                                );
                                                                              }
                                                                            }
                                                                          },
                                                                    child:
                                                                        isResetting
                                                                        ? const SizedBox(
                                                                            width:
                                                                                20,
                                                                            height:
                                                                                20,
                                                                            child: CircularProgressIndicator(
                                                                              strokeWidth: 2,
                                                                            ),
                                                                          )
                                                                        : Text(
                                                                            appLocale.confirmButton(
                                                                              gender,
                                                                            ),
                                                                            style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 16.sp,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: Text(
                                          appLocale.userSettingsReset(gender),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: _kActionLabelSize.sp,
                                            fontWeight: AppFontWeight.semiBold,
                                            color: colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
