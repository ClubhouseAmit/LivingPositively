
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';

class PhonePageData extends ChangeNotifier {

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

  bool _hasDialablePhoneNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s().-]'), '');
    return RegExp(r'^\+?\d{2,}$').hasMatch(normalized);
  }

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
    if (index < savedPhoneNames.length && index < savedPhoneNumbers.length) {
      savedPhoneNames[index] = newPhoneName.trim();
      savedPhoneNumbers[index] = newPhoneNumber.trim();
      saveItemsToPrefs();
      notifyListeners();
    }
  }

  Future<void> loadItemsFromPrefs() async {
    final service =
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
    if (!_isValidContact(phoneName, phoneNumber)) {
      return false;
    }
    savedPhoneNames.add(phoneName.trim());
    savedPhoneNumbers.add(phoneNumber.trim());
    saveItemsToPrefs();
    notifyListeners();
    return true;
  }

  void removeItemAt(int index) {
    if (index < savedPhoneNames.length && index < savedPhoneNumbers.length) {
      savedPhoneNames.removeAt(index);
      savedPhoneNumbers.removeAt(index);
      saveItemsToPrefs();
      notifyListeners();
    }
  }

  void removeItem(String phoneName, String phoneNumber) {
    savedPhoneNames.remove(phoneName);
    savedPhoneNumbers.remove(phoneNumber);
    saveItemsToPrefs();
    notifyListeners();
  }

  Future<void> saveItemsToPrefs() async {
    final service =
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
