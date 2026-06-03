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

  double _fieldWidth(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 48;
    if (availableWidth > 360) {
      return 360;
    }
    return availableWidth > 0
        ? availableWidth
        : MediaQuery.sizeOf(context).width;
  }

  Widget resizeText(String text, double fieldWidth) {
    List<String> sep = text.split("(");
    final appLocale = AppLocalizations.of(context);

    sep[1] = "(${sep[1]}";
    return SizedBox(
      width: fieldWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sep[0],
            style: const TextStyle(
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              fontFamily: 'Rubix',
            ),
            textAlign: appLocale!.textDirection == "rtl"
                ? TextAlign.right
                : TextAlign.left,
            maxLines: 2,
          ),
          Text(
            sep[1],
            style: const TextStyle(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              fontFamily: 'Rubix',
            ),
            textAlign: appLocale.textDirection == "rtl"
                ? TextAlign.right
                : TextAlign.left,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text, double fieldWidth) {
    return SizedBox(
      width: fieldWidth,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          height: 1.2,
          fontWeight: FontWeight.normal,
          color: Colors.black,
          fontFamily: 'Rubix',
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: appLocale.textDirection == "rtl"
            ? TextAlign.right
            : TextAlign.left,
      ),
    );
  }

  Widget _primaryActionButton({
    required double width,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        style: myButtonStyle,
        child: Text(
          text,
          style: myTextStyle.copyWith(fontSize: 20, fontFamily: 'Rubix'),
        ),
      ),
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
    final fieldWidth = _fieldWidth(context);
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
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24.h),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  myAutoSizedText(
                    appLocale.introductionFormSecondPageMainTitle(gender),
                    const TextStyle(
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                    ),
                    TextAlign.center,
                    30,
                    2,
                  ),
                  SizedBox(height: 8.h),
                  myAutoSizedText(
                    appLocale.introductionFormSecondPageSubTitle(gender),
                    const TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                    ),
                    TextAlign.center,
                    15,
                    3,
                  ),
                  SizedBox(height: 16.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      resizeText(
                        appLocale.userSettingsName(gender),
                        fieldWidth,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (text) {
                            // Do something with the text
                            name = text;
                          },
                          textAlignVertical: TextAlignVertical.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _formLabel(appLocale.userSettingsAge(gender), fieldWidth),
                      const SizedBox(height: 6),
                      //ages drop down select:
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownMenu<String>(
                          width: fieldWidth,
                          initialSelection: userInfoProvider.age,
                          dropdownMenuEntries: [
                            ...ages.map(
                              (age) => buildDropdownMenuEntry(
                                age,
                                dropdownValueAge == age
                                    ? primaryPurple
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
                      const SizedBox(height: 12),

                      _formLabel(
                        appLocale.userSettingsGender(gender),
                        fieldWidth,
                      ),
                      const SizedBox(height: 6),
                      //gender drop down select
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownMenu<String>(
                          width: fieldWidth,
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
                                    ? primaryPurple
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
                      const SizedBox(height: 12),
                      CountrySelectorWidget(
                        text: appLocale.locationSelect(gender),
                        disclaimerText: appLocale.locationDisclaimer(gender),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _primaryActionButton(
                    width: fieldWidth,
                    text: appLocale.nextButton(gender),
                    onPressed: () {
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
