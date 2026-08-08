// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';

class PhonePageData extends ChangeNotifier {
  final String key;
  String header; // Add this
  String subTitle; // Add this
  String midTitle;
  String phoneNameTitle;
  String phoneNumberTitle;
  List<String> phoneNames = [];
  List<String> phoneNumbers = [];
  List<String> savedPhoneNames = []; // New list
  List<String> savedPhoneNumbers = []; // New list
  List<String> phoneDescription = [];

  PhonePageData({
    required this.key,
    required this.phoneNames,
    required this.phoneNumbers,
    required this.header,
    required this.subTitle,
    required this.midTitle,
    required this.phoneNameTitle,
    required this.phoneNumberTitle,
    required this.savedPhoneNames,
    required this.savedPhoneNumbers,
    required this.phoneDescription,
  }) {
    loadItemsFromPrefs();
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'header': header,
      'subTitle': subTitle,
      'midTitle': midTitle,
      'phoneNameTitle': phoneNameTitle,
      'phoneNumberTitle': phoneNumberTitle,
      'phoneNames': phoneNames,
      'phoneNumbers': phoneNumbers,
      'savedPhoneNames': savedPhoneNames,
      'savedPhoneNumbers': savedPhoneNumbers,
      'phoneDescription': phoneDescription,
    };
  }

  //changes made on phone page CMS must be updated here
  factory PhonePageData.fromJson(Map<String, dynamic> json) {
    return PhonePageData(
      key: json['key'],
      header: json['header'],
      subTitle: json['subTitle'],
      midTitle: json['midTitle'],
      phoneNameTitle: json['phoneNameTitle'],
      phoneNumberTitle: json['phoneNumberTitle'],
      phoneNames: List<String>.from(json['phoneNames']),
      phoneNumbers: List<String>.from(json['phoneNumbers']),
      savedPhoneNames: List<String>.from(json['savedPhoneNames']),
      savedPhoneNumbers: List<String>.from(json['savedPhoneNumbers']),
      phoneDescription: List<String>.from(json['phoneDescription']),
    );
  }
  void updateFromJson(Map<String, dynamic> json) {
    header = json['header'] ?? header;
    subTitle = json['subTitle'] ?? subTitle;
    midTitle = json['midTitle'] ?? midTitle;
    phoneNameTitle = json['phoneNameTitle'] ?? phoneNameTitle;
    phoneNumberTitle = json['phoneNumberTitle'] ?? phoneNumberTitle;
    phoneNames = List<String>.from(json['phoneNames'] ?? phoneNames);
    phoneNumbers = List<String>.from(json['phoneNumbers'] ?? phoneNumbers);
    savedPhoneNames = List<String>.from(
      json['savedPhoneNames'] ?? savedPhoneNames,
    );
    savedPhoneNumbers = List<String>.from(
      json['savedPhoneNumbers'] ?? savedPhoneNumbers,
    );
    phoneDescription = List<String>.from(
      json['phoneDescription'] ?? phoneDescription,
    );

    // Notify listeners about the update
    notifyListeners();
  }

  void update() {
    notifyListeners();
  }

  static String? normalizeDialablePhoneNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s().-]'), '');
    if (!RegExp(r'^\+?\d{2,}$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  bool _hasDialablePhoneNumber(String value) =>
      normalizeDialablePhoneNumber(value) != null;

  bool _isValidContact(String phoneName, String phoneNumber) {
    return phoneName.trim().isNotEmpty &&
        phoneNumber.trim().isNotEmpty &&
        _hasDialablePhoneNumber(phoneNumber);
  }

  void reset() {
    savedPhoneNames = [];
    savedPhoneNumbers = [];
    saveItemsToPrefs();
    notifyListeners();
  }

  void replaceItem(int index, String newPhoneName, String newPhoneNumber) {
    if (!_isValidContact(newPhoneName, newPhoneNumber)) {
      return;
    }
    if (index < 0) {
      return;
    }

    if (index < savedPhoneNames.length && index < savedPhoneNumbers.length) {
      savedPhoneNames[index] = newPhoneName.trim();
      savedPhoneNumbers[index] = newPhoneNumber.trim();
    } else if (index == savedPhoneNumbers.length &&
        index < savedPhoneNames.length) {
      savedPhoneNames[index] = newPhoneName.trim();
      savedPhoneNumbers.add(newPhoneNumber.trim());
    } else if (index == savedPhoneNames.length &&
        index < savedPhoneNumbers.length) {
      savedPhoneNames.add(newPhoneName.trim());
      savedPhoneNumbers[index] = newPhoneNumber.trim();
    } else {
      return;
    }

    saveItemsToPrefs();
    notifyListeners();
  }

  Future<void> loadItemsFromPrefs() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    savedPhoneNames = TypeUtils.castToStringList(
      await service.getItem(
        '${key}SavedPhoneNames',
        PersistentMemoryType.StringList,
      ),
    );
    savedPhoneNumbers = TypeUtils.castToStringList(
      await service.getItem(
        '${key}SavedPhoneNumbers',
        PersistentMemoryType.StringList,
      ),
    );
    notifyListeners();
  }

  bool addItem(String phoneName, String phoneNumber) {
    if (savedPhoneNames.length != savedPhoneNumbers.length ||
        !_isValidContact(phoneName, phoneNumber)) {
      return false;
    }
    savedPhoneNames.add(phoneName.trim());
    savedPhoneNumbers.add(phoneNumber.trim());
    saveItemsToPrefs();
    notifyListeners();
    return true;
  }

  void removeItemAt(int index) {
    if (index >= 0 &&
        index < savedPhoneNames.length &&
        index < savedPhoneNumbers.length) {
      savedPhoneNames.removeAt(index);
      savedPhoneNumbers.removeAt(index);
      saveItemsToPrefs();
      notifyListeners();
    }
  }

  void removeItem(String phoneName, String phoneNumber) {
    final normalizedName = phoneName.trim();
    final normalizedNumber = phoneNumber.trim();
    final contactCount = savedPhoneNames.length < savedPhoneNumbers.length
        ? savedPhoneNames.length
        : savedPhoneNumbers.length;
    for (var index = 0; index < contactCount; index++) {
      if (savedPhoneNames[index].trim() == normalizedName &&
          savedPhoneNumbers[index].trim() == normalizedNumber) {
        removeItemAt(index);
        return;
      }
    }
  }

  Future<void> saveItemsToPrefs() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance
    await service.setItem(
      '${key}SavedPhoneNames',
      PersistentMemoryType.StringList,
      savedPhoneNames,
    );
    await service.setItem(
      '${key}SavedPhoneNumbers',
      PersistentMemoryType.StringList,
      savedPhoneNumbers,
    );
  }
}
