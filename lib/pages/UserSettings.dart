import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class UserSettings extends StatefulWidget {

  const UserSettings({
    required this.username, required this.age, required this.gender, required this.phonePageData, required this.changeLocale, super.key,
  });
  final String username;
  final String age;
  final String gender;

  final Function changeLocale;
  final PhonePageData phonePageData;
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
  String? dropdownValueGender;
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
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.setItem('localeName', PersistentMemoryType.String, locale);

    setState(() {
      widget.changeLocale(locale);
      userInfoProvider.updateLocaleName(locale);
    });
  }

  double getSizeOfTextGender(AppLocalizations locale) {
    switch (locale.language) {
      case 'עברית':
        return 18.sp;

      case 'English':
        return 14.sp;

      default:
        return 16.sp;
    }
  }

  String _genderLabel(UserInformation userInfo, AppLocalizations locale) {
    if (userInfo.binary) {
      return locale.nonBinary;
    }
    if (userInfo.gender == 'male') {
      return locale.male;
    }
    if (userInfo.gender == 'female') {
      return locale.female;
    }
    return locale.notWillingToSay;
  }

  void _applyGenderSelection(
    UserInformation userInfo,
    AppLocalizations locale,
    String selectedGender,
  ) {
    if (selectedGender == locale.male) {
      userInfo.updateGender('male');
      userInfo.updateBinary(false);
    } else if (selectedGender == locale.female) {
      userInfo.updateGender('female');
      userInfo.updateBinary(false);
    } else if (selectedGender == locale.nonBinary) {
      userInfo.updateGender('');
      userInfo.updateBinary(true);
    } else {
      userInfo.updateGender('');
      userInfo.updateBinary(false);
    }
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

    await userInfo.updateDarkModeSettings(
      startHour: isStart ? selectedTime.hour : null,
      startMinute: isStart ? selectedTime.minute : null,
      endHour: isStart ? null : selectedTime.hour,
      endMinute: isStart ? null : selectedTime.minute,
    );
  }

  Widget _buildDarkModeSettings(
    UserInformation userInfo,
    double settingsFieldWidth,
    ColorScheme colorScheme,
  ) {
    final isScheduled =
        userInfo.darkModePreference == DarkModePreference.scheduled;
    final startTime = TimeOfDay(
      hour: userInfo.darkModeStartHour,
      minute: userInfo.darkModeStartMinute,
    );
    final endTime = TimeOfDay(
      hour: userInfo.darkModeEndHour,
      minute: userInfo.darkModeEndMinute,
    );

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocale.darkModeSettingsTitle,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              RadioGroup<DarkModePreference>(
                groupValue: userInfo.darkModePreference,
                onChanged: (preference) async {
                  if (preference != null) {
                    await userInfo.updateDarkModeSettings(
                      preference: preference,
                    );
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<DarkModePreference>(
                      key: const Key('darkModeAlwaysLightOption'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(appLocale.darkModeAlwaysLight),
                      value: DarkModePreference.alwaysLight,
                      activeColor: colorScheme.primary,
                    ),
                    RadioListTile<DarkModePreference>(
                      key: const Key('darkModeAlwaysDarkOption'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(appLocale.darkModeAlwaysDark),
                      value: DarkModePreference.alwaysDark,
                      activeColor: colorScheme.primary,
                    ),
                    RadioListTile<DarkModePreference>(
                      key: const Key('darkModeScheduledOption'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(appLocale.darkModeSleepPromoting),
                      value: DarkModePreference.scheduled,
                      activeColor: colorScheme.primary,
                    ),
                  ],
                ),
              ),
              if (isScheduled) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  key: const Key('darkModeStartTimeButton'),
                  onPressed: () => _selectDarkModeTime(userInfo, isStart: true),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    '${appLocale.darkModeStartTime}: ${startTime.format(context)}',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('darkModeEndTimeButton'),
                  onPressed: () =>
                      _selectDarkModeTime(userInfo, isStart: false),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    '${appLocale.darkModeEndTime}: ${endTime.format(context)}',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  //remove log-in data and reset all data that user has filled in the app:
  Future<void> resetData(UserInformation userInfo) async {
    final localeService = GetIt.instance<LocaleService>();
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.reset(); // Reset the persistent memory service
    final enteredBeforeValue = await service.getItem(
      'enteredBefore',
      PersistentMemoryType.Bool,
    );
    final hasFilledValue = await service.getItem(
      'hasFilled',
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

    userInfo.reset(localeService.getLocale());
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
      (route) => false,
    );
  }

  Column resizeText(text) {
    final colorScheme = Theme.of(context).colorScheme;
    if (text == '') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      );
    }
    final List<String> sep = text.split('(');

    sep[1] = '(${sep[1]}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          sep[0],
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.normal,
                color: colorScheme.onSurface,
              ),
        ),
        AutoSizeText(
          sep[1],
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.normal,
                color: colorScheme.onSurface,
              ),
        ),
      ],
    );
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

    genders = [
      appLocale.male,
      appLocale.female,
      appLocale.nonBinary,
      appLocale.notWillingToSay,
    ];
    final userInfoProvider = Provider.of<UserInformation>(context);

    final gender = userInfoProvider.gender;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedGenderLabel =
        dropdownValueGender ?? _genderLabel(userInfoProvider, appLocale);
    final selectedLocaleName = locales.contains(userInfoProvider.localeName)
        ? localesNames[locales.indexOf(userInfoProvider.localeName)]
        : localesNames.first;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PageLayoutWrapper(
        sliverAppBar: PremiumGlassAppBar(
          variant: AppBarVariant.detailScreen,
          titleText: appLocale.userSettingsTitle(gender),
        ),
        body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Form(
                key: _settingsFormKey,
                child: Column(
                  children: [
                  const SizedBox(height: Spacing.md),
                  // ── Profile Card (Name, Age, Gender) ──
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            resizeText(appLocale.userSettingsName(gender)),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _namecontroller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
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
                            const SizedBox(height: Spacing.md),
                            AutoSizeText(
                              appLocale.userSettingsAge(gender),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            //AGE:
                            SizedBox(
                              width: double.infinity,
                              child: DropdownMenu<String>(
                                width: double.infinity,
                                initialSelection: dropdownValueAge,
                                dropdownMenuEntries: [
                                  ...ages.map(
                                    (age) => buildDropdownMenuEntry(
                                      age,
                                      dropdownValueAge == age
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                                onSelected: (newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      dropdownValueAge = newValue;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            AutoSizeText(
                              appLocale.userSettingsGender(gender),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            //GENDER:
                            SizedBox(
                              width: double.infinity,
                              child: DropdownMenu<String>(
                                initialSelection: selectedGenderLabel,
                                width: double.infinity,
                                dropdownMenuEntries: [
                                  ...genders.map(
                                    (gender) => buildDropdownMenuEntry(
                                      gender,
                                      selectedGenderLabel == gender
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                                onSelected: (newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      dropdownValueGender = newValue;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  // ── Preferences Card (Language, Location) ──
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              appLocale.selectLanguage(gender),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: DropdownMenu<String>(
                                initialSelection: selectedLocaleName,
                                width: double.infinity,
                                dropdownMenuEntries: [
                                  ...localesNames.map(
                                    (locale) => buildDropdownMenuEntry(
                                      locale,
                                      languageCode(locale) ==
                                              userInfoProvider.localeName
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                                onSelected: (newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      final val = languageCode(newValue);
                                      updateLocale(val, userInfoProvider);
                                    }
                                  });
                                },
                              ),
                            ),
                            CountrySelectorWidget(
                              text: appLocale.locationSelect(gender),
                              disclaimerText: appLocale.locationDisclaimer(gender),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  // ── Dark Mode Card ──
                  _buildDarkModeSettings(
                    userInfoProvider,
                    double.infinity,
                    colorScheme,
                  ),
                  const SizedBox(height: Spacing.xl + Spacing.lg),
                  ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      if (!_settingsFormKey.currentState!.validate()) {
                        return;
                      }

                      userInfoProvider.updateName(_namecontroller.text.trim());
                      userInfoProvider.updateAge(
                        dropdownValueAge == ''
                            ? userInfoProvider.age
                            : dropdownValueAge!,
                      );
                      if (dropdownValueGender != null) {
                        _applyGenderSelection(
                          userInfoProvider,
                          appLocale,
                          dropdownValueGender!,
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: Text(appLocale.confirmButton(gender)),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: SizedBox(
                                width: double.infinity,
                                child: SingleChildScrollView(
                                  // Wrap Column with SingleChildScrollView
                                  child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    // text on the top of the form
                                    AutoSizeText(
                                      appLocale.confirmResetTitle,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        50,
                                        0,
                                        50,
                                        0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          // the close button
                                          TextButton(
                                            child: Text(
                                              appLocale.closeButton(gender),
                                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          // the save button
                                          TextButton(
                                            child: Text(
                                              appLocale.confirmButton(gender),
                                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            onPressed: () {
                                              resetData(userInfoProvider);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          );
                        },
                      );
                    },
                    child: Text(appLocale.userSettingsReset(gender)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
