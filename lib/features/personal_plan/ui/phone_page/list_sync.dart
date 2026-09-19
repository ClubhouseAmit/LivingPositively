part of 'list.dart';

mixin _PhonePageListSync on LPExtendedState<PhonePageList> {
  int editingIndex = -1;
  final Map<int, GlobalKey<FormState>> _formKeys = {};
  final GlobalKey<FormState> _draftFormKey = GlobalKey<FormState>();
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> numberControllers = [];
  final Map<int, String> _countryCodesByEntry = {};
  TextEditingController? _draftNameController;
  TextEditingController? _draftNumberController;
  String? _draftCountryCode;

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
}
