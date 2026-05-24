// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Writes a minimal valid JSON blob for [loadAppInfoFromJson] to parse.
/// [appVersion] inside the file must match the version stored in Firestore
/// VersionManager for the function to return true.
Map<String, dynamic> _buildValidJson(String appVersion) => {
      'appVersion': appVersion,
      'reminderMainTitle': 'RMT',
      'reminderSubTitle': 'RST',
      'homeTitleGreeting': 'HTG',
      'personalPlanMainTitle': {'a': 'b'},
      'personalPlanSubTitle': {'c': 'd'},
      'traitMainTitle': {'e': 'f'},
      'traitSubTitle': {'g': 'h'},
      'journalMainTitle': {'i': 'j'},
      'othersuggestions': {'os': 'v'},
      'journalSubTitle': {'k': 'l'},
      'journalPopUpText': {'m': 'n'},
      'positiveTraitsPopUpText': {'o': 'p'},
      'returnToPlanStrings': {'rtp': 'v'},
      'personalInformationForm': {'pif': 'v'},
      'signUpLoginPage': {'sulp': 'v'},
      'introductionFormFirstPage': {'iff': 'v'},
      'introductionFormSecondPage': {'ifs': 'v'},
      'introductionFormLastPage': {'ifl': 'v'},
      'warningHomePageTitles': {'w': 'v'},
      'traitsHomePageTitles': {'t': 'v'},
      'formPhonePage': {'fpp': 'v'},
      'shareMessages': {'sm': 'v'},
      'formDifficultEventsTitles': {'fde': 'v'},
      'formDistractionsTitles': {'fdt': 'v'},
      'formFeelBetterTitles': {'ffbt': 'v'},
      'formMakeSaferTitles': {'fmst': 'v'},
      'formSharePageTitles': {'fspt': 'v'},
      'thanksSuggestionsList': ['ts1', 'ts2'],
      'positiveTraitsSuggestionsList': {
        'traits': ['t1'],
        'traits-female': <String>[],
        'traits-male': <String>[],
      },
      'homePageInspirationalQuotes': {
        'quotes-': ['q1'],
        'quotes-female': <String>[],
        'quotes-male': <String>[],
      },
      'phonePageTitles': {
        'mainTitle': ['mt'],
      },
      'sharePDFtexts': {'pdf': 'v'},
      'aboutPageText': {'about': 'v'},
      'disclaimerPageText': 'disc',
      'disclaimerPageNext': 'nxt',
      'wellnessVideos': {
        'videoId': ['v1'],
        'videoHeadline': ['h1'],
        'videoDescription': ['d1'],
        'videoLocale': ['en'],
      },
      'formSkipButtonText': {'skip': 'v'},
      'feelGoodPageTitles': {'fgt': 'v'},
      'extraMenuStrings': {'ems': 'v'},
      'syncPages': {'sp': 'v'},
      'popupBack': {'pb': 'v'},
      'addFormStrings': {'afs': 'v'},
      'addThanksFormStrings': {'atfs': 'v'},
      'addFormPageTemplateStrings': {'afpts': 'v'},
      'IntroductionRestart': {'ir': 'v'},
    };

Future<File> _writeJsonFile(Directory dir, Map<String, dynamic> data) async {
  final file = File('${dir.path}/data.json');
  await file.writeAsString(jsonEncode(data));
  return file;
}

FakeFirebaseFirestore _firestoreWithVersion(String version) {
  final fake = FakeFirebaseFirestore();
  fake.collection('VersionManager').add({'version': version});
  return fake;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('loadAppInfoFromJson', () {
    test('returns false when file does not exist', () async {
      final tempDir = await Directory.systemTemp.createTemp('maz_test_');
      final fakePath = '${tempDir.path}/nonexistent.json';
      final fakeFirestore = _firestoreWithVersion('1.0.0');
      final appInfo = AppInformation();

      final result = await loadAppInfoFromJson(appInfo, fakePath,
          firestore: fakeFirestore);

      expect(result, isFalse);
      await tempDir.delete(recursive: true);
    });

    test('returns false when stored version != firestore version', () async {
      final tempDir = await Directory.systemTemp.createTemp('maz_test_');
      final data = _buildValidJson('1.0.0'); // file says 1.0.0
      final file = await _writeJsonFile(tempDir, data);
      final fakeFirestore = _firestoreWithVersion('2.0.0'); // firestore says 2.0.0
      final appInfo = AppInformation();

      final result = await loadAppInfoFromJson(appInfo, file.path,
          firestore: fakeFirestore);

      expect(result, isFalse);
      await tempDir.delete(recursive: true);
    });

    test('returns true and populates appInfo when versions match', () async {
      const version = '3.1.0';
      final tempDir = await Directory.systemTemp.createTemp('maz_test_');
      final data = _buildValidJson(version);
      final file = await _writeJsonFile(tempDir, data);
      final fakeFirestore = _firestoreWithVersion(version);
      final appInfo = AppInformation();

      final result = await loadAppInfoFromJson(appInfo, file.path,
          firestore: fakeFirestore);

      expect(result, isTrue);
      // Verify a sample of updated fields
      expect(appInfo.reminderMainTitle, equals('RMT'));
      expect(appInfo.homeTitleGreeting, equals('HTG'));
      expect(appInfo.personalPlanMainTitle, equals({'a': 'b'}));
      expect(appInfo.thanksSuggestionsList, equals(['ts1', 'ts2']));
      expect(appInfo.disclaimerText, equals('disc'));
      expect(appInfo.disclaimerNext, equals('nxt'));
      expect(appInfo.lastUpdated, isNotNull);
      await tempDir.delete(recursive: true);
    });

    test('returns false on malformed JSON (catch path)', () async {
      final tempDir = await Directory.systemTemp.createTemp('maz_test_');
      final file = File('${tempDir.path}/data.json');
      await file.writeAsString('{not valid json!!!');
      final fakeFirestore = _firestoreWithVersion('1.0.0');
      final appInfo = AppInformation();

      final result = await loadAppInfoFromJson(appInfo, file.path,
          firestore: fakeFirestore);

      expect(result, isFalse);
      await tempDir.delete(recursive: true);
    });

    test('returns false on JSON missing required keys (cast error path)',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('maz_test_');
      // Missing 'personalPlanMainTitle' which needs .cast<String,String>()
      final data = {
        'appVersion': '1.0.0',
        'reminderMainTitle': 'R',
        // intentionally omit many required keys
      };
      final file = await _writeJsonFile(tempDir, data);
      final fakeFirestore = _firestoreWithVersion('1.0.0');
      final appInfo = AppInformation();

      final result = await loadAppInfoFromJson(appInfo, file.path,
          firestore: fakeFirestore);

      expect(result, isFalse);
      await tempDir.delete(recursive: true);
    });

    test('verifies map fields are deeply populated from JSON', () async {
      const version = '5.0.0';
      final tempDir = await Directory.systemTemp.createTemp('maz_test_');
      final data = _buildValidJson(version);
      final file = await _writeJsonFile(tempDir, data);
      final fakeFirestore = _firestoreWithVersion(version);
      final appInfo = AppInformation();

      await loadAppInfoFromJson(appInfo, file.path, firestore: fakeFirestore);

      expect(appInfo.traitMainTitle, equals({'e': 'f'}));
      expect(appInfo.journalMainTitle, equals({'i': 'j'}));
      expect(appInfo.syncPages, equals({'sp': 'v'}));
      expect(appInfo.extraMenuStrings, equals({'ems': 'v'}));
      expect(appInfo.wellnessVideos['videoId'], equals(['v1']));
      await tempDir.delete(recursive: true);
    });
  });
}
