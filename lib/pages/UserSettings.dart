import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';

import 'package:mazilon/l10n/app_localizations.dart';

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

  double getSizeOfTextGender(AppLocalizations locale) {
    switch (locale.language) {
      case "עברית":
        return 18.sp;

      case "English":
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
      width: settingsFieldWidth,
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
    LocaleService localeService = GetIt.instance<LocaleService>();
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.reset(); // Reset the persistent memory service
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
      (Route<dynamic> route) => false,
    );
  }

  // create the "what's your name?" title
  Column resizeText(text) {
    final appLocale = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    if (text == '') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          myAutoSizedText(
            text,
            TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.normal,
              color: colorScheme.onSurface,
            ),
            appLocale!.textDirection == "rtl"
                ? TextAlign.right
                : TextAlign.left,
            24,
          ),
        ],
      );
    }
    List<String> sep = text.split("(");

    sep[1] = "(${sep[1]}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        myAutoSizedText(
          sep[0],
          TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurface,
          ),
          appLocale!.textDirection == "rtl" ? TextAlign.right : TextAlign.left,
          24,
        ),
        myAutoSizedText(
          sep[1],
          TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurface,
          ),
          appLocale.textDirection == "rtl" ? TextAlign.right : TextAlign.left,
          22,
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
    final settingsFieldWidth = formFieldWidth(context);
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
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: myAutoSizedText(
            appLocale.userSettingsTitle(gender),
            TextStyle(fontSize: 20.sp),
            null,
            40,
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _settingsFormKey,
              child: Column(
                children: [
                  myAutoSizedText(
                    appLocale.userSettingsTitle(gender),
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 40.sp),
                    null,
                    60,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      resizeText(appLocale.userSettingsName(gender)),
                      SizedBox(
                        width: settingsFieldWidth,
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
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      myAutoSizedText(
                        appLocale.userSettingsAge(gender),
                        TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.normal,
                          color: colorScheme.onSurface,
                        ),
                        null,
                        30,
                      ),
                      //AGE:
                      SizedBox(
                        width: settingsFieldWidth,
                        child: DropdownMenu<String>(
                          width: settingsFieldWidth,
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
                          onSelected: (String? newValue) {
                            setState(() {
                              if (newValue != null) {
                                dropdownValueAge = newValue;
                              }
                            });
                            // Do something with the selected value
                          },
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      myAutoSizedText(
                        appLocale.userSettingsGender(gender),
                        TextStyle(
                          fontSize: getSizeOfTextGender(appLocale),
                          fontWeight: FontWeight.normal,
                          color: colorScheme.onSurface,
                        ),
                        null,
                        35,
                      ),
                      //GENDER:
                      SizedBox(
                        width: settingsFieldWidth,
                        child: DropdownMenu<String>(
                          initialSelection: selectedGenderLabel,
                          width: settingsFieldWidth,
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
                          onSelected: (String? newValue) {
                            setState(() {
                              if (newValue != null) {
                                dropdownValueGender = newValue;
                              }
                            });
                            // Do something with the selected value
                          },
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      myAutoSizedText(
                        appLocale.selectLanguage(gender),
                        TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.normal,
                          color: colorScheme.onSurface,
                        ),
                        null,
                        30,
                      ),
                      SizedBox(
                        width: settingsFieldWidth,
                        child: DropdownMenu<String>(
                          initialSelection: selectedLocaleName,
                          width: settingsFieldWidth,
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
                          onSelected: (String? newValue) {
                            setState(() {
                              if (newValue != null) {
                                final val = languageCode(newValue);

                                updateLocale(val, userInfoProvider);
                              }
                            });
                            // Do something with the selected value
                          },
                        ),
                      ),
                      CountrySelectorWidget(
                        text: appLocale.locationSelect(gender),
                        disclaimerText: appLocale.locationDisclaimer(gender),
                      ),
                      const SizedBox(height: 20),
                      _buildDarkModeSettings(
                        userInfoProvider,
                        settingsFieldWidth,
                        colorScheme,
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  ConfirmationButton(
                    context,
                    () {
                      FocusScope.of(context).unfocus();
                      if (!_settingsFormKey.currentState!.validate()) {
                        return;
                      }

                      userInfoProvider.updateName(_namecontroller.text.trim());
                      userInfoProvider.updateAge(
                        dropdownValueAge == ""
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

                      //savePage(dropdownValueAge!, dropdownValueGender!);
                    },
                    appLocale.confirmButton(gender),
                    myTextStyle.copyWith(fontSize: 20.sp),
                  ),
                  const SizedBox(height: 20),
                  ResetButton(
                    context,
                    () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              // set the width of the dialog to 800 if the screen width is more than 1000, else set it to the screen width
                              width: MediaQuery.of(context).size.width > 1000
                                  ? 800
                                  : MediaQuery.of(context).size.width,
                              child: SingleChildScrollView(
                                // Wrap Column with SingleChildScrollView
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    // text on the top of the form
                                    myAutoSizedText(
                                      appLocale.confirmResetTitle,
                                      TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.sp, // text size
                                      ),
                                      null,
                                      40,
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
                                            child: myAutoSizedText(
                                              appLocale.closeButton(gender),
                                              TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    20.sp, // button text size
                                              ),
                                              null,
                                              30,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          // the save button
                                          TextButton(
                                            child: myAutoSizedText(
                                              appLocale.confirmButton(gender),
                                              TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    20.sp, // button text size
                                              ),
                                              null,
                                              30,
                                            ),
                                            onPressed: () {
                                              resetData(userInfoProvider);
                                              // Save the item (add or edit) to the list
                                            },
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
                      );
                    },
                    appLocale.userSettingsReset(gender),
                    myTextStyle.copyWith(fontSize: 15.sp),
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
