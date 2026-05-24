// Additional branch coverage for loadAppFromFirebase – every subgroup switch
// case that wasn't yet hit by `firebase_functions_load_firebase_test.dart`.
//
// These tests reuse the same FakeFirebaseFirestore + path_provider mock
// pattern as the existing suite. We focus on the specific switch arms that
// remain uncovered:
//   - IntroductionFormSecondPage non-mainTitle suffix branch
//   - IntroductionFormLastPage non-mainTitle suffix branch
//   - Distractions / FeelBetter nextButton fast-path
//   - MakeSafer non-button default branch
//   - HomePage PersonalPlanSecondaryTitle / TraitsSecondaryTitle /
//     ThanksSecondaryTitle / othersuggestions / thankyouPopup /
//     PositiveTraitPopup arms
//   - SharePage default (non-listed) field arm with gender suffixes
//   - AddFormPageTemplate / IntroductionRestart arms
//
// Each test seeds a fully-functional FakeFirebaseFirestore (so helper
// collections do not blow up) then adds one subgroup document and asserts
// the corresponding AppInformation map was updated.

import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/appInformation.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void _installPathProviderMock() {
  final tempDir = Directory.systemTemp.createTempSync('mazilon_test_').path;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, (call) async => tempDir);
}

void _uninstallPathProviderMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, null);
}

Future<FakeFirebaseFirestore> _buildFakeFirestore() async {
  final fake = FakeFirebaseFirestore();
  await fake.collection('VersionManager').add({'version': '2.0.0'});
  await fake
      .collection('Thanks-suggestions')
      .add({'suggestions': 'thank you suggestion'});
  await fake.collection('positiveTraits-suggestions').add({
    'generalSuggestions': 'brave',
    'femaleSuggestions': 'braveF',
    'maleSuggestions': 'braveM',
  });
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
  await fake
      .collection('homePage-titles')
      .doc('zzzzzzzzzzzzzzzzzzzu')
      .set({'mainTitles': 'remMain', 'secondaryTitle': 'remSub'});
  await fake
      .collection('homePage-titles')
      .doc('zzzzzzzzzzzzzzzzzzzv')
      .set({'mainTitles': 'ppMain', 'secondaryTitle': 'ppSub'});
  await fake.collection('HomePage-InspirationalQuotes').add({
    'quotes': 'q1',
    'quotesFemale': 'q1F',
    'quotesMale': 'q1M',
  });
  await fake
      .collection('ShareTexts')
      .doc('zzzzzzzzzzzzzzzzzzzy')
      .set({'emergency': 'sos', 'regular': 'reg'});
  // PhonePage-titles requires at least 4 documents (snapshot.docs[0..3]).
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
  await fake
      .collection('SharePDFtexts')
      .add({'fieldName': 'header', 'content': 'Share Header'});
  await fake.collection('SyncPages').add(
      {'fieldName': 'sync1', 'general': 'sg', 'female': 'sf', 'male': 'sm'});
  await fake.collection('Wellness-Videos').add({
    'videoId': 'vid1',
    'videoHeadline': 'headline',
    'videoDescription': 'desc',
    'videoLocal': 'en',
  });
  await fake
      .collection('Disclaimer-Page-Text')
      .doc('zzzzzzzzzzzzzzzzzzzy')
      .set({'disclaimerText': 'discText', 'next': 'nextBtn'});
  await fake
      .collection('PersonalPlan_SaveButton')
      .doc('zzzzzzzzzzzzzzzzzzzy')
      .set({'female': 'saveF', 'male': 'saveM', 'general': 'saveG'});
  await fake
      .collection('feelGoodPageTitles')
      .doc('zzzzzzzzzzzzzzzzzzzy')
      .set({
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

Future<void> _addDoc(
    FakeFirebaseFirestore fake, Map<String, dynamic> data) async {
  await fake
      .collection('_pageGroups')
      .doc('parent')
      .collection('subgroup')
      .add(data);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_installPathProviderMock);
  tearDown(_uninstallPathProviderMock);

  group('loadAppFromFirebase – additional branch coverage', () {
    test('IntroductionFormSecondPage non-mainTitle suffix branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'IntroductionFormSecondPage',
        'fieldName': 'subTitle',
        'general': 'Sub2G',
        'male': 'Sub2M',
        'female': 'Sub2F',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.introductionFormSecondPage['subTitle-'], 'Sub2G');
      expect(appInfo.introductionFormSecondPage['subTitle-male'], 'Sub2M');
      expect(appInfo.introductionFormSecondPage['subTitle-female'], 'Sub2F');
    });

    test('IntroductionFormLastPage non-mainTitle takes suffixed branch',
        () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'IntroductionFormLastPage',
        'fieldName': 'subTitle1',
        'general': 'S1G',
        'male': 'S1M',
        'female': 'S1F',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.introductionFormLastPage['subTitle1-'], 'S1G');
      expect(appInfo.introductionFormLastPage['subTitle1-male'], 'S1M');
      expect(appInfo.introductionFormLastPage['subTitle1-female'], 'S1F');
    });

    test('Distractions nextButton routes through no-suffix branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'Distractions',
        'fieldName': 'nextButton',
        'general': 'NextG',
        'male': 'NextM',
        'female': 'NextF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.formDistractionsTitles['nextButton'], 'NextG');
      expect(appInfo.formDistractionsTitles.containsKey('nextButtonmale'),
          isFalse);
    });

    test('FeelBetter nextButton routes through no-suffix branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'FeelBetter',
        'fieldName': 'nextButton',
        'general': 'FBnext',
        'male': 'FBM',
        'female': 'FBF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.formFeelBetterTitles['nextButton'], 'FBnext');
      expect(
          appInfo.formFeelBetterTitles.containsKey('nextButtonmale'), isFalse);
    });

    test('MakeSafer non-button field stored with gender suffixes', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'MakeSafer',
        'fieldName': 'mainTitle',
        'general': 'MSMain',
        'male': 'MSMainM',
        'female': 'MSMainF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.formMakeSaferTitles['mainTitle'], 'MSMain');
      expect(appInfo.formMakeSaferTitles['mainTitlemale'], 'MSMainM');
      expect(appInfo.formMakeSaferTitles['mainTitlefemale'], 'MSMainF');
    });

    test('HomePage PersonalPlanSecondaryTitle branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'PersonalPlanSecondaryTitle',
        'general': 'PPSubG',
        'male': 'PPSubM',
        'female': 'PPSubF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.personalPlanSubTitle['PersonalPlanSecondaryTitle-'],
          'PPSubG');
    });

    test('HomePage TraitsSecondaryTitle branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'TraitsSecondaryTitle',
        'general': 'TSubG',
        'male': 'TSubM',
        'female': 'TSubF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.traitSubTitle['TraitsSecondaryTitle-'], 'TSubG');
    });

    test('HomePage ThanksSecondaryTitle branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'ThanksSecondaryTitle',
        'general': 'JSubG',
        'male': 'JSubM',
        'female': 'JSubF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.journalSubTitle['ThanksSecondaryTitle-'], 'JSubG');
    });

    test('HomePage othersuggestions branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'othersuggestions',
        'general': 'OG',
        'male': 'OM',
        'female': 'OF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.othersuggestions['othersuggestions-'], 'OG');
    });

    test('HomePage thankyouPopup branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'thankyouPopup',
        'general': 'TPG',
        'male': 'TPM',
        'female': 'TPF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.journalPopUpText['thankyouPopup-'], 'TPG');
    });

    test('HomePage PositiveTraitPopup branch', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'HomePage',
        'fieldName': 'PositiveTraitPopup',
        'general': 'PG',
        'male': 'PM',
        'female': 'PF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.positiveTraitsPopUpText['PositiveTraitPopup-'], 'PG');
    });

    test('SharePage default (non-listed) field uses suffixed branch',
        () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'SharePage',
        'fieldName': 'mainTitle',
        'general': 'SPG',
        'male': 'SPM',
        'female': 'SPF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.formSharePageTitles['mainTitle'], 'SPG');
      expect(appInfo.formSharePageTitles['mainTitlemale'], 'SPM');
      expect(appInfo.formSharePageTitles['mainTitlefemale'], 'SPF');
    });

    test('AddFormPageTemplate branch populates addFormPageTemplateStrings',
        () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'AddFormPageTemplate',
        'fieldName': 'addTemplateTitle',
        'general': 'TplG',
        'male': 'TplM',
        'female': 'TplF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.addFormPageTemplateStrings['addTemplateTitle-'], 'TplG');
    });

    test('IntroductionRestart branch populates introductionRestart', () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'IntroductionRestart',
        'fieldName': 'restartTitle',
        'general': 'RG',
        'male': 'RM',
        'female': 'RF',
      });
      final appInfo = AppInformation();
      await loadAppFromFirebase(appInfo, firestore: fake);
      expect(appInfo.IntroductionRestart['restartTitle-'], 'RG');
    });

    test('Unknown page name falls through default arm without error',
        () async {
      final fake = await _buildFakeFirestore();
      await _addDoc(fake, {
        'page': 'NoSuchPage',
        'fieldName': 'whatever',
        'general': 'x',
        'male': 'y',
        'female': 'z',
      });
      final appInfo = AppInformation();
      await expectLater(
          loadAppFromFirebase(appInfo, firestore: fake), completes);
    });
  });
}
