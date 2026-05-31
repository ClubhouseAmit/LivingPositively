import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

//this it the user's information class, with it we store and display it across the app
class UserInformation with ChangeNotifier {
  String localeName;
  String gender;
  String name;
  String age;
  String location;
  bool binary;
  bool disclaimerSigned;
  List<String> difficultEvents;
  List<String> positiveTraits;
  List<String> makeSafer;
  List<String> feelBetter;
  List<String> distractions;
  bool loggedIn;
  String userId;
  int notificationMinute;
  int notificationHour;
  Map<String, List<String>> thanks;
  PersistentMemoryService service; // Get the persistent memory service instance

  UserInformation({
    this.location = '',
    this.thanks = const <String, List<String>>{},
    this.positiveTraits = const [],
    this.localeName = '',
    this.notificationHour = 12,
    this.notificationMinute = 0,
    this.gender = '',
    this.name = '',
    this.age = '',
    this.binary = false,
    this.difficultEvents = const [],
    this.makeSafer = const [],
    this.feelBetter = const [],
    this.distractions = const [],
    this.disclaimerSigned = false,
    this.loggedIn = false,
    this.userId = '',
    PersistentMemoryService? service,
  }) : service = service ?? GetIt.instance<PersistentMemoryService>();

  void reset(String locale) {
    location = '';
    notificationHour = 12;
    notificationMinute = 0;
    gender = '';
    name = '';
    age = '';
    binary = false;
    disclaimerSigned = false;
    difficultEvents = [];
    makeSafer = [];
    feelBetter = [];
    distractions = [];
    loggedIn = false;
    userId = '';
    thanks = {};
    positiveTraits = [];
    localeName = locale;

    notifyListeners();
  }

  void updateGender(String text) {
    void saveGender(String value) async {
      await service.setItem('gender', PersistentMemoryType.String, value);
    }

    gender = text;
    saveGender(text);
    notifyListeners();
  }

  void updateName(String text) {
    void saveName(String value) async {
      await service.setItem('name', PersistentMemoryType.String, value);
    }

    name = text;
    saveName(text);
    notifyListeners();
  }

  void updateAge(String text) {
    void saveAge(String value) async {
      await service.setItem('age', PersistentMemoryType.String, value);
    }

    age = text;
    saveAge(text);
    notifyListeners();
  }

  void updateBinary(bool value) {
    void saveBinary(bool value) async {
      await service.setItem('binary', PersistentMemoryType.Bool, value);
    }

    binary = value;
    saveBinary(value);
    notifyListeners();
  }

  void updateDifficultEvents(List<String> value) {
    difficultEvents = value;
    notifyListeners();
  }

  void updateMakeSafer(List<String> value) {
    makeSafer = value;
    notifyListeners();
  }

  void updateFeelBetter(List<String> value) {
    feelBetter = value;
    notifyListeners();
  }

  void updateDistractions(List<String> value) {
    distractions = value;
    notifyListeners();
  }

  void updateDisclaimerSigned(bool value) {
    disclaimerSigned = value;
    notifyListeners();
  }

  void updateLoggedIn(bool value) {
    loggedIn = value;
    notifyListeners();
  }

  void updateUserId(String value) {
    userId = value;
    notifyListeners();
  }

  void updateNotificationHour(int value) {
    Future<void> saveNotificationHour(int hour) async {
      await service.setItem('notificationHour', PersistentMemoryType.Int, hour);
    }

    notificationHour = value;
    saveNotificationHour(value);
    notifyListeners();
  }

  void updateNotificationMinute(int value) {
    Future<void> saveNotificationMinute(int minute) async {
      await service.setItem(
        'notificationMinute',
        PersistentMemoryType.Int,
        minute,
      );
    }

    notificationMinute = value;
    saveNotificationMinute(value);
    notifyListeners();
  }

  void updateLocaleName(String value) {
    localeName = value;
    notifyListeners();
  }

  void updatePositiveTraits(List<String> value) {
    Future<void> savePositiveTraits(List<String> traits) async {
      await service.setItem(
        'positiveTraits',
        PersistentMemoryType.StringList,
        traits,
      );
    }

    positiveTraits = [...value];
    savePositiveTraits(value);
    notifyListeners();
  }

  void updateThanks(Map<String, List<String>> value) {
    Future<void> saveThanks(List<String> thanks, List<String> dates) async {
      await service.setItem(
        'thankYous',
        PersistentMemoryType.StringList,
        thanks,
      );
      await service.setItem('dates', PersistentMemoryType.StringList, dates);
    }

    thanks = {"thanks": value["thanks"] ?? [], "dates": value["dates"] ?? []};
    saveThanks(value["thanks"] ?? [], value["dates"] ?? []);
    notifyListeners();
  }

  void updateLocation(String value) {
    location = value;

    notifyListeners();
  }
}
