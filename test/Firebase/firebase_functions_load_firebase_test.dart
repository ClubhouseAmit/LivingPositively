// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void _installPathProviderMock() {
  final tempDir = Directory.systemTemp.createTempSync('mazilon_test_').path;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, (call) async {
        return tempDir;
      });
}

void _uninstallPathProviderMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, null);
}

// ---------------------------------------------------------------------------
// Helper: build a fully-seeded FakeFirebaseFirestore so all helper functions
// called from loadAppFromFirebase can resolve their queries without errors.
// ---------------------------------------------------------------------------
Future<FakeFirebaseFirestore> _buildFullFakeFirestore() async {
  final fake = FakeFirebaseFirestore();

  // VersionManager
  await fake.collection('VersionManager').add({'version': '2.0.0'});

  // Thanks-suggestions
  await fake.collection('Thanks-suggestions').add({
    'suggestions': 'thank you suggestion',
  });

  // positiveTraits-suggestions
  await fake.collection('positiveTraits-suggestions').add({
    'generalSuggestions': 'brave',
    'femaleSuggestions': 'braveF',
    'maleSuggestions': 'braveM',
  });

  // homePage-titles – warning (w), traits (x), reminder (u), personalPlan (v)
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzw').set({
    'mainTitles': 'warnMain',
    'secondaryTitle': 'warnSub',
    'secondaryTitleMale': 'warnSubM',
    'secondaryTitleFemale': 'warnSubF',
  });
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzx').set({
    'mainTitles': 'traitMain',
    'secondaryTitle': 'traitSub',
    'secondaryTitleMale': 'traitSubM',
    'secondaryTitleFemale': 'traitSubF',
  });
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzu').set({
    'mainTitles': 'remMain',
    'secondaryTitle': 'remSub',
  });
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzv').set({
    'mainTitles': 'ppMain',
    'secondaryTitle': 'ppSub',
  });

  // HomePage-InspirationalQuotes
  await fake.collection('HomePage-InspirationalQuotes').add({
    'quotes': 'q1',
    'quotesFemale': 'q1F',
    'quotesMale': 'q1M',
  });

  // ShareTexts
  await fake.collection('ShareTexts').doc('zzzzzzzzzzzzzzzzzzzy').set({
    'emergency': 'sos',
    'regular': 'reg',
  });

  // PhonePage-titles (needs at least 4 docs for updatePhonePageTitles)
  for (int i = 0; i < 4; i++) {
    await fake.collection('PhonePage-titles').add({
      'mainTitle': 'ptMain$i',
      'contactsTitle': 'ptContacts$i',
      'emergencyNumbersTitle': 'ptEmerg$i',
      'emergencyPhones': '120',
      'phoneName': 'Eran',
      'phoneDescription': 'desc',
      'emergencyDialogChooseTitle': 'choose',
      'emergencyDialogChooseTitleFemale': 'chooseF',
      'emergencyDialogChooseTitleGeneral': 'chooseG',
      'emergencyDialogWhatsapp': 'wa',
      'emergencyDialogDial': 'dial',
      'emergencyDialogWebsite': 'web',
      'emergencyDialogBack': 'back',
      'emergencyDialogWebsiteTitle': 'webTitle',
    });
  }

  // SharePDFtexts
  await fake.collection('SharePDFtexts').add({
    'fieldName': 'header',
    'content': 'Share Header',
  });

  // SyncPages
  await fake.collection('SyncPages').add({
    'fieldName': 'sync1',
    'general': 'sg',
    'female': 'sf',
    'male': 'sm',
  });

  // Wellness-Videos
  await fake.collection('Wellness-Videos').add({
    'videoId': 'vid1',
    'videoHeadline': 'headline',
    'videoDescription': 'desc',
    'videoLocal': 'en',
  });

  // Disclaimer-Page-Text
  await fake.collection('Disclaimer-Page-Text').doc('zzzzzzzzzzzzzzzzzzzy').set(
    {'disclaimerText': 'discText', 'next': 'nextBtn'},
  );

  // PersonalPlan_SaveButton
  await fake
      .collection('PersonalPlan_SaveButton')
      .doc('zzzzzzzzzzzzzzzzzzzy')
      .set({'female': 'saveF', 'male': 'saveM', 'general': 'saveG'});

  // feelGoodPageTitles
  await fake.collection('feelGoodPageTitles').doc('zzzzzzzzzzzzzzzzzzzy').set({
    'header': 'fgh',
    'subHeader': 'fgsh',
    'alertButtonTitle': 'abt',
    'addImgButtonText': 'aibt',
    'cameraButtonText': 'cbt',
    'cancelDeleteButtonText': 'cdbt',
    'deleteButtonText': 'dbt',
    'galleryButtonText': 'gbt',
  });

  return fake;
}

/// Adds a document to the `subgroup` collection-group under an arbitrary parent.
Future<void> _addSubgroupDoc(
  FakeFirebaseFirestore fake,
  Map<String, dynamic> data,
) async {
  await fake
      .collection('_pageGroups')
      .doc('parent')
      .collection('subgroup')
      .add(data);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_installPathProviderMock);
  tearDown(_uninstallPathProviderMock);

  group('loadAppFromFirebase – subgroup switch branches', () {
    test('SignupLogin branch populates signUpLoginPage', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'SignupLogin',
        'fieldName': 'loginTitle',
        'general': 'Login',
        'male': 'LoginM',
        'female': 'LoginF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.signUpLoginPage['loginTitle-'], equals('Login'));
      expect(appInfo.signUpLoginPage['loginTitle-male'], equals('LoginM'));
      expect(appInfo.signUpLoginPage['loginTitle-female'], equals('LoginF'));
    });

    test('UserSettings branch populates personalInformationForm', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'UserSettings',
        'fieldName': 'settingsTitle',
        'general': 'Settings',
        'male': 'SettingsM',
        'female': 'SettingsF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(
        appInfo.personalInformationForm['settingsTitle-'],
        equals('Settings'),
      );
    });

    test(
      'IntroductionFormFirstPage branch populates introductionFormFirstPage',
      () async {
        final fake = await _buildFullFakeFirestore();
        await _addSubgroupDoc(fake, {
          'page': 'IntroductionFormFirstPage',
          'fieldName': 'mainTitle',
          'general': 'IntroFirst',
          'male': 'IntroFirstM',
          'female': 'IntroFirstF',
        });

        final appInfo = AppInformation();
        await loadAppFromFirebase(appInfo, firestore: fake);

        expect(
          appInfo.introductionFormFirstPage['mainTitle-'],
          equals('IntroFirst'),
        );
      },
    );

    test(
      'IntroductionFormLastPage mainTitle stored without gender suffix',
      () async {
        final fake = await _buildFullFakeFirestore();
        await _addSubgroupDoc(fake, {
          'page': 'IntroductionFormLastPage',
          'fieldName': 'mainTitle',
          'general': 'LastPageMain',
          'male': 'unused',
          'female': 'unused',
        });

        final appInfo = AppInformation();
        await loadAppFromFirebase(appInfo, firestore: fake);

        expect(
          appInfo.introductionFormLastPage['mainTitle'],
          equals('LastPageMain'),
        );
      },
    );

    test('DifficultEvents nextButton stored without gender suffix', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'DifficultEvents',
        'fieldName': 'nextButton',
        'general': 'Next',
        'male': 'NextM',
        'female': 'NextF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.formDifficultEventsTitles['nextButton'], equals('Next'));
      expect(
        appInfo.formDifficultEventsTitles.containsKey('nextButtonmale'),
        isFalse,
      );
    });

    test(
      'DifficultEvents non-button field stored with gender suffixes',
      () async {
        final fake = await _buildFullFakeFirestore();
        await _addSubgroupDoc(fake, {
          'page': 'DifficultEvents',
          'fieldName': 'mainTitle',
          'general': 'DE Main',
          'male': 'DE MainM',
          'female': 'DE MainF',
        });

        final appInfo = AppInformation();
        await loadAppFromFirebase(appInfo, firestore: fake);

        expect(
          appInfo.formDifficultEventsTitles['mainTitle'],
          equals('DE Main'),
        );
        expect(
          appInfo.formDifficultEventsTitles['mainTitlemale'],
          equals('DE MainM'),
        );
        expect(
          appInfo.formDifficultEventsTitles['mainTitlefemale'],
          equals('DE MainF'),
        );
      },
    );

    test('Distractions branch populates formDistractionsTitles', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'Distractions',
        'fieldName': 'header',
        'general': 'Dist',
        'male': 'DistM',
        'female': 'DistF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.formDistractionsTitles['header'], equals('Dist'));
    });

    test('FeelBetter branch populates formFeelBetterTitles', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'FeelBetter',
        'fieldName': 'title',
        'general': 'FB',
        'male': 'FBM',
        'female': 'FBF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.formFeelBetterTitles['title'], equals('FB'));
    });

    test('MakeSafer ShowMoreButton stored without gender suffix', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'MakeSafer',
        'fieldName': 'ShowMoreButton',
        'general': 'Show More',
        'male': 'ShowMoreM',
        'female': 'ShowMoreF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(
        appInfo.formMakeSaferTitles['ShowMoreButton'],
        equals('Show More'),
      );
      expect(
        appInfo.formMakeSaferTitles.containsKey('ShowMoreButtonmale'),
        isFalse,
      );
    });

    test('PhonesPage branch populates formPhonePage', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'PhonesPage',
        'fieldName': 'header',
        'general': 'PhoneH',
        'male': 'PhoneHM',
        'female': 'PhoneHF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.formPhonePage['header'], equals('PhoneH'));
      expect(appInfo.formPhonePage['headermale'], equals('PhoneHM'));
      expect(appInfo.formPhonePage['headerfemale'], equals('PhoneHF'));
    });

    test('PersonalPlanPage branch populates returnToPlanStrings', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'PersonalPlanPage',
        'fieldName': 'alreadyFilled',
        'general': 'Already',
        'male': 'AlreadyM',
        'female': 'AlreadyF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.returnToPlanStrings['alreadyFilled'], equals('Already'));
    });

    test('HomePage Greetings branch sets homeTitleGreeting', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'Greetings',
        'general': 'Hello there!',
        'male': 'unused',
        'female': 'unused',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.homeTitleGreeting, equals('Hello there!'));
    });

    test(
      'HomePage PersonalPlanMainTitle branch populates personalPlanMainTitle',
      () async {
        final fake = await _buildFullFakeFirestore();
        await _addSubgroupDoc(fake, {
          'page': 'HomePage',
          'fieldName': 'PersonalPlanMainTitle',
          'general': 'PPMain',
          'male': 'PPMainM',
          'female': 'PPMainF',
        });

        final appInfo = AppInformation();
        await loadAppFromFirebase(appInfo, firestore: fake);

        expect(
          appInfo.personalPlanMainTitle['PersonalPlanMainTitle-'],
          equals('PPMain'),
        );
        expect(
          appInfo.personalPlanMainTitle['PersonalPlanMainTitle-male'],
          equals('PPMainM'),
        );
      },
    );

    test('HomePage TraitsMainTitle branch populates traitMainTitle', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'TraitsMainTitle',
        'general': 'TraitM',
        'male': 'TraitMM',
        'female': 'TraitMF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.traitMainTitle['TraitsMainTitle-'], equals('TraitM'));
    });

    test(
      'HomePage ThanksMainTitle branch populates journalMainTitle',
      () async {
        final fake = await _buildFullFakeFirestore();
        await _addSubgroupDoc(fake, {
          'page': 'HomePage',
          'fieldName': 'ThanksMainTitle',
          'general': 'ThanksMain',
          'male': 'ThanksMainM',
          'female': 'ThanksMainF',
        });

        final appInfo = AppInformation();
        await loadAppFromFirebase(appInfo, firestore: fake);

        expect(
          appInfo.journalMainTitle['ThanksMainTitle-'],
          equals('ThanksMain'),
        );
      },
    );

    test('HomePage Back branch populates popupBack', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'Back',
        'general': 'BackG',
        'male': 'BackM',
        'female': 'BackF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.popupBack['Back-'], equals('BackG'));
    });

    test('SharePage header stored without gender suffix', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'SharePage',
        'fieldName': 'header',
        'general': 'ShareH',
        'male': 'unused',
        'female': 'unused',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.formSharePageTitles['header'], equals('ShareH'));
      expect(appInfo.formSharePageTitles.containsKey('headermale'), isFalse);
    });

    test('AddForm branch populates addFormStrings', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'AddForm',
        'fieldName': 'addTitle',
        'general': 'AddG',
        'male': 'AddM',
        'female': 'AddF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.addFormStrings['addTitle-'], equals('AddG'));
    });

    test('AddThanksForm branch populates addThanksFormStrings', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'AddThanksForm',
        'fieldName': 'thanksTitle',
        'general': 'ThanksG',
        'male': 'ThanksM',
        'female': 'ThanksF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.addThanksFormStrings['thanksTitle-'], equals('ThanksG'));
    });

    test(
      'AddFormPageTemplate branch populates addFormPageTemplateStrings',
      () async {
        final fake = await _buildFullFakeFirestore();
        await _addSubgroupDoc(fake, {
          'page': 'AddFormPageTemplate',
          'fieldName': 'templateTitle',
          'general': 'TplG',
          'male': 'TplM',
          'female': 'TplF',
        });

        final appInfo = AppInformation();
        await loadAppFromFirebase(appInfo, firestore: fake);

        expect(
          appInfo.addFormPageTemplateStrings['templateTitle-'],
          equals('TplG'),
        );
      },
    );

    test('IntroductionRestart branch populates IntroductionRestart', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {
        'page': 'IntroductionRestart',
        'fieldName': 'restartTitle',
        'general': 'RestartG',
        'male': 'RestartM',
        'female': 'RestartF',
      });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      expect(appInfo.IntroductionRestart['restartTitle-'], equals('RestartG'));
    });

    test('VersionManager document sets appVersion', () async {
      // VersionManager with version '9.9.9' already added in _buildFullFakeFirestore
      // but it added '2.0.0'. Let's add a separate test with a specific version.
      final fake2 = FakeFirebaseFirestore();
      await fake2.collection('VersionManager').add({'version': '7.7.7'});
      // Seed all required helpers
      await fake2.collection('Thanks-suggestions').add({'suggestions': 's'});
      await fake2.collection('positiveTraits-suggestions').add({
        'generalSuggestions': 'g',
        'femaleSuggestions': 'f',
        'maleSuggestions': 'm',
      });
      await fake2
          .collection('homePage-titles')
          .doc('zzzzzzzzzzzzzzzzzzzw')
          .set({
            'mainTitles': 'w',
            'secondaryTitle': 'ws',
            'secondaryTitleMale': 'wm',
            'secondaryTitleFemale': 'wf',
          });
      await fake2
          .collection('homePage-titles')
          .doc('zzzzzzzzzzzzzzzzzzzx')
          .set({
            'mainTitles': 't',
            'secondaryTitle': 'ts',
            'secondaryTitleMale': 'tm',
            'secondaryTitleFemale': 'tf',
          });
      await fake2.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzu').set(
        {'mainTitles': 'r', 'secondaryTitle': 'rs'},
      );
      await fake2.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzv').set(
        {'mainTitles': 'pp', 'secondaryTitle': 'pps'},
      );
      await fake2.collection('HomePage-InspirationalQuotes').add({
        'quotes': 'q',
        'quotesFemale': 'qf',
        'quotesMale': 'qm',
      });
      await fake2.collection('ShareTexts').doc('zzzzzzzzzzzzzzzzzzzy').set({
        'emergency': 'e',
        'regular': 'r',
      });
      for (int i = 0; i < 4; i++) {
        await fake2.collection('PhonePage-titles').add({
          'mainTitle': 'pt$i',
          'contactsTitle': 'ct$i',
          'emergencyNumbersTitle': 'en$i',
          'emergencyPhones': '100',
          'phoneName': 'p',
          'phoneDescription': 'd',
          'emergencyDialogChooseTitle': 'c',
          'emergencyDialogChooseTitleFemale': 'cf',
          'emergencyDialogChooseTitleGeneral': 'cg',
          'emergencyDialogWhatsapp': 'wa',
          'emergencyDialogDial': 'dial',
          'emergencyDialogWebsite': 'web',
          'emergencyDialogBack': 'back',
          'emergencyDialogWebsiteTitle': 'wt',
        });
      }
      await fake2.collection('SharePDFtexts').add({
        'fieldName': 'f',
        'content': 'c',
      });
      await fake2.collection('SyncPages').add({
        'fieldName': 's',
        'general': 'sg',
        'female': 'sf',
        'male': 'sm',
      });
      await fake2.collection('Wellness-Videos').add({
        'videoId': 'v',
        'videoHeadline': 'h',
        'videoDescription': 'd',
        'videoLocal': 'en',
      });
      await fake2
          .collection('Disclaimer-Page-Text')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'disclaimerText': 'd', 'next': 'n'});
      await fake2
          .collection('PersonalPlan_SaveButton')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'female': 'f', 'male': 'm', 'general': 'g'});
      await fake2
          .collection('feelGoodPageTitles')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({
            'header': 'h',
            'subHeader': 'sh',
            'alertButtonTitle': 'abt',
            'addImgButtonText': 'ai',
            'cameraButtonText': 'cb',
            'cancelDeleteButtonText': 'cd',
            'deleteButtonText': 'db',
            'galleryButtonText': 'gb',
          });

      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake2);

      expect(appInfo.appVersion, equals('7.7.7'));
    });

    test('doc without page key is silently ignored', () async {
      final fake = await _buildFullFakeFirestore();
      await _addSubgroupDoc(fake, {'someOtherKey': 'value'}); // no 'page' key

      final appInfo = AppInformation();
      // Should not throw
      await expectLater(
        loadAppFromFirebase(appInfo, firestore: fake),
        completes,
      );
    });

    test('helper collections are populated into appInfo', () async {
      final fake = await _buildFullFakeFirestore();
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);

      // Thanks suggestions from getThanksSuggestionsList
      expect(appInfo.thanksSuggestionsList, equals(['thank you suggestion']));

      // Disclaimer from getDisclaimerPageText
      expect(appInfo.disclaimerText, equals('discText'));
      expect(appInfo.disclaimerNext, equals('nextBtn'));

      // Version set from VersionManager
      expect(appInfo.appVersion, equals('2.0.0'));

      // ShareTexts
      expect(appInfo.shareMessages['emergency'], equals('sos'));
      expect(appInfo.shareMessages['regular'], equals('reg'));

      // SyncPages
      expect(appInfo.syncPages['sync1'], equals('sg'));
    });
  });
}
