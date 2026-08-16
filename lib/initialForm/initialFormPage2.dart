import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// Second page of the initial form: user selects age, name and gender.
class InitialFormPage2 extends WizardStep {
  final VoidCallback next;
  final VoidCallback prev;
  final ValueChanged<String> updateName;

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

  static const List<String> ages = ['18-', '18-30', '30-40', '40-55', '55+'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserInformation>(context, listen: false);
    _nameController.text = user.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _selectedGender(UserInformation user, AppLocalizations l10n) {
    if (user.binary) return l10n.nonBinary;
    return switch (user.gender) {
      'male' => l10n.male,
      'female' => l10n.female,
      _ => l10n.notWillingToSay,
    };
  }

  void _updateGender(
    String? label,
    UserInformation user,
    AppLocalizations l10n,
  ) {
    if (label == null) return;
    if (label == l10n.male) {
      user.updateGender('male');
      user.updateBinary(false);
    } else if (label == l10n.female) {
      user.updateGender('female');
      user.updateBinary(false);
    } else if (label == l10n.nonBinary) {
      user.updateGender('');
      user.updateBinary(true);
    } else {
      user.updateGender('');
      user.updateBinary(false);
    }
  }

  /// Field label (Figma nodes 1660:2288 / 2294 / 2300).
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

  /// Label + field group (Figma Groups 143/141/142 on frame 28).
  Widget _fieldGroup({required Widget label, required Widget field}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
    if (userInfoProvider.age.isEmpty) {
      userInfoProvider.updateAge(ages[1]);
    }
    userInfoProvider.updateName(trimmedName);
    widget.updateName(trimmedName);
    widget.next();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    final gender = userInfoProvider.gender;

    final genders = [
      appLocale.male,
      appLocale.female,
      appLocale.nonBinary,
      appLocale.notWillingToSay,
    ];

    final selectedAge = userInfoProvider.age.isEmpty
        ? ages[1]
        : userInfoProvider.age;

    final selectedGender = _selectedGender(userInfoProvider, appLocale);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: OnboardingGaps.betweenBlocks,
            children: [
              Column(
                key: const Key('intro-title-block'),
                mainAxisSize: MainAxisSize.min,
                spacing: OnboardingGaps.withinBlock,
                children: [
                  Text(
                    appLocale.introductionFormSecondPageMainTitle(gender),
                    style: TextStyle(
                      fontSize: 26.sp,
                      height: 1.3,
                      fontWeight: AppFontWeight.medium,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    appLocale.introductionFormSecondPageSubTitle(gender),
                    style: TextStyle(
                      fontSize: 16.sp,
                      height: 1.125,
                      fontWeight: AppFontWeight.regular,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              // Fields block — Groups 143/141/142.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: OnboardingGaps.withinBlock,
                children: [
                  _fieldGroup(
                    label: _formLabel(appLocale.userSettingsName(gender)),
                    field: DecoratedBox(
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
                    field: DecoratedBox(
                      decoration: formFieldShadowDecoration(),
                      child: DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme:
                            formFieldInputDecorationTheme(context),
                        initialSelection: selectedAge,
                        dropdownMenuEntries: [
                          for (final age in ages)
                            buildDropdownMenuEntry(
                              age,
                              selectedAge == age
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                        ],
                        onSelected: (String? newValue) {
                          if (newValue != null) {
                            userInfoProvider.updateAge(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  _fieldGroup(
                    label: _formLabel(
                      appLocale.userSettingsGender(gender),
                    ),
                    field: DecoratedBox(
                      decoration: formFieldShadowDecoration(),
                      child: DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme:
                            formFieldInputDecorationTheme(context),
                        initialSelection: selectedGender,
                        dropdownMenuEntries: [
                          for (final g in genders)
                            buildDropdownMenuEntry(
                              g,
                              selectedGender == g
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                        ],
                        onSelected: (String? newValue) => _updateGender(
                          newValue,
                          userInfoProvider,
                          appLocale,
                        ),
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
    );
  }
}
