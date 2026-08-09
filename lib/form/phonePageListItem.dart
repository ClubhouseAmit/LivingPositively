import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class PhonePageList extends StatefulWidget {
  final PhonePageData phonePageData;
  @override
  _PhonePageListState createState() => _PhonePageListState();
  const PhonePageList({super.key, required this.phonePageData});
}

class _PhonePageListState extends LPExtendedState<PhonePageList> {
  int editingIndex = -1;
  final Map<int, GlobalKey<FormState>> _formKeys = {};
  final GlobalKey<FormState> _draftFormKey = GlobalKey<FormState>();
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> numberControllers = [];
  final Map<int, String> _countryCodesByEntry = {};
  TextEditingController? _draftNameController;
  TextEditingController? _draftNumberController;
  String? _draftCountryCode;

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

  int _contactCount(PhonePageData phonePageData) {
    return phonePageData.savedPhoneNames.length <
            phonePageData.savedPhoneNumbers.length
        ? phonePageData.savedPhoneNames.length
        : phonePageData.savedPhoneNumbers.length;
  }

  int _entryCount(PhonePageData phonePageData) {
    final contactCount = _contactCount(phonePageData);
    return phonePageData.savedPhoneNames.length ==
            phonePageData.savedPhoneNumbers.length
        ? contactCount
        : contactCount + 1;
  }

  String _nameAt(PhonePageData phonePageData, int index) {
    return index < phonePageData.savedPhoneNames.length
        ? phonePageData.savedPhoneNames[index]
        : '';
  }

  String _numberAt(PhonePageData phonePageData, int index) {
    return index < phonePageData.savedPhoneNumbers.length
        ? phonePageData.savedPhoneNumbers[index]
        : '';
  }

  String _profileCountryCode(UserInformation userInformation) {
    final profileCountryCode = userInformation.location.trim().toUpperCase();
    if (countryPickerCodes.contains(profileCountryCode)) {
      return profileCountryCode;
    }
    return defaultPickerCountry.countryCodes.first;
  }

  String? _dialCodeFor(String countryCode) {
    return CountryCode.tryFromCountryCode(countryCode)?.dialCode;
  }

  String _countryCodeForStoredNumber(
    String number,
    String fallbackCountryCode,
  ) {
    final normalized = PhonePageData.normalizeDialablePhoneNumber(number);
    if (normalized == null || !normalized.startsWith('+')) {
      return fallbackCountryCode;
    }

    final matchingCodes =
        countryPickerCodes.where((countryCode) {
          final dialCode = _dialCodeFor(countryCode);
          return dialCode != null && normalized.startsWith(dialCode);
        }).toList()..sort(
          (left, right) => (_dialCodeFor(right)?.length ?? 0).compareTo(
            _dialCodeFor(left)?.length ?? 0,
          ),
        );
    return matchingCodes.isEmpty ? fallbackCountryCode : matchingCodes.first;
  }

  String _numberForEditing(String number, String countryCode) {
    final normalized = PhonePageData.normalizeDialablePhoneNumber(number);
    final dialCode = _dialCodeFor(countryCode);
    if (normalized != null &&
        normalized.startsWith('+') &&
        dialCode != null &&
        normalized.startsWith(dialCode)) {
      return normalized.substring(dialCode.length);
    }
    return number;
  }

  void _syncControllers(
    PhonePageData phonePageData,
    String fallbackCountryCode,
  ) {
    final count = _entryCount(phonePageData);
    final contactCount = _contactCount(phonePageData);
    while (nameControllers.length < count) {
      final index = nameControllers.length;
      final countryCode = _countryCodeForStoredNumber(
        _numberAt(phonePageData, index),
        fallbackCountryCode,
      );
      _countryCodesByEntry[index] = countryCode;
      nameControllers.add(
        TextEditingController(text: _nameAt(phonePageData, index)),
      );
      numberControllers.add(
        TextEditingController(
          text: _numberForEditing(_numberAt(phonePageData, index), countryCode),
        ),
      );
    }
    for (var index = 0; index < count; index++) {
      if (index == editingIndex || index >= contactCount) {
        continue;
      }
      final countryCode = _countryCodeForStoredNumber(
        _numberAt(phonePageData, index),
        fallbackCountryCode,
      );
      _countryCodesByEntry[index] = countryCode;
      if (nameControllers[index].text != _nameAt(phonePageData, index)) {
        nameControllers[index].text = _nameAt(phonePageData, index);
      }
      final editableNumber = _numberForEditing(
        _numberAt(phonePageData, index),
        countryCode,
      );
      if (numberControllers[index].text != editableNumber) {
        numberControllers[index].text = editableNumber;
      }
    }
    while (nameControllers.length > count) {
      nameControllers.removeLast().dispose();
      numberControllers.removeLast().dispose();
    }
    _formKeys.removeWhere((index, _) => index >= count);
    _countryCodesByEntry.removeWhere((index, _) => index >= count);
    if (editingIndex >= count) {
      editingIndex = -1;
    }
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return appLocale.contactNameRequiredError;
    }
    return null;
  }

  String? _validateNumber(String? value, String countryCode) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return appLocale.contactPhoneRequiredError;
    }
    if (PhonePageData.canonicalizePhoneNumber(
          trimmed,
          _dialCodeFor(countryCode),
        ) ==
        null) {
      return appLocale.contactPhoneInvalidError;
    }
    return null;
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              appLocale.closeButton(
                Provider.of<UserInformation>(context, listen: false).gender,
              ),
            ),
          ),
          TextButton(
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

  Widget _displayRow(PhonePageData phonePageData, int index, String gender) {
    final name = phonePageData.savedPhoneNames[index];
    final number = phonePageData.savedPhoneNumbers[index];
    return Padding(
      padding: EdgeInsets.all(returnSizedBox(context, 8)),
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
                number,
                isCallFailure: true,
                launch: () => dialPhone(number),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(returnSizedBox(context, 10)),
                child: myText(
                  name,
                  TextStyle(fontWeight: FontWeight.normal, fontSize: 14.sp),
                  null,
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
    return Padding(
      padding: EdgeInsets.all(returnSizedBox(context, 8)),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final nameField = TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: appLocale.phonesPageName(gender),
                  ),
                  validator: _validateName,
                );
                final numberField = Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: numberController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocale.phonesPagePhone(gender),
                    ),
                    validator: (value) => _validateNumber(value, countryCode),
                  ),
                );
                final phoneField = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: appLocale.contactPhoneCountryCodeHint,
                      child: SizedBox(
                        width: 112,
                        child: CountryCodePicker(
                          key: ValueKey(countryPickerKey),
                          initialSelection: countryCode,
                          countryFilter: countryPickerCodes,
                          showFlag: false,
                          showDropDownButton: true,
                          padding: EdgeInsets.zero,
                          onChanged: (selectedCountry) {
                            final selectedCode = selectedCountry.code;
                            if (selectedCode != null) {
                              onCountryChanged(selectedCode);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: numberField),
                  ],
                );
                final helper = Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4),
                  child: Text(
                    appLocale.contactPhoneCountryCodeHint,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      nameField,
                      const SizedBox(height: 8),
                      phoneField,
                      helper,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: nameField),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: phoneField),
                      ],
                    ),
                    helper,
                  ],
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: appLocale.contactSaveTooltip,
                  icon: Icon(Icons.check, size: returnSizedBox(context, 32)),
                  onPressed: onSave,
                ),
                IconButton(
                  tooltip: appLocale.contactCancelTooltip,
                  icon: Icon(Icons.close, size: returnSizedBox(context, 32)),
                  onPressed: onCancel,
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: appLocale.contactDeleteTooltip,
                    icon: Icon(Icons.delete, size: returnSizedBox(context, 32)),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
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
          return _displayRow(phonePageData, index, gender);
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
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => _startDraft(profileCountryCode),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(6),
            ),
            child: myText(
              appLocale.phonesPageManualTitle(gender),
              TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16.sp,
              ),
              TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
