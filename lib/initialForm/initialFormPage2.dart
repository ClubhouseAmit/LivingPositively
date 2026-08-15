// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';
import 'package:mazilon/l10n/app_localizations.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//second page of the initial form
//this is where the user selects their age,name and gender
class InitialFormPage2 extends WizardStep {
  final Function next;
  final Function prev;
  final Function updateName;

  const InitialFormPage2({
    required super.key,
    required this.next,
    required this.prev,
    required this.updateName,
  });

  @override
  String primaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.nextButton(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<InitialFormPage2> createState() => _InitialFormPage2State();
}

class _InitialFormPage2State extends WizardStepState<InitialFormPage2> {
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

  /// Field label — Figma specifies a single 14px/SemiBold line box per field
  /// (nodes 1660:2288 / 2294 / 2300), start-aligned so it mirrors under RTL.
  ///
  /// The name label used to be split on "(" and rendered at two different
  /// sizes; the design has one uniform label, so the split is gone.
  Widget _formLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: kFormFieldLabelSize.sp,
        height: kFormFieldLabelHeight,
        fontWeight: AppFontWeight.semiBold,
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'Rubix',
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
    );
  }

  /// One label + field pair — Figma Groups 143/141/142 on frame 28. The
  /// groups carry no auto-layout, so the gap comes from the shared onboarding
  /// scale rather than from a per-screen measurement.
  Widget _fieldGroup({required Widget label, required Widget field}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // Stretch, not start: the design's fields span the full 330 of the
      // content column, the same width as the primary button below them.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: OnboardingGaps.labelToField,
      children: [label, field],
    );
  }

  @override
  Future<void> onPrimaryAction() async {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final trimmedName = _nameController.text.trim();

    userInfoProvider.updateAge(dropdownValueAge ?? '');
    userInfoProvider.updateName(trimmedName);
    widget.updateName(trimmedName);
    userInfoProvider.updateBinary(dropdownValueGender == appLocale.nonBinary);

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
    // Frame 28 shows the age field pre-filled with "18-30"; a user who has not
    // picked yet should see that default rather than an empty control.
    dropdownValueAge = userInfoProvider.age.isEmpty
        ? ages[1]
        : userInfoProvider.age;
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
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 8.h),
        // topCenter, not Center: all three frames put the title block at y 104,
        // and centring the column vertically dropped this screen's title well
        // below the other two whenever the form was shorter than the viewport.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            // Tight width inside the cap: `Center` hands the column loose
            // constraints, under which `stretch` resolves to the widest text
            // rather than the full column, leaving the fields narrower than
            // the button below them.
            child: SizedBox(
              width: double.infinity,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: OnboardingGaps.betweenBlocks,
                  children: [
                    // Title block — Figma Frame 205 (1660:2844): VERTICAL,
                    // itemSpacing 16, narrower than the content column so the
                    // copy wraps as designed.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: OnboardingSizes.titleBlockWidth.w,
                      ),
                      child: Column(
                        key: const Key('intro-title-block'),
                        mainAxisSize: MainAxisSize.min,
                        spacing: OnboardingGaps.withinBlock,
                        children: [
                          myText(
                            appLocale.introductionFormSecondPageMainTitle(
                              gender,
                            ),
                            TextStyle(
                              fontSize: 26.sp,
                              height: 1.3,
                              fontWeight: AppFontWeight.medium,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            TextAlign.center,
                          ),
                          myText(
                            appLocale.introductionFormSecondPageSubTitle(
                              gender,
                            ),
                            TextStyle(
                              fontSize: 16.sp,
                              height: 1.125,
                              fontWeight: AppFontWeight.regular,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Fields block — Groups 143/141/142 sit 16 apart, each 330
                    // wide (the full content column) like the button below.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: OnboardingGaps.withinBlock,
                      children: [
                        _fieldGroup(
                          label: _formLabel(appLocale.userSettingsName(gender)),
                          field: Container(
                            decoration: formFieldShadowDecoration(),
                            child: TextFormField(
                              controller: _nameController,
                              decoration: formFieldInputDecoration(context),
                              validator: (text) {
                                if ((text ?? '').trim().isEmpty) {
                                  return appLocale.nameRequiredError;
                                }
                                return null;
                              },
                              textAlignVertical: TextAlignVertical.center,
                            ),
                          ),
                        ),
                        _fieldGroup(
                          label: _formLabel(appLocale.userSettingsAge(gender)),
                          //ages drop down select:
                          field: Container(
                            decoration: formFieldShadowDecoration(),
                            child: DropdownMenu<String>(
                              // Fills the group's width instead of sizing to the
                              // widest entry, so it matches the other fields.
                              expandedInsets: EdgeInsets.zero,
                              inputDecorationTheme:
                                  formFieldInputDecorationTheme(context),
                              initialSelection: dropdownValueAge,
                              dropdownMenuEntries: [
                                ...ages.map(
                                  (age) => buildDropdownMenuEntry(
                                    age,
                                    dropdownValueAge == age
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                        ),
                        _fieldGroup(
                          label: _formLabel(
                            appLocale.userSettingsGender(gender),
                          ),
                          //gender drop down select
                          field: Container(
                            decoration: formFieldShadowDecoration(),
                            child: DropdownMenu<String>(
                              // Fills the group's width instead of sizing to the
                              // widest entry, so it matches the other fields.
                              expandedInsets: EdgeInsets.zero,
                              inputDecorationTheme:
                                  formFieldInputDecorationTheme(context),
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
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                                    } else if (newValue ==
                                        appLocale.nonBinary) {
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
                        ),
                        CountrySelectorWidget(
                          text: appLocale.locationSelect(gender),
                          disclaimerText: appLocale.locationDisclaimer(gender),
                        ),
                      ],
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
