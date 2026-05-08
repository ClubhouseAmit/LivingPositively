// ignore_for_file: non_constant_identifier_names

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';

void main() {
  group('getThanksSuggestionsList', () {
    test('returns list of suggestions from collection', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('Thanks-suggestions')
          .add({'suggestions': 'Be grateful'});
      await fake
          .collection('Thanks-suggestions')
          .add({'suggestions': 'Smile more'});

      final result = await getThanksSuggestionsList(firestore: fake);

      expect(result, containsAll(['Be grateful', 'Smile more']));
      expect(result.length, equals(2));
    });

    test('returns empty list when collection is empty', () async {
      final fake = FakeFirebaseFirestore();
      final result = await getThanksSuggestionsList(firestore: fake);
      expect(result, isEmpty);
    });
  });

  group('getPositiveTraitsSuggestionsList', () {
    test('returns traits, traits-female, traits-male keys', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('positiveTraits-suggestions').add({
        'generalSuggestions': 'Kind',
        'femaleSuggestions': 'KindF',
        'maleSuggestions': 'KindM',
      });
      await fake.collection('positiveTraits-suggestions').add({
        'generalSuggestions': 'Brave',
        'femaleSuggestions': 'BraveF',
        'maleSuggestions': 'BraveM',
      });

      final result = await getPositiveTraitsSuggestionsList(firestore: fake);

      expect(result['traits'], containsAll(['Kind', 'Brave']));
      expect(result['traits-female'], containsAll(['KindF', 'BraveF']));
      expect(result['traits-male'], containsAll(['KindM', 'BraveM']));
    });

    test('returns empty lists when collection is empty', () async {
      final fake = FakeFirebaseFirestore();
      final result = await getPositiveTraitsSuggestionsList(firestore: fake);
      expect(result['traits'], isEmpty);
      expect(result['traits-female'], isEmpty);
      expect(result['traits-male'], isEmpty);
    });
  });

  group('getAllTraitsData', () {
    test('returns correct map structure', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('homePage-titles')
          .doc('zzzzzzzzzzzzzzzzzzzx')
          .set({
        'mainTitles': 'Traits',
        'secondaryTitle': 'Sub',
        'secondaryTitleMale': 'SubM',
        'secondaryTitleFemale': 'SubF',
      });

      final result = await getAllTraitsData(firestore: fake);

      expect(result['mainTitle'], equals('Traits'));
      expect(result['secondaryTitle-'], equals('Sub'));
      expect(result['secondaryTitle-male'], equals('SubM'));
      expect(result['secondaryTitle-female'], equals('SubF'));
    });
  });

  group('getAllWarningData', () {
    test('returns correct map structure', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('homePage-titles')
          .doc('zzzzzzzzzzzzzzzzzzzw')
          .set({
        'mainTitles': 'Warning',
        'secondaryTitle': 'WarnSub',
        'secondaryTitleMale': 'WarnSubM',
        'secondaryTitleFemale': 'WarnSubF',
      });

      final result = await getAllWarningData(firestore: fake);

      expect(result['mainTitle'], equals('Warning'));
      expect(result['secondaryTitle-'], equals('WarnSub'));
      expect(result['secondaryTitle-male'], equals('WarnSubM'));
      expect(result['secondaryTitle-female'], equals('WarnSubF'));
    });
  });

  group('getHomePageInspirationalQuotes', () {
    test('returns quotes in three keys', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('HomePage-InspirationalQuotes').add({
        'quotes': 'Q1',
        'quotesFemale': 'Q1F',
        'quotesMale': 'Q1M',
      });

      final result = await getHomePageInspirationalQuotes(firestore: fake);

      expect(result['quotes-'], equals(['Q1']));
      expect(result['quotes-female'], equals(['Q1F']));
      expect(result['quotes-male'], equals(['Q1M']));
    });

    test('returns empty lists when no documents', () async {
      final fake = FakeFirebaseFirestore();
      final result = await getHomePageInspirationalQuotes(firestore: fake);
      expect(result['quotes-'], isEmpty);
    });
  });

  group('updateShareTexts', () {
    test('returns emergency and regular texts', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('ShareTexts')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'emergency': 'HELP', 'regular': 'Hi there'});

      final result = await updateShareTexts(firestore: fake);

      expect(result['emergency'], equals('HELP'));
      expect(result['regular'], equals('Hi there'));
    });
  });

  group('updateSharePDFtexts', () {
    test('returns map of fieldName -> content', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('SharePDFtexts')
          .add({'fieldName': 'title', 'content': 'My Title'});
      await fake
          .collection('SharePDFtexts')
          .add({'fieldName': 'body', 'content': 'My Body'});

      final result = await updateSharePDFtexts(firestore: fake);

      expect(result['title'], equals('My Title'));
      expect(result['body'], equals('My Body'));
    });

    test('returns empty map when collection is empty', () async {
      final fake = FakeFirebaseFirestore();
      final result = await updateSharePDFtexts(firestore: fake);
      expect(result, isEmpty);
    });
  });

  group('getWellnessVideos', () {
    test('returns all video fields', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('Wellness-Videos').add({
        'videoId': 'abc123',
        'videoHeadline': 'Breathe',
        'videoDescription': 'A breathing exercise',
        'videoLocal': 'en',
      });

      final result = await getWellnessVideos(firestore: fake);

      expect(result['videoId'], equals(['abc123']));
      expect(result['videoHeadline'], equals(['Breathe']));
      expect(result['videoDescription'], equals(['A breathing exercise']));
      expect(result['videoLocale'], equals(['en']));
    });

    test('returns empty lists when collection is empty', () async {
      final fake = FakeFirebaseFirestore();
      final result = await getWellnessVideos(firestore: fake);
      expect(result['videoId'], isEmpty);
    });
  });

  group('getSyncPages', () {
    test('returns map with field name + gender variants', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('SyncPages').add({
        'fieldName': 'syncTitle',
        'general': 'SyncG',
        'female': 'SyncF',
        'male': 'SyncM',
      });

      final result = await getSyncPages(firestore: fake);

      expect(result['syncTitle'], equals('SyncG'));
      expect(result['syncTitlefemale'], equals('SyncF'));
      expect(result['syncTitlemale'], equals('SyncM'));
    });

    test('returns empty map when collection is empty', () async {
      final fake = FakeFirebaseFirestore();
      final result = await getSyncPages(firestore: fake);
      expect(result, isEmpty);
    });
  });

  group('getDisclaimerPageText', () {
    test('returns [disclaimerText, next] from document', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('Disclaimer-Page-Text')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'disclaimerText': 'Read carefully', 'next': 'I agree'});

      final result = await getDisclaimerPageText(firestore: fake);

      expect(result[0], equals('Read carefully'));
      expect(result[1], equals('I agree'));
    });
  });

  group('getPersonalPlanSaveButtonText', () {
    test('returns female, male, general texts', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('PersonalPlan_SaveButton')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'female': 'SaveF', 'male': 'SaveM', 'general': 'Save'});

      final result = await getPersonalPlanSaveButtonText(firestore: fake);

      expect(result['female'], equals('SaveF'));
      expect(result['male'], equals('SaveM'));
      expect(result['general'], equals('Save'));
    });
  });

  group('getFeelGoodPageTitles', () {
    test('returns all required keys', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('feelGoodPageTitles')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({
        'header': 'Feel Good',
        'subHeader': 'Sub',
        'alertButtonTitle': 'Alert',
        'addImgButtonText': 'Add Image',
        'cameraButtonText': 'Camera',
        'cancelDeleteButtonText': 'Cancel',
        'deleteButtonText': 'Delete',
        'galleryButtonText': 'Gallery',
      });

      final result = await getFeelGoodPageTitles(firestore: fake);

      expect(result['header'], equals('Feel Good'));
      expect(result['subHeader'], equals('Sub'));
      expect(result['alertButtonTitle'], equals('Alert'));
      expect(result['galleryButtonText'], equals('Gallery'));
    });
  });

  group('updatePhonePageTitles', () {
    test('throws when collection is empty', () async {
      final fake = FakeFirebaseFirestore();
      expect(
        () => updatePhonePageTitles(firestore: fake),
        throwsException,
      );
    });

    test('returns structured map when 4 docs present', () async {
      final fake = FakeFirebaseFirestore();
      for (int i = 0; i < 4; i++) {
        await fake.collection('PhonePage-titles').add({
          'mainTitle': 'main$i',
          'contactsTitle': 'contacts$i',
          'emergencyNumbersTitle': 'emerg$i',
          'emergencyPhones': '10$i',
          'phoneName': 'name$i',
          'phoneDescription': 'desc$i',
          'emergencyDialogChooseTitle': 'choose$i',
          'emergencyDialogChooseTitleFemale': 'chooseF$i',
          'emergencyDialogChooseTitleGeneral': 'chooseG$i',
          'emergencyDialogWhatsapp': 'wa$i',
          'emergencyDialogDial': 'dial$i',
          'emergencyDialogWebsite': 'web$i',
          'emergencyDialogBack': 'back$i',
          'emergencyDialogWebsiteTitle': 'wt$i',
        });
      }

      final result = await updatePhonePageTitles(firestore: fake);

      expect(result.containsKey('mainTitle'), isTrue);
      expect(result['emergencyPhones']!.length, equals(4));
      expect(result['phoneName']!.length, equals(4));
    });
  });
}
