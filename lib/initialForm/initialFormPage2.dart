
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//second page of the initial form
//this is where the user selects their age,name and gender
class InitialFormPage2 extends StatefulWidget {

  const InitialFormPage2({
    required this.next, required this.prev, required this.updateName, super.key,
  });
  final Function next;
  final Function prev;
  final Function updateName;
  @override
  State<InitialFormPage2> createState() => _InitialFormPage2State();
}

class _InitialFormPage2State extends LPExtendedState<InitialFormPage2> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? dropdownValueAge = '18-30';
  String? dropdownValueGender = '';
  List<String> ages = ['18-', '18-30', '30-40', '40-55', '55+'];
  List<String> genders = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget resizeText(String text) {
    final sep = text.split('(');

    sep[1] = '(${sep[1]}';
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sep[0],
            style: Theme.of(context).textTheme.titleLarge,
            
            maxLines: 2,
          ),
          Text(
            sep[1],
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        
      ),
    );
  }

  Widget _primaryActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
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
    final gender = userInfoProvider.gender;
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24.h),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                    Semantics(
                      header: true,
                      child: AutoSizeText(
                        appLocale.introductionFormSecondPageMainTitle(gender),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              height: 1.15,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    AutoSizeText(
                      appLocale.introductionFormSecondPageSubTitle(gender),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            height: 1.25,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                    SizedBox(height: 16.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        resizeText(
                          appLocale.userSettingsName(gender),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: TextFormField(
                            controller: _nameController,
                            validator: (text) {
                              if ((text ?? '').trim().isEmpty) {
                                return appLocale.nameRequiredError;
                              }
                              return null;
                            },
                            textAlignVertical: TextAlignVertical.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _formLabel(
                          appLocale.userSettingsAge(gender),
                        ),
                        const SizedBox(height: 6),
                        //ages drop down select:
                        SizedBox(
                          width: double.infinity,
                          child: DropdownMenu<String>(
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            width: double.infinity,
                            initialSelection: userInfoProvider.age,
                            dropdownMenuEntries: [
                              ...ages.map(
                                (age) => buildDropdownMenuEntry(
                                  age,
                                  dropdownValueAge == age
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                            onSelected: (newValue) {
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
                        ),
                        const SizedBox(height: 6),
                        //gender drop down select
                        SizedBox(
                          width: double.infinity,
                          child: DropdownMenu<String>(
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            width: double.infinity,
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
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                            //update user info accordingly:
                            onSelected: (newValue) {
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
                      text: appLocale.nextButton(gender),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final trimmedName = _nameController.text.trim();

                        userInfoProvider.updateAge(dropdownValueAge ?? '');
                        userInfoProvider.updateName(trimmedName);
                        widget.updateName(trimmedName);
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
