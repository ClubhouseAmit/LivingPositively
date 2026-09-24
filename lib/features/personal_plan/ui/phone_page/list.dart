import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/design_system/widgets/card.dart';
import 'package:mazilon/features/phone/ui/emergency_numbers.dart';
import 'package:mazilon/features/speech_dictation/ui/suffix_action.dart';
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/phone/ui/phoneTextAndIcon.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/features/personal_plan/ui/phone_page/spoken_phone_number_normalizer.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

part 'editing_row.dart';
part 'list_sync.dart';

const double _countryPickerWidth = 112;

class PhonePageList extends StatefulWidget {
  final PhonePageData phonePageData;
  @override
  _PhonePageListState createState() => _PhonePageListState();
  const PhonePageList({super.key, required this.phonePageData});
}

class _PhonePageListState extends LPExtendedState<PhonePageList>
    with _PhonePageListSync {
  @override
  void initState() {
    super.initState();
    final phonePageData = Provider.of<PhonePageData>(context, listen: false);
    final userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    _syncControllers(phonePageData, _profileCountryCode(userInformation));
  }

  @override
  void dispose() {
    for (final controller in nameControllers) {
      controller.dispose();
    }
    for (final controller in numberControllers) {
      controller.dispose();
    }
    _draftNameController?.dispose();
    _draftNumberController?.dispose();
    super.dispose();
  }

  void _startDraft(String countryCode) {
    if (_draftNameController != null || _draftNumberController != null) {
      return;
    }
    setState(() {
      editingIndex = -1;
      _draftNameController = TextEditingController();
      _draftNumberController = TextEditingController();
      _draftCountryCode = countryCode;
    });
  }

  void _cancelDraft() {
    setState(() {
      _draftNameController?.dispose();
      _draftNumberController?.dispose();
      _draftNameController = null;
      _draftNumberController = null;
      _draftCountryCode = null;
    });
  }

  void _cancelExistingEdit(
    PhonePageData phonePageData,
    int index,
    String fallbackCountryCode,
  ) {
    setState(() {
      if (index < _entryCount(phonePageData)) {
        final countryCode = _countryCodeForStoredNumber(
          _numberAt(phonePageData, index),
          fallbackCountryCode,
        );
        _countryCodesByEntry[index] = countryCode;
        nameControllers[index].text = _nameAt(phonePageData, index);
        numberControllers[index].text = _numberForEditing(
          _numberAt(phonePageData, index),
          countryCode,
        );
      }
      editingIndex = -1;
    });
  }

  void _saveDraft(PhonePageData phonePageData) {
    if (!_draftFormKey.currentState!.validate()) {
      return;
    }
    final canonicalNumber = PhonePageData.canonicalizePhoneNumber(
      _draftNumberController!.text,
      _dialCodeFor(
        _draftCountryCode ?? defaultPickerCountry.countryCodes.first,
      ),
    );
    if (canonicalNumber == null) {
      return;
    }
    if (phonePageData.addItem(_draftNameController!.text, canonicalNumber)) {
      _cancelDraft();
    }
  }

  void _saveExisting(PhonePageData phonePageData, int index) {
    if (!_formKeys[index]!.currentState!.validate()) {
      return;
    }
    final canonicalNumber = PhonePageData.canonicalizePhoneNumber(
      numberControllers[index].text,
      _dialCodeFor(
        _countryCodesByEntry[index] ?? defaultPickerCountry.countryCodes.first,
      ),
    );
    if (canonicalNumber == null) {
      return;
    }
    phonePageData.replaceItem(
      index,
      nameControllers[index].text,
      canonicalNumber,
    );
    setState(() {
      editingIndex = -1;
    });
  }

  Future<void> _confirmDelete(PhonePageData phonePageData, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appLocale.confirmDeleteContactTitle),
        content: Text(appLocale.confirmDeleteContactMessage),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              appLocale.closeButton(
                Provider.of<UserInformation>(context, listen: false).gender,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              appLocale.deleteButton(
                Provider.of<UserInformation>(context, listen: false).gender,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    if (!mounted) {
      return;
    }
    phonePageData.removeItemAt(index);
    setState(() {
      editingIndex = -1;
      _formKeys.clear();
      if (index < nameControllers.length) {
        nameControllers.removeAt(index).dispose();
        numberControllers.removeAt(index).dispose();
      }
    });
  }

  Widget _displayRow(
    PhonePageData phonePageData,
    int index,
    String gender,
    String fallbackCountryCode,
  ) {
    final name = phonePageData.savedPhoneNames[index];
    final number = phonePageData.savedPhoneNumbers[index];
    final canonicalNumber = PhonePageData.canonicalizePhoneNumber(
      number,
      _dialCodeFor(_countryCodeForStoredNumber(number, fallbackCountryCode)),
    );
    return Padding(
      padding: EdgeInsets.all(
        returnSizedBox(context, AppSpacing.sm.toInt()),
      ),
      child: Row(
        children: [
          circularActionButton(
            context,
            tooltip: appLocale.callContactTooltip(name),
            icon: Icons.phone,
            diameter: returnSizedBox(context, 20) * 2,
            iconSize: returnSizedBox(context, 24),
            onTap: () {
              launchWithFeedback(
                context,
                canonicalNumber ?? number,
                isCallFailure: true,
                launch: canonicalNumber == null
                    ? () async => false
                    : () => dialPhone(canonicalNumber),
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Card(
              padding: EdgeInsets.all(
                returnSizedBox(context, AppSpacing.md.toInt()),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: appLocale.contactEditTooltip,
            icon: Icon(Icons.edit, size: returnSizedBox(context, 32)),
            onPressed: () {
              setState(() {
                editingIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _editingRow({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController numberController,
    required String countryCode,
    required String countryPickerKey,
    required String gender,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required ValueChanged<String> onCountryChanged,
    VoidCallback? onDelete,
  }) {
    return _PhoneEditingRow(
      formKey: formKey,
      nameController: nameController,
      numberController: numberController,
      countryCode: countryCode,
      countryPickerKey: countryPickerKey,
      nameLabel: appLocale.phonesPageName(gender),
      phoneLabel: appLocale.phonesPagePhone(gender),
      countryCodeHint: appLocale.contactPhoneCountryCodeHint,
      saveTooltip: appLocale.contactSaveTooltip,
      cancelTooltip: appLocale.contactCancelTooltip,
      deleteTooltip: appLocale.contactDeleteTooltip,
      validateName: _validateName,
      validateNumber: (value) => _validateNumber(value, countryCode),
      dialCode: _dialCodeFor(countryCode),
      onSave: onSave,
      onCancel: onCancel,
      onCountryChanged: onCountryChanged,
      onDelete: onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    final phonePageData = Provider.of<PhonePageData>(context);
    final gender = userInfoProvider.gender;
    final profileCountryCode = _profileCountryCode(userInfoProvider);
    _syncControllers(phonePageData, profileCountryCode);
    final contactCount = _contactCount(phonePageData);
    final entryCount = _entryCount(phonePageData);
    return Column(
      children: [
        ...List.generate(entryCount, (index) {
          if (index == editingIndex || index >= contactCount) {
            return _editingRow(
              formKey: _formKeys.putIfAbsent(
                index,
                () => GlobalKey<FormState>(),
              ),
              nameController: nameControllers[index],
              numberController: numberControllers[index],
              countryCode: _countryCodesByEntry[index] ?? profileCountryCode,
              countryPickerKey: 'contact-country-code-picker-$index',
              gender: gender,
              onSave: () => _saveExisting(phonePageData, index),
              onCancel: () =>
                  _cancelExistingEdit(phonePageData, index, profileCountryCode),
              onCountryChanged: (countryCode) {
                setState(() {
                  _countryCodesByEntry[index] = countryCode;
                });
              },
              onDelete: index < contactCount
                  ? () => _confirmDelete(phonePageData, index)
                  : null,
            );
          }
          return _displayRow(phonePageData, index, gender, profileCountryCode);
        }),
        if (_draftNameController != null && _draftNumberController != null)
          _editingRow(
            formKey: _draftFormKey,
            nameController: _draftNameController!,
            numberController: _draftNumberController!,
            countryCode: _draftCountryCode ?? profileCountryCode,
            countryPickerKey: 'contact-country-code-picker-draft',
            gender: gender,
            onSave: () => _saveDraft(phonePageData),
            onCancel: _cancelDraft,
            onCountryChanged: (countryCode) {
              setState(() {
                _draftCountryCode = countryCode;
              });
            },
          ),
        if (entryCount == contactCount) ...[
          const SizedBox(width: AppSpacing.md),
          _manualAddButton(gender, profileCountryCode),
        ],
      ],
    );
  }

  Widget _manualAddButton(String gender, String profileCountryCode) {
    return InkWell(
      key: const Key('phone-manual-add'),
      onTap: () => _startDraft(profileCountryCode),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            appLocale.phonesPageManualTitle(gender),
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
