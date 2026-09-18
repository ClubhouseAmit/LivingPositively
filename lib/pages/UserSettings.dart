import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_store.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/util/Share/LP_alert_dialog.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';
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
// Note: fields follow DESIGN.md's input tokens (radius 10, 1px outline) via
// the app-wide `inputDecorationTheme`, not the design's 12. The action
// buttons keep the design's 14 radius, narrower than DESIGN.md's 20.

/// Gap between the screen's top-level sections.
const double _kSectionGap = 8;

/// Horizontal inset the content stack gives up on each side.
const double _kContentInsetX = 40;

/// Widest the content stack gets — beyond this it stays phone-width and
/// centres, rather than stretching a one-column form across a tablet.
const double _kContentMaxWidth = 393;

/// Gap between a field's label and its control.
const double _kLabelToField = 4;

/// Height of a text/dropdown field — DESIGN.md §3.4.
const double _kFieldHeight = 40;

/// Corner radius shared by fields, the appearance cards, and the divider-less
/// containers on this screen. The app's input token, so the non-input controls
/// here sit on the same profile as the fields.
const double _kFieldRadius = kInputRadius;

/// Inside horizontal padding of a field.
const double _kFieldPaddingX = kInputPaddingX;

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
    try {
      PersistentMemoryService service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      await service.setItem("localeName", PersistentMemoryType.String, locale);

      if (!mounted) {
        return;
      }
      setState(() {
        widget.changeLocale(locale);
        userInfoProvider.updateLocaleName(locale);
      });
    } catch (error, stackTrace) {
      debugPrint('Could not save settings locale: $error\n$stackTrace');
    }
  }

  Future<void> _applyGenderInBackground(
    Gender gender,
    UserInformation userInfoProvider,
  ) async {
    try {
      await gender.applyTo(userInfoProvider);
    } catch (error, stackTrace) {
      debugPrint('Could not save settings gender: $error\n$stackTrace');
    }
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

  /// The country picker draws its own container rather than going through
  /// `InputDecoration`, so it restates what the input theme gives the other
  /// fields: the same radius and 1px outline, and the same fill (none in
  /// light mode, the elevated surface in dark).
  BoxDecoration _fieldDecoration(ThemeData theme) {
    final InputDecorationThemeData inputs = theme.inputDecorationTheme;
    return BoxDecoration(
      color: inputs.filled ? inputs.fillColor : null,
      borderRadius: BorderRadius.circular(_kFieldRadius),
      border: Border.fromBorderSide(
        inputs.enabledBorder?.borderSide ?? BorderSide.none,
      ),
    );
  }

  /// The screen's five controls share one exact height, which the app-wide
  /// `inputDecorationTheme` deliberately leaves free (multi-line fields
  /// elsewhere have to grow). Everything else — fill, radius, borders — comes
  /// from the theme.
  ///
  /// `suffixIconConstraints` is the other addition: `DropdownMenu` hands its
  /// chevron to the decorator as an `IconButton`, whose 48 minimum tap target
  /// would otherwise make every dropdown taller than the name field.
  InputDecorationThemeData _fieldInputTheme(BuildContext context) =>
      Theme.of(context).inputDecorationTheme.copyWith(
        constraints: const BoxConstraints.tightFor(height: _kFieldHeight),
        suffixIconConstraints: const BoxConstraints.tightFor(
          width: 32,
          height: _kFieldHeight,
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
      inputDecorationTheme: _fieldInputTheme(context),
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
    try {
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

      await userInfo.updateDarkModeSettings(
        startHour: isStart ? selectedTime.hour : null,
        startMinute: isStart ? selectedTime.minute : null,
        endHour: isStart ? null : selectedTime.hour,
        endMinute: isStart ? null : selectedTime.minute,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to save dark-mode schedule: $error\n$stackTrace');
    }
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
            padding: const EdgeInsets.all(AppSpacing.sm),
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
        _darkModeOptions(userInfo, colorScheme, preference),
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
                  onPressed: () {
                    unawaited(_selectDarkModeTime(userInfo, isStart: true));
                  },
                ),
              ),
              Expanded(
                child: _scheduleButton(
                  colorScheme,
                  buttonKey: const Key('darkModeEndTimeButton'),
                  label:
                      '${appLocale.darkModeEndTime}: ${endTime.format(context)}',
                  onPressed: () {
                    unawaited(_selectDarkModeTime(userInfo, isStart: false));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDarkModePreference(
    UserInformation userInfo,
    DarkModePreference value,
  ) async {
    try {
      await userInfo.updateDarkModeSettings(preference: value);
    } catch (error, stackTrace) {
      debugPrint('Unable to save dark-mode preference: $error\n$stackTrace');
    }
  }

  Widget _darkModeOptions(
    UserInformation userInfo,
    ColorScheme colorScheme,
    DarkModePreference preference,
  ) {
    return Row(
      spacing: _kModeOptionGap,
      children: [
        _darkModeOption(
          userInfo,
          colorScheme,
          preference,
          key: const Key('darkModeAlwaysLightOption'),
          icon: Icons.light_mode_outlined,
          label: appLocale.darkModeAlwaysLight,
          value: DarkModePreference.alwaysLight,
        ),
        _darkModeOption(
          userInfo,
          colorScheme,
          preference,
          key: const Key('darkModeAlwaysDarkOption'),
          icon: Icons.dark_mode_outlined,
          label: appLocale.darkModeAlwaysDark,
          value: DarkModePreference.alwaysDark,
        ),
        _darkModeOption(
          userInfo,
          colorScheme,
          preference,
          key: const Key('darkModeScheduledOption'),
          icon: Icons.schedule_outlined,
          label: appLocale.darkModeSleepPromoting,
          value: DarkModePreference.scheduled,
        ),
      ],
    );
  }

  Widget _darkModeOption(
    UserInformation userInfo,
    ColorScheme colorScheme,
    DarkModePreference preference, {
    required Key key,
    required IconData icon,
    required String label,
    required DarkModePreference value,
  }) {
    return _modeOption(
      colorScheme,
      optionKey: key,
      icon: icon,
      label: label,
      selected: preference == value,
      onTap: () => unawaited(_selectDarkModePreference(userInfo, value)),
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

  /// The two bottom actions. Same 44-high pill; only the fill and the
  /// optional outline differ. The label takes its colour from the button's
  /// `foregroundColor` rather than restating it.
  ///
  /// Not `ConfirmationButton`/`ResetButton` from `styles.dart`: those are
  /// radius-20 and route their label through the deprecated
  /// `myAutoSizedText`, which paints at its `maxFontSize` here.
  Widget _actionButton({
    Key? buttonKey,
    required Color background,
    required Color foreground,
    required String label,
    required VoidCallback onPressed,
    BorderSide side = BorderSide.none,
  }) {
    return SizedBox(
      height: _kActionButtonHeight,
      child: TextButton(
        key: buttonKey,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kActionButtonRadius),
            side: side,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _kActionLabelSize.sp,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
      ),
    );
  }

  //remove log-in data and reset all data that user has filled in the app:
  Future<void> resetData(UserInformation userInfo) async {
    LocaleService localeService = GetIt.instance<LocaleService>();
    final PersistentMemoryService service = userInfo.service;

    // Cancel feature operations that have not reached the memory queue yet,
    // so a delayed photo/history write cannot restore data after this reset.
    if (GetIt.instance.isRegistered<BreathingStore>()) {
      GetIt.instance<BreathingStore>().invalidatePendingWrites();
    }
    await service.reset(); // Reset the persistent memory service
    await userInfo.reset(localeService.getLocale());
    var enteredBeforeValue = await service.getItem(
      "enteredBefore",
      PersistentMemoryType.Bool,
    );
    var hasFilledValue = await service.getItem(
      "hasFilled",
      PersistentMemoryType.Bool,
    );

    if (!mounted) {
      return;
    }
    widget.phonePageData.reset();
    setState(() {
      enteredBefore = enteredBeforeValue;
      hasFilled = hasFilledValue;
    });

    await pickerService.deleteImages();

    if (!mounted) {
      return;
    }
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

  /// Attempts the complete reset flow and reports whether it completed.
  ///
  /// The confirmation dialog owns the in-progress state and offers the retry
  /// affordance when this command returns `false`.
  Future<bool> _attemptResetAndReturnSuccess(UserInformation userInfo) async {
    try {
      await resetData(userInfo);
      return true;
    } catch (_) {
      return false;
    }
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

  PreferredSizeWidget _settingsAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    String gender,
    bool canPop,
  ) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 40,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: canPop
          ? Center(
              child: SizedBox.square(
                dimension: AppSpacing.xxxl,
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
    );
  }

  Widget _nameSetting(ColorScheme colorScheme, String gender) {
    return _field(
      colorScheme,
      appLocale.userSettingsName(gender),
      TextFormField(
        controller: _namecontroller,
        style: _valueStyle(colorScheme),
        decoration: InputDecoration(
          suffixIconConstraints: const BoxConstraints(
            minHeight: _kFieldHeight,
            maxHeight: _kFieldHeight,
          ),
          suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
              ? SpeechDictationSuffixAction(controller: _namecontroller)
              : null,
        ),
        validator: (text) {
          if ((text ?? '').trim().isEmpty) {
            return appLocale.nameRequiredError;
          }
          return null;
        },
      ),
    );
  }

  Widget _ageSetting(
    ColorScheme colorScheme,
    String gender,
    double fieldWidth,
  ) {
    return _field(
      colorScheme,
      appLocale.userSettingsAge(gender),
      _dropdown(
        colorScheme,
        fieldWidth,
        initialSelection: dropdownValueAge,
        options: ages,
        isSelected: (age) => dropdownValueAge == age,
        onSelected: (newValue) {
          if (newValue != null) setState(() => dropdownValueAge = newValue);
        },
      ),
    );
  }

  Widget _genderSetting(
    UserInformation userInfo,
    ColorScheme colorScheme,
    String gender,
    String selectedLabel,
    double fieldWidth,
  ) {
    return _field(
      colorScheme,
      appLocale.userSettingsGender(gender),
      _dropdown(
        colorScheme,
        fieldWidth,
        initialSelection: selectedLabel,
        options: genders,
        isSelected: (option) => selectedLabel == option,
        onSelected: (newValue) {
          if (newValue != null) {
            setState(
              () => selectedGender = Gender.fromLabel(newValue, appLocale),
            );
          }
        },
      ),
    );
  }

  Widget _languageSetting(
    UserInformation userInfo,
    ColorScheme colorScheme,
    String gender,
    String selectedLocaleName,
    double fieldWidth,
  ) {
    return _field(
      colorScheme,
      appLocale.selectLanguage(gender),
      _dropdown(
        colorScheme,
        fieldWidth,
        initialSelection: selectedLocaleName,
        options: localesNames,
        isSelected: (locale) => languageCode(locale) == userInfo.localeName,
        onSelected: (newValue) {
          if (newValue != null) {
            unawaited(updateLocale(languageCode(newValue), userInfo));
          }
        },
      ),
    );
  }

  Widget _profileSettings(
    UserInformation userInfo,
    ThemeData theme,
    ColorScheme colorScheme,
    String gender,
    String selectedGenderLabel,
    String selectedLocaleName,
    double fieldWidth,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _kSectionGap,
        children: [
          _nameSetting(colorScheme, gender),
          _ageSetting(colorScheme, gender, fieldWidth),
          _genderSetting(
            userInfo,
            colorScheme,
            gender,
            selectedGenderLabel,
            fieldWidth,
          ),
          _languageSetting(
            userInfo,
            colorScheme,
            gender,
            selectedLocaleName,
            fieldWidth,
          ),
          _divider(colorScheme),
          CountrySelectorWidget(
            text: appLocale.locationSelect(gender),
            disclaimerText: appLocale.locationDisclaimer(gender),
            labelStyle: _labelStyle(colorScheme),
            labelGap: _kLabelToField,
            fieldDecoration: _fieldDecoration(theme),
            fieldHeight: _kFieldHeight,
            helpButtonSize: 20,
          ),
          _divider(colorScheme),
          _buildDarkModeSettings(userInfo, colorScheme),
        ],
      ),
    );
  }

  void _saveSettings(UserInformation userInfo) {
    FocusScope.of(context).unfocus();
    if (!_settingsFormKey.currentState!.validate()) return;
    userInfo
      ..updateName(_namecontroller.text.trim())
      ..updateAge(dropdownValueAge == '' ? userInfo.age : dropdownValueAge!);
    if (selectedGender != null) {
      unawaited(_applyGenderInBackground(selectedGender!, userInfo));
    }
    Navigator.pop(context);
  }

  Widget _actionSection(
    UserInformation userInfo,
    ColorScheme colorScheme,
    String gender,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _kSectionGap,
        children: [
          _divider(colorScheme),
          _actionButton(
            background: colorScheme.primary,
            foreground: colorScheme.onPrimary,
            label: appLocale.confirmButton(gender),
            onPressed: () => _saveSettings(userInfo),
          ),
          _actionButton(
            buttonKey: const Key('user-settings-reset-open'),
            background: colorScheme.surface,
            foreground: colorScheme.error,
            side: BorderSide(color: colorScheme.error, width: 1.5),
            label: appLocale.userSettingsReset(gender),
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => _ResetConfirmationDialog(
                gender: gender,
                onAttemptReset: () => _attemptResetAndReturnSuccess(userInfo),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsContent(
    UserInformation userInfo,
    ThemeData theme,
    ColorScheme colorScheme,
    String gender,
    String selectedGenderLabel,
    String selectedLocaleName,
    double fieldWidth,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Spacer(),
                _profileSettings(
                  userInfo,
                  theme,
                  colorScheme,
                  gender,
                  selectedGenderLabel,
                  selectedLocaleName,
                  fieldWidth,
                ),
                _actionSection(userInfo, colorScheme, gender),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    genders = Gender.labels(appLocale);
    final userInfo = Provider.of<UserInformation>(context);
    final gender = userInfo.gender;
    final contentWidth = math.min(
      _kContentMaxWidth,
      MediaQuery.sizeOf(context).width,
    );
    final fieldWidth = math.max(0.0, contentWidth - _kContentInsetX);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedGenderLabel =
        selectedGender?.label(appLocale) ??
        Gender.of(userInfo).label(appLocale);
    final selectedLocaleName = locales.contains(userInfo.localeName)
        ? localesNames[locales.indexOf(userInfo.localeName)]
        : localesNames.first;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _settingsAppBar(
          theme,
          colorScheme,
          gender,
          Navigator.of(context).canPop(),
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Form(
                key: _settingsFormKey,
                child: _settingsContent(
                  userInfo,
                  theme,
                  colorScheme,
                  gender,
                  selectedGenderLabel,
                  selectedLocaleName,
                  fieldWidth,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmation route for the destructive settings reset flow.
///
/// Busy state lives with the route so its actions and system back navigation
/// stay blocked until the reset attempt either succeeds or exposes a retry.
class _ResetConfirmationDialog extends StatefulWidget {
  const _ResetConfirmationDialog({
    required this.gender,
    required this.onAttemptReset,
  });

  final String gender;
  final Future<bool> Function() onAttemptReset;

  @override
  State<_ResetConfirmationDialog> createState() =>
      _ResetConfirmationDialogState();
}

class _ResetConfirmationDialogState extends State<_ResetConfirmationDialog> {
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
                TextButton(
                  key: const Key('user-settings-reset-cancel'),
                  onPressed: _resetInProgress
                      ? null
                      : () => Navigator.of(snackBarContext).pop(),
                  child: Text(appLocale.closeButton(widget.gender)),
                ),
                TextButton(
                  key: const Key('user-settings-reset-confirm'),
                  onPressed: _resetInProgress
                      ? null
                      : () {
                          unawaited(_attemptReset(snackBarContext));
                        },
                  child: Text(appLocale.confirmButton(widget.gender)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
