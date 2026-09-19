import 'dart:math' show min;

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/features/phone/ui/emergency_numbers.dart';
import 'package:mazilon/features/personal_plan/ui/phone_page/list.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide PermissionStatus;

const double _importRadius = 12;
const double _importPad = 6;
const double _disclaimerHPad = 24;
const double _disclaimerBottom = 8;

class PhonePageForm extends WizardStep {
  final Function next;
  final Function prev;

  final PhonePageData phonePageData;
  const PhonePageForm({
    required super.key,
    required this.next,
    required this.prev,
    required this.phonePageData,
  });

  @override
  String primaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.nextButton(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<PhonePageForm> createState() => _PhonePageFormState();
}

class _PhonePageFormState extends WizardStepState<PhonePageForm> {
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> numberControllers = [];
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  bool isEditingNew = false;
  int editingIndex = -1;

  //add contact to the list from the contact list in the phone
  void addItem(Contact contact) {
    //  debugPrint(contact.phones);
    String? phoneName = contact.displayName;
    String? phoneNumber = contact.phones.isNotEmpty == true
        ? contact.phones[0].number
        : null;
    if (phoneName != null && phoneNumber != null) {
      if (widget.phonePageData.savedPhoneNames.length !=
          widget.phonePageData.savedPhoneNumbers.length) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(appLocale.sosDeliveryContactsNeedAttention)),
        );
        return;
      }
      final profileCountryCode = Provider.of<UserInformation>(
        context,
        listen: false,
      ).location.trim().toUpperCase();
      final countryCode = countryPickerCodes.contains(profileCountryCode)
          ? profileCountryCode
          : defaultPickerCountry.countryCodes.first;
      final dialCode = CountryCode.tryFromCountryCode(countryCode)?.dialCode;
      final canonicalNumber = PhonePageData.canonicalizePhoneNumber(
        phoneNumber,
        dialCode,
      );
      final added =
          canonicalNumber != null &&
          widget.phonePageData.addItem(phoneName, canonicalNumber);
      if (!added) {
        final message = phoneName.trim().isEmpty
            ? appLocale.contactNameRequiredError
            : appLocale.contactPhoneInvalidError;
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      editingIndex =
          widget.phonePageData.savedPhoneNames.length -
          1; // Set editingIndex to the index of the new contact
      nameControllers.add(TextEditingController(text: phoneName));
      numberControllers.add(TextEditingController(text: canonicalNumber));
    } else {
      debugPrint("Both fields must be filled");
    }
  }

  Future<void> pickContact() async {
    final hasPermission = await FlutterContacts.permissions.has(
      PermissionType.read,
    );
    if (!mounted) {
      return;
    }
    if (hasPermission) {
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone, ContactProperty.name},
      );
      if (!mounted) {
        return;
      }
      if (contact != null) {
        addItem(contact);
      }
      if (!mounted) {
        return;
      }
      setState(() {});
    } else {
      await FlutterContacts.permissions.request(PermissionType.read);
    }
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in numberControllers) {
      controller.dispose();
    }
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final contactCount = min(
      widget.phonePageData.savedPhoneNames.length,
      widget.phonePageData.savedPhoneNumbers.length,
    );
    for (int i = 0; i < contactCount; i++) {
      nameControllers.add(
        TextEditingController(text: widget.phonePageData.savedPhoneNames[i]),
      );
      numberControllers.add(
        TextEditingController(text: widget.phonePageData.savedPhoneNumbers[i]),
      );
    }
  }

  @override
  Future<void> onPrimaryAction() async {
    await widget.phonePageData.loadItemsFromPrefs();
    await widget.phonePageData.saveItemsToPrefs();
    widget.phonePageData.update();
    widget.next();
  }

  @override
  Widget build(BuildContext context) {
    final gender = Provider.of<UserInformation>(context, listen: true).gender;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            appLocale.phonesPageHeader(gender),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: OnboardingGaps.labelToField.h),
          _PhoneImportButton(
            label: appLocale.phonesPageContactImportTitle(gender),
            onTap: pickContact,
          ),
          SizedBox(height: returnSizedBox(context, 10)),
          PhonePageList(phonePageData: widget.phonePageData),
          SizedBox(height: returnSizedBox(context, 10)),
          _PhoneContactDisclaimer(appLocale: appLocale),
        ],
      ),
    );
  }
}

class _PhoneImportButton extends StatelessWidget {
  const _PhoneImportButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(_importRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_importPad),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PhoneContactDisclaimer extends StatelessWidget {
  const _PhoneContactDisclaimer({required this.appLocale});

  final AppLocalizations appLocale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _disclaimerHPad,
        vertical: OnboardingGaps.labelToField,
      ),
      child: ExpansionTile(
        leading: Tooltip(
          message: appLocale.phoneContactDisclaimerMoreTooltip,
          child: Icon(
            Icons.info_outline,
            size: 20.sp,
            semanticLabel: appLocale.phoneContactDisclaimerMoreTooltip,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: _disclaimerBottom),
        title: myAutoSizedText(
          appLocale.phoneContactDisclaimerSummary,
          TextStyle(fontSize: 12.sp, height: 1.4),
          TextAlign.start,
          20,
          2,
        ),
        children: [
          Text(
            appLocale.addingContactDisclaimer,
            style: TextStyle(fontSize: 12.sp, height: 1.5),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
