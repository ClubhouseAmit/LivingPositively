// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';

void main() {
  group('createJson', () {
    test('returns a map with all 50+ expected keys', () {
      final appInfo = AppInformation(
        reminderMainTitle: 'RMT',
        reminderSubTitle: 'RST',
        homeTitleGreeting: 'HTG',
        personalPlanMainTitle: {'a': 'b'},
        personalPlanSubTitle: {'c': 'd'},
        traitMainTitle: {'e': 'f'},
        traitSubTitle: {'g': 'h'},
        journalMainTitle: {'i': 'j'},
        othersuggestions: {'os': 'val'},
        journalSubTitle: {'k': 'l'},
        journalPopUpText: {'m': 'n'},
        positiveTraitsPopUpText: {'o': 'p'},
        returnToPlanStrings: {'rtp': 'val'},
        personalInformationForm: {'pif': 'val'},
        signUpLoginPage: {'sulp': 'val'},
        introductionFormFirstPage: {'iff': 'val'},
        introductionFormSecondPage: {'ifs': 'val'},
        introductionFormLastPage: {'ifl': 'val'},
        warningHomePageTitles: {'w': 'v'},
        traitsHomePageTitles: {'t': 'v'},
        formPhonePage: {'fpp': 'val'},
        shareMessages: {'sm': 'val'},
        formDifficultEventsTitles: {'fde': 'val'},
        formDistractionsTitles: {'fdt': 'val'},
        formFeelBetterTitles: {'ffbt': 'val'},
        formMakeSaferTitles: {'fmst': 'val'},
        formSharePageTitles: {'fspt': 'val'},
        thanksSuggestionsList: ['ts1', 'ts2'],
        positiveTraitsSuggestionsList: {
          'traits': ['t1']
        },
        homePageInspirationalQuotes: {
          'quotes-': ['q1']
        },
        phonePageTitles: {
          'mainTitle': ['mt']
        },
        appVersion: '1.2.3',
        MakeSaferSug: ['ms1'],
        FeelBetterSug: ['fb1'],
        DistractionsSug: ['ds1'],
        DifficultEventsSug: ['de1'],
        sharePDFtexts: {'pdf': 'val'},
        aboutPageText: {'about': 'val'},
        disclaimerText: 'disc',
        disclaimerNext: 'next',
        wellnessVideos: {
          'videoId': ['v1']
        },
        formSkipButtonText: {'skip': 'val'},
        feelGoodPageTitles: {'fgt': 'val'},
        extraMenuStrings: {'ems': 'val'},
        syncPages: {'sp': 'val'},
        popupBack: {'pb': 'val'},
        addFormStrings: {'afs': 'val'},
        addThanksFormStrings: {'atfs': 'val'},
        addFormPageTemplateStrings: {'afpts': 'val'},
        IntroductionRestart: {'ir': 'val'},
      );

      final json = createJson(appInfo);

      // Verify all known top-level keys exist
      final expectedKeys = [
        'reminderMainTitle',
        'reminderSubTitle',
        'homeTitleGreeting',
        'personalPlanMainTitle',
        'personalPlanSubTitle',
        'traitMainTitle',
        'traitSubTitle',
        'journalMainTitle',
        'othersuggestions',
        'journalSubTitle',
        'journalPopUpText',
        'positiveTraitsPopUpText',
        'returnToPlanStrings',
        'personalInformationForm',
        'signUpLoginPage',
        'introductionFormFirstPage',
        'introductionFormSecondPage',
        'introductionFormLastPage',
        'warningHomePageTitles',
        'traitsHomePageTitles',
        'formPhonePage',
        'shareMessages',
        'formDifficultEventsTitles',
        'formDistractionsTitles',
        'formFeelBetterTitles',
        'formMakeSaferTitles',
        'formSharePageTitles',
        'thanksSuggestionsList',
        'positiveTraitsSuggestionsList',
        'homePageInspirationalQuotes',
        'phonePageTitles',
        'lastUpdated',
        'appVersion',
        'MakeSaferSug',
        'FeelBetterSug',
        'DistractionsSug',
        'DifficultEventsSug',
        'sharePDFtexts',
        'aboutPageText',
        'disclaimerPageText',
        'disclaimerPageNext',
        'wellnessVideos',
        'formSkipButtonText',
        'feelGoodPageTitles',
        'extraMenuStrings',
        'syncPages',
        'popupBack',
        'addFormStrings',
        'addThanksFormStrings',
        'addFormPageTemplateStrings',
        'IntroductionRestart',
      ];

      for (final key in expectedKeys) {
        expect(json.containsKey(key), isTrue,
            reason: 'Expected key "$key" to be present in createJson output');
      }

      expect(json.length, greaterThanOrEqualTo(51));
    });

    test('values in the map reflect appInfo field values', () {
      final appInfo = AppInformation(
        reminderMainTitle: 'TestReminder',
        appVersion: '9.9.9',
        disclaimerText: 'MyDisclaimer',
        disclaimerNext: 'NextButton',
      );

      final json = createJson(appInfo);

      expect(json['reminderMainTitle'], equals('TestReminder'));
      expect(json['appVersion'], equals('9.9.9'));
      expect(json['disclaimerPageText'], equals('MyDisclaimer'));
      expect(json['disclaimerPageNext'], equals('NextButton'));
    });

    test('lastUpdated is a non-empty string representing a DateTime', () {
      final appInfo = AppInformation();
      final json = createJson(appInfo);
      final lastUpdated = json['lastUpdated'] as String;
      expect(lastUpdated, isNotEmpty);
      expect(() => DateTime.parse(lastUpdated), returnsNormally);
    });

    test('list fields are preserved correctly', () {
      final appInfo = AppInformation(
        thanksSuggestionsList: ['alpha', 'beta', 'gamma'],
        MakeSaferSug: ['safe1', 'safe2'],
      );
      final json = createJson(appInfo);
      expect(json['thanksSuggestionsList'], equals(['alpha', 'beta', 'gamma']));
      expect(json['MakeSaferSug'], equals(['safe1', 'safe2']));
    });

    test('empty AppInformation produces map with empty/default values', () {
      final appInfo = AppInformation();
      final json = createJson(appInfo);
      expect(json['reminderMainTitle'], equals(''));
      expect(json['appVersion'], equals(''));
      expect(json['thanksSuggestionsList'], equals([]));
      expect(json['personalPlanMainTitle'], equals({}));
    });
  });
}
