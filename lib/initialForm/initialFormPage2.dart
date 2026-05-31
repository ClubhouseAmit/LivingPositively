// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';
import 'package:mazilon/util/LP_extended_state.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//second page of the initial form
//this is where the user selects their age,name and gender
class InitialFormPage2 extends StatefulWidget {
  final Function next;
  final Function prev;
  final Function updateName;

  const InitialFormPage2({
    super.key,
    required this.next,
    required this.prev,
    required this.updateName,
  });
  @override
  State<InitialFormPage2> createState() => _InitialFormPage2State();
}

class _InitialFormPage2State extends LPExtendedState<InitialFormPage2> {
  String? dropdownValueAge = '18-30';
  String? dropdownValueGender = '';
  String? name = '';
  List<String> ages = ['18-', '18-30', '30-40', '40-55', '55+'];
  List<String> genders = [];

  Column resizeText(text) {
    List<String> sep = text.split("(");
    final appLocale = AppLocalizations.of(context);

    sep[1] = "(${sep[1]}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        myAutoSizedText(
          sep[0],
          TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
          appLocale!.textDirection == "rtl" ? TextAlign.right : TextAlign.left,
          24,
        ),
        myAutoSizedText(
          sep[1],
          TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
          appLocale.textDirection == "rtl" ? TextAlign.right : TextAlign.left,
          22,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);

    genders = [
      appLocale.male,
      appLocale.female,
      appLocale.nonBinary,
      appLocale.notWillingToSay,
    ];
    var gender = userInfoProvider.gender;
    dropdownValueAge = userInfoProvider.age;
    //add genders here

    dropdownValueGender = (userInfoProvider.binary)
        ? appLocale.nonBinary
        : (userInfoProvider.gender == 'male'
              ? appLocale.male
              : userInfoProvider.gender == 'female'
              ? appLocale.female
              : appLocale.notWillingToSay);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: myAutoSizedText(
                    appLocale.introductionFormSecondPageMainTitle(gender),
                    TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                    null,
                    60,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                  child: myAutoSizedText(
                    appLocale.introductionFormSecondPageSubTitle(gender),
                    TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                    ),
                    TextAlign.center,
                    40,
                  ),
                ),
                SizedBox(height: returnSizedBox(context, 25)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    resizeText(appLocale.userSettingsName(gender)),
                    Container(
                      width: 300,
                      child: Container(
                        height: 35,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 6.0),
                          ),
                          onChanged: (text) {
                            // Do something with the text
                            name = text;
                          },
                          textAlignVertical: TextAlignVertical.center,
                        ),
                      ),
                    ),
                    myAutoSizedText(
                      appLocale.userSettingsAge(gender),
                      TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                      null,
                      24,
                    ),
                    //ages drop down select:
                    Container(
                      width: 300,
                      child: DropdownMenu<String>(
                        width: 300,
                        initialSelection: userInfoProvider.age,
                        dropdownMenuEntries: [
                          ...ages.map(
                            (age) => buildDropdownMenuEntry(
                              age,
                              dropdownValueAge == age
                                  ? Color.fromARGB(255, 68, 0, 255)
                                  : Colors.black,
                            ),
                          ),
                        ],
                        onSelected: (String? newValue) {
                          setState(() {
                            if (newValue != null) {
                              dropdownValueAge = newValue;
                              userInfoProvider.updateAge(newValue);
                            }
                          });
                          // Do something with the selected value
                        },
                      ),
                    ),

                    myAutoSizedText(
                      appLocale.userSettingsGender(gender),
                      TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                      null,
                      24,
                    ),
                    //gender drop down select
                    Container(
                      width: 300,
                      child: DropdownMenu<String>(
                        width: 300,
                        initialSelection: (userInfoProvider.binary)
                            ? appLocale.nonBinary
                            : (userInfoProvider.gender == 'male'
                                  ? appLocale.male
                                  : userInfoProvider.gender == 'female'
                                  ? appLocale.female
                                  : appLocale.notWillingToSay),
                        dropdownMenuEntries: [
                          ...genders.map(
                            (gender) => buildDropdownMenuEntry(
                              gender,
                              dropdownValueGender == gender
                                  ? Color.fromARGB(255, 68, 0, 255)
                                  : Colors.black,
                            ),
                          ),
                        ],
                        //update user info accordingly:
                        onSelected: (String? newValue) {
                          setState(() {
                            if (newValue != null) {
                              dropdownValueGender = newValue;
                              if (newValue == appLocale.male) {
                                userInfoProvider.updateGender('male');
                                userInfoProvider.updateBinary(false);
                              } else if (newValue == appLocale.female) {
                                userInfoProvider.updateGender('female');
                                userInfoProvider.updateBinary(false);
                              } else if (newValue == appLocale.nonBinary) {
                                userInfoProvider.updateGender('');
                                userInfoProvider.updateBinary(true);
                              } else {
                                userInfoProvider.updateGender('');
                                userInfoProvider.updateBinary(false);
                              }
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
                  ],
                ),
                SizedBox(height: returnSizedBox(context, 100)),
                ConfirmationButton(
                  context,
                  () {
                    FocusScope.of(context).unfocus();

                    userInfoProvider.updateAge(dropdownValueAge ?? '');
                    userInfoProvider.updateName(name!);
                    userInfoProvider.updateBinary(
                      dropdownValueGender == appLocale.nonBinary,
                    );

                    if (dropdownValueGender != null) {
                      if (dropdownValueGender == appLocale.male) {
                        userInfoProvider.updateGender('male');
                      } else if (dropdownValueGender == appLocale.female) {
                        userInfoProvider.updateGender('female');
                      } else {
                        userInfoProvider.updateGender('');
                      }
                    }
                    widget.next();
                  },
                  appLocale.nextButton(gender),
                  myTextStyle.copyWith(fontSize: 20.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
