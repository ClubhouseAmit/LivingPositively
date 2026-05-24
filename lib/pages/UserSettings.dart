import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';

import 'package:mazilon/l10n/app_localizations.dart';

class UserSettings extends StatefulWidget {
  final String username;
  final String age;
  final String gender;

  final Function changeLocale;
  PhonePageData phonePageData;

  UserSettings({
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

  String? dropdownValueAge = '18-30';
  TextEditingController _namecontroller = TextEditingController();
  bool enteredBefore = false;
  bool hasFilled = false;
  String? dropdownValueGender = '';
  String? name = '';
  List<String> ages = ['18-', '18-30', '30-40', '40-55', '55+'];
  List<String> genders = [];
  List<String> locales =
      AppLocalizations.supportedLocales.map((e) => e.languageCode).toList();
  List<String> localesNames = AppLocalizations.supportedLocales
      .map((e) => languageName(e.languageCode))
      .toList();
  Future<void> updateLocale(
      String locale, UserInformation userInfoProvider) async {
    PersistentMemoryService service = GetIt.instance<
        PersistentMemoryService>(); // Get the persistent memory service instance

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

  Future<void> _signOut(UserInformation userInfo) async {
    await AuthService.signOut();
    userInfo.updateLoggedIn(false);
    userInfo.updateAuthDecisionMade(false);
    userInfo.updateEmail('');
    userInfo.updateDisplayName('');

    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();
    final enteredBeforeValue =
        await service.getItem("enteredBefore", PersistentMemoryType.Bool) ??
            false;
    final hasFilledValue =
        await service.getItem("hasFilled", PersistentMemoryType.Bool) ?? false;

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => FirstPage(
            phonePageData: widget.phonePageData,
            firsttime: !enteredBeforeValue,
            hasFilled: hasFilledValue,
            changeLocale: widget.changeLocale,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  //remove log-in data and reset all data that user has filled in the app:
  Future<void> resetData(UserInformation userInfo) async {
    LocaleService localeService = GetIt.instance<LocaleService>();
    PersistentMemoryService service = GetIt.instance<
        PersistentMemoryService>(); // Get the persistent memory service instance
    _signOut(userInfo);
    await service.reset(); // Reset the persistent memory service
    var enteredBeforeValue =
        await service.getItem("enteredBefore", PersistentMemoryType.Bool);
    var hasFilledValue =
        await service.getItem("hasFilled", PersistentMemoryType.Bool);

    widget.phonePageData.reset();
    setState(() {
      enteredBefore = enteredBeforeValue;
      hasFilled = hasFilledValue;
    });

    userInfo.reset(localeService.getLocale());
    await pickerService.deleteImages();

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => FirstPage(
                phonePageData: widget.phonePageData,
                firsttime: !enteredBefore,
                changeLocale: widget.changeLocale,
                hasFilled: hasFilled)),
        (Route<dynamic> route) => false);
  }

  // create the "what's your name?" title
  Column resizeText(text) {
    final appLocale = AppLocalizations.of(context);
    if (text == '') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          myAutoSizedText(
              text,
              TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
              appLocale!.textDirection == "rtl"
                  ? TextAlign.right
                  : TextAlign.left,
              24),
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
                color: Colors.black),
            appLocale!.textDirection == "rtl"
                ? TextAlign.right
                : TextAlign.left,
            24),
        myAutoSizedText(
            sep[1],
            TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.normal,
                color: Colors.black),
            appLocale!.textDirection == "rtl"
                ? TextAlign.right
                : TextAlign.left,
            22),
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
      appLocale.notWillingToSay
    ];
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: false);

    final gender = userInfoProvider.gender;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: appWhite,
        appBar: AppBar(
          title: myAutoSizedText(appLocale!.userSettingsTitle(gender),
              TextStyle(fontSize: 20.sp), null, 40),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                myAutoSizedText(
                    appLocale!.userSettingsTitle(gender),
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40.sp,
                    ),
                    null,
                    60),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    resizeText(
                      appLocale!.userSettingsName(gender),
                    ),
                    Container(
                      width: 300,
                      child: Container(
                        height: 35,
                        child: TextField(
                          controller: _namecontroller,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 6.0),
                          ),
                          onChanged: (text) {
                            // Do something with the text
                            name = text;
                            userInfoProvider.updateName(text);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    myAutoSizedText(
                        appLocale!.userSettingsAge(gender),
                        TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.normal,
                            color: Colors.black),
                        null,
                        30),
                    //AGE:
                    Container(
                      width: 300,
                      child: DropdownMenu<String>(
                        width: 300,
                        initialSelection: dropdownValueAge,
                        dropdownMenuEntries: [
                          ...ages
                              .map((age) => buildDropdownMenuEntry(
                                    age,
                                    dropdownValueAge == age
                                        ? const Color.fromARGB(255, 68, 0, 255)
                                        : Colors.black,
                                  ))
                              .toList()
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
                        appLocale!.userSettingsGender(gender),
                        TextStyle(
                            fontSize: getSizeOfTextGender(appLocale),
                            fontWeight: FontWeight.normal,
                            color: Colors.black),
                        null,
                        35),
                    //GENDER:
                    Container(
                      width: 300,
                      child: DropdownMenu<String>(
                        initialSelection: (userInfoProvider.binary)
                            ? appLocale!.nonBinary
                            : (userInfoProvider.gender == 'male'
                                ? appLocale.male
                                : userInfoProvider.gender == 'female'
                                    ? appLocale.female
                                    : appLocale.notWillingToSay),
                        width: 300,
                        dropdownMenuEntries: [
                          ...genders
                              .map((gender) => buildDropdownMenuEntry(
                                    gender,
                                    dropdownValueGender == gender
                                        ? const Color.fromARGB(255, 68, 0, 255)
                                        : Colors.black,
                                  ))
                              .toList()
                        ],
                        onSelected: (String? newValue) {
                          setState(() {
                            debugPrint("thsi is the selected value");
                            if (newValue != null) {
                              debugPrint(newValue);
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
                        appLocale!.selectLanguage(gender),
                        TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.normal,
                            color: Colors.black),
                        null,
                        30),
                    Container(
                      width: 300,
                      child: DropdownMenu<String>(
                        initialSelection: localesNames[
                            locales.indexOf(userInfoProvider.localeName)],
                        width: 300,
                        dropdownMenuEntries: [
                          ...localesNames
                              .map((locale) => buildDropdownMenuEntry(
                                    locale,
                                    locale == 'en'
                                        ? const Color.fromARGB(255, 68, 0, 255)
                                        : Colors.black,
                                  ))
                              .toList()
                        ],
                        onSelected: (String? newValue) {
                          setState(() {
                            if (newValue != null) {
                              debugPrint(newValue);
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
                    )
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.04,
                ),
                ConfirmationButton(context, () {
                  FocusScope.of(context).unfocus();

                  userInfoProvider.updateName(_namecontroller.text);
                  userInfoProvider.updateBinary(
                      dropdownValueGender! == appLocale.nonBinary);
                  userInfoProvider.updateAge(dropdownValueAge == ""
                      ? userInfoProvider.age
                      : dropdownValueAge!);
                  if (dropdownValueGender != null) {
                    if (dropdownValueGender == appLocale.male) {
                      userInfoProvider.updateGender('male');
                    } else if (dropdownValueGender == appLocale.female) {
                      userInfoProvider.updateGender('female');
                    } else {
                      userInfoProvider.updateGender('');
                    }
                  }
                  Navigator.pop(context);

                  //savePage(dropdownValueAge!, dropdownValueGender!);
                }, appLocale!.confirmButton(gender),
                    myTextStyle.copyWith(fontSize: 20.sp)),
                const SizedBox(height: 20),
                ResetButton(context, () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Container(
                            // set the width of the dialog to 800 if the screen width is more than 1000, else set it to the screen width
                            width: MediaQuery.of(context).size.width > 1000
                                ? 800
                                : MediaQuery.of(context).size.width,
                            child: SingleChildScrollView(
                              // Wrap Column with SingleChildScrollView
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 8,
                                  ),
                                  // text on the top of the form
                                  myAutoSizedText(
                                      appLocale.confirmResetTitle,
                                      TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.sp // text size
                                          ),
                                      null,
                                      40),

                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(50, 0, 50, 0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        // the close button
                                        TextButton(
                                          child: myAutoSizedText(
                                              appLocale!.closeButton(gender),
                                              TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      20.sp // button text size
                                                  ),
                                              null,
                                              30),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        // the save button
                                        TextButton(
                                          child: myAutoSizedText(
                                              appLocale!.confirmButton(gender),
                                              TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      20.sp // button text size
                                                  ),
                                              null,
                                              30),
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
                      });
                }, appLocale!.userSettingsReset(gender),
                    myTextStyle.copyWith(fontSize: 15.sp)),
                if (userInfoProvider.loggedIn) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(appLocale!.authSignOutConfirmTitle),
                        content: Text(appLocale!.authSignOutConfirmBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(appLocale!.closeButton(gender)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _signOut(userInfoProvider);
                            },
                            child: Text(appLocale!.authSignOut,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                    child: Text(appLocale!.authSignOut,
                        style: TextStyle(
                            color: Colors.red.shade400, fontSize: 15.sp)),
                  ),
                ],
                const SizedBox(height: 20)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
