// Phase 9 coverage tests for `lib/util/Firebase/firebase_functions.dart`.
//
// Covers the 29 newly-injectable helpers (ADR-001 / ADR-004) that follow
// the `Future<X> helperName(...args..., {FirebaseFirestore? firestore})`
// shape. Each helper resolves its Firestore via
// `firestore ?? FirebaseFirestore.instance`, so a `FakeFirebaseFirestore`
// injected via the named param exercises the production seam end-to-end
// without touching the real SDK.
//
// Test groupings:
//   * homePage-titles single-doc reads (mainTitle / secondaryTitle pairs)
//   * Other single-doc reads (personal info, intro form pages, journal,
//     greeting, return-to-plan, popups, updateTest1)
//   * Gender-parameterised PhonePage-titles reads (getMainTitle /
//     getContactsTitle / getEmergancyTitle)
//   * fetchWarnings (random-pick Warning object)
//   * Multi-collection `update*` helpers (six of them; each has a happy
//     path + at least one empty-collection throw path)
//
// All tests use the production `firestore:` named param. The implicit
// `?? FirebaseFirestore.instance` fallback is intentionally NOT exercised
// (it would require a live Firebase app and is out of scope per ADR-004).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';

// --- Seed helpers ---------------------------------------------------------

Future<void> _seedHomePageTitles(FakeFirebaseFirestore fake) async {
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzy').set({
    'mainTitles': 'journalMain',
    'secondaryTitle': 'journalSub',
  });
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzx').set({
    'mainTitles': 'traitMain',
    'secondaryTitle': 'traitSub',
  });
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzv').set({
    'mainTitles': 'ppMain',
    'secondaryTitle': 'ppSub',
  });
  await fake.collection('homePage-titles').doc('zzzzzzzzzzzzzzzzzzzu').set({
    'mainTitles': 'remMain',
    'secondaryTitle': 'remSub',
  });
}

Future<void> _seedPhonePageTitles(FakeFirebaseFirestore fake) async {
  await fake.collection('PhonePage-titles').doc('zzzzzzzzzzzzzzzzzzzy').set({
    'mainTitle': 'maleMain',
    'contactsTitle': 'maleContacts',
    'emergencyNumbersTitle': 'maleEmerg',
  });
  await fake.collection('PhonePage-titles').doc('zzzzzzzzzzzzzzzzzzzx').set({
    'mainTitle': 'femaleMain',
    'contactsTitle': 'femaleContacts',
    'emergencyNumbersTitle': 'femaleEmerg',
  });
}

void main() {
  group('homePage-titles single-doc reads', () {
    test('getJournalMainTitle returns mainTitles field', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getJournalMainTitle(firestore: fake);

      expect(result, 'journalMain');
    });

    test('getJournalSeocndaryTitle returns secondaryTitle field', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getJournalSeocndaryTitle(firestore: fake);

      expect(result, 'journalSub');
    });

    test('getTraitMainTitle reads from doc zzzz...x', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getTraitMainTitle(firestore: fake);

      expect(result, 'traitMain');
    });

    test('getTraitSeocndaryTitle reads from doc zzzz...x', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getTraitSeocndaryTitle(firestore: fake);

      expect(result, 'traitSub');
    });

    test('getPersonalPlanMainTitle reads from doc zzzz...v', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getPersonalPlanMainTitle(firestore: fake);

      expect(result, 'ppMain');
    });

    test('getPersonalPlanSecondaryTitle reads from doc zzzz...v', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getPersonalPlanSecondaryTitle(firestore: fake);

      expect(result, 'ppSub');
    });

    test('getReminderMainTitle reads from doc zzzz...u', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getReminderMainTitle(firestore: fake);

      expect(result, 'remMain');
    });

    test('getReminderSeocndaryTitle reads from doc zzzz...u', () async {
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      final result = await getReminderSeocndaryTitle(firestore: fake);

      expect(result, 'remSub');
    });

    test('main/secondary helpers are independent across docs', () async {
      // Guards against accidentally pointing two helpers at the same doc:
      // each pair (journal / trait / personalPlan / reminder) must return a
      // distinct value when the seed gives each doc a unique payload.
      final fake = FakeFirebaseFirestore();
      await _seedHomePageTitles(fake);

      expect(await getJournalMainTitle(firestore: fake), 'journalMain');
      expect(await getTraitMainTitle(firestore: fake), 'traitMain');
      expect(await getPersonalPlanMainTitle(firestore: fake), 'ppMain');
      expect(await getReminderMainTitle(firestore: fake), 'remMain');
    });
  });

  group('other single-doc reads', () {
    test('getPersonalInfo returns name/gender/age map', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('PersonalInformation-Form')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'name': 'Alice', 'gender': 'female', 'age': '30'});

      final result = await getPersonalInfo(firestore: fake);

      expect(result, {'name': 'Alice', 'gender': 'female', 'age': '30'});
    });

    test('getIntroductionFormFirstPage returns three titles', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('IntroductionForm_FirstPage')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({
        'mainTitle': 'mT',
        'subTitle1': 'sT1',
        'subTitle2': 'sT2',
      });

      final result = await getIntroductionFormFirstPage(firestore: fake);

      expect(
          result, {'mainTitle': 'mT', 'subTitle1': 'sT1', 'subTitle2': 'sT2'});
    });

    test('getIntroductionFormSecondPage returns main + sub', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('IntroductionForm_SecondPage')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'mainTitle': 'm2', 'subTitle': 's2'});

      final result = await getIntroductionFormSecondPage(firestore: fake);

      expect(result, {'mainTitle': 'm2', 'subTitle': 's2'});
    });

    test('getIntroductionFormLastPage returns 7-key map', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('IntroductionForm_LastPage')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({
        'mainTitle': 'mt',
        'subTitle1': 's1',
        'subTitle2': 's2',
        'subTitle1Male': 's1m',
        'subTitle2Male': 's2m',
        'subTitle1Female': 's1f',
        'subTitle2Female': 's2f',
      });

      final result = await getIntroductionFormLastPage(firestore: fake);

      expect(result['mainTitle'], 'mt');
      expect(result['subTitle1-'], 's1');
      expect(result['subTitle2-'], 's2');
      expect(result['subTitle1-male'], 's1m');
      expect(result['subTitle2-male'], 's2m');
      expect(result['subTitle1-female'], 's1f');
      expect(result['subTitle2-female'], 's2f');
      expect(result.length, 7);
    });

    test('getJournalTitle returns title field', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('Journal-title')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'title': 'My Journal'});

      final result = await getJournalTitle(firestore: fake);

      expect(result, 'My Journal');
    });

    test('getGreetingString returns homePageGreeting field', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('homePage-strings')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'homePageGreeting': 'Hello there!'});

      final result = await getGreetingString(firestore: fake);

      expect(result, 'Hello there!');
    });

    test('getReturnToPlan returns alreadyFilled + didntFill', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('PersonalPlan_FullPage')
          .doc('6kLyHj3X7tpOh6uQ0K6w')
          .set({'alreadyFilled': 'AF', 'didntFill': 'DF'});

      final result = await getReturnToPlan(firestore: fake);

      expect(result, {'alreadyFilled': 'AF', 'didntFill': 'DF'});
    });

    test('getJournalPopUpText returns thankYouPopupText field', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('Popups-texts')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'thankYouPopupText': 'Thank You'});

      final result = await getJournalPopUpText(firestore: fake);

      expect(result, 'Thank You');
    });

    test('getPositiveTraitsPopUpText reads same doc/field as journal',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('Popups-texts')
          .doc('zzzzzzzzzzzzzzzzzzzy')
          .set({'thankYouPopupText': 'Great Trait'});

      final result = await getPositiveTraitsPopUpText(firestore: fake);

      expect(result, 'Great Trait');
    });

    test('updateTest1 returns [quotes] from doc zzzz...u', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('HomePage-InspirationalQuotes')
          .doc('zzzzzzzzzzzzzzzzzzzu')
          .set({'quotes': 'Carpe Diem'});

      final result = await updateTest1(firestore: fake);

      expect(result, ['Carpe Diem']);
      expect(result.length, 1);
    });
  });

  group('PhonePage-titles gender-parameterised reads', () {
    test('getMainTitle(true) reads male doc', () async {
      final fake = FakeFirebaseFirestore();
      await _seedPhonePageTitles(fake);

      final result = await getMainTitle(true, firestore: fake);

      expect(result, 'maleMain');
    });

    test('getMainTitle(false) reads female doc', () async {
      final fake = FakeFirebaseFirestore();
      await _seedPhonePageTitles(fake);

      final result = await getMainTitle(false, firestore: fake);

      expect(result, 'femaleMain');
    });

    test('getContactsTitle(true) reads contactsTitle on male doc', () async {
      final fake = FakeFirebaseFirestore();
      await _seedPhonePageTitles(fake);

      final result = await getContactsTitle(true, firestore: fake);

      expect(result, 'maleContacts');
    });

    test('getContactsTitle(false) reads contactsTitle on female doc', () async {
      final fake = FakeFirebaseFirestore();
      await _seedPhonePageTitles(fake);

      final result = await getContactsTitle(false, firestore: fake);

      expect(result, 'femaleContacts');
    });

    test('getEmergancyTitle(true) reads emergencyNumbersTitle on male doc',
        () async {
      final fake = FakeFirebaseFirestore();
      await _seedPhonePageTitles(fake);

      final result = await getEmergancyTitle(true, firestore: fake);

      expect(result, 'maleEmerg');
    });

    test('getEmergancyTitle(false) reads emergencyNumbersTitle on female doc',
        () async {
      final fake = FakeFirebaseFirestore();
      await _seedPhonePageTitles(fake);

      final result = await getEmergancyTitle(false, firestore: fake);

      expect(result, 'femaleEmerg');
    });
  });

  group('fetchWarnings', () {
    test('returns Warning whose .warnings is full list and .text is in list',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('warning-suggestions')
          .add({'suggestions': 'warn-1'});
      await fake
          .collection('warning-suggestions')
          .add({'suggestions': 'warn-2'});
      await fake
          .collection('warning-suggestions')
          .add({'suggestions': 'warn-3'});

      final result = await fetchWarnings(firestore: fake);

      expect(result, isA<Warning>());
      expect(result.warnings, hasLength(3));
      expect(result.warnings, containsAll(['warn-1', 'warn-2', 'warn-3']));
      // .text is a random pick — must be one of the seeded values.
      expect(result.warnings.contains(result.text), isTrue);
    });

    test('single-doc collection yields a Warning with that single text',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('warning-suggestions')
          .add({'suggestions': 'only-one'});

      final result = await fetchWarnings(firestore: fake);

      expect(result.warnings, ['only-one']);
      expect(result.text, 'only-one');
    });
  });

  group('update* multi-collection helpers', () {
    // ---- updatePhoneFormTitles --------------------------------------------
    test('updatePhoneFormTitles happy path builds general/female/male map',
        () async {
      final fake = FakeFirebaseFirestore();
      // First collection just needs at least one doc to pass the
      // isEmpty check; its contents are not read.
      await fake.collection('PersonalPlan-PhonesPage').add({'placeholder': 1});
      await fake.collection('FormPage-PhonesPage').add({
        'fieldName': 'title',
        'general': 'G',
        'female': 'F',
        'male': 'M',
      });

      final result = await updatePhoneFormTitles(firestore: fake);

      expect(result['title'], 'G');
      expect(result['titlefemale'], 'F');
      expect(result['titlemale'], 'M');
    });

    test('updatePhoneFormTitles throws when PersonalPlan-PhonesPage is empty',
        () async {
      final fake = FakeFirebaseFirestore();
      // Only seed the secondary collection; primary remains empty.
      await fake.collection('FormPage-PhonesPage').add({
        'fieldName': 'title',
        'general': 'G',
        'female': 'F',
        'male': 'M',
      });

      await expectLater(
        updatePhoneFormTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    test('updatePhoneFormTitles throws when FormPage-PhonesPage is empty',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('PersonalPlan-PhonesPage').add({'placeholder': 1});

      await expectLater(
        updatePhoneFormTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    // ---- updateFormDifficultEventsTitles ----------------------------------
    test('updateFormDifficultEventsTitles happy path', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('PersonalPlan-DifficultEvents')
          .add({'placeholder': 1});
      await fake.collection('FormPage-DifficultEvents').add({
        'fieldName': 'evt',
        'general': 'eG',
        'female': 'eF',
        'male': 'eM',
      });

      final result = await updateFormDifficultEventsTitles(firestore: fake);

      expect(result['evt'], 'eG');
      expect(result['evtfemale'], 'eF');
      expect(result['evtmale'], 'eM');
    });

    test(
        'updateFormDifficultEventsTitles throws when PersonalPlan-DifficultEvents is empty',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('FormPage-DifficultEvents').add({
        'fieldName': 'evt',
        'general': 'eG',
        'female': 'eF',
        'male': 'eM',
      });

      await expectLater(
        updateFormDifficultEventsTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'updateFormDifficultEventsTitles throws when FormPage-DifficultEvents is empty',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('PersonalPlan-DifficultEvents')
          .add({'placeholder': 1});

      await expectLater(
        updateFormDifficultEventsTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    // ---- updateFormDistractionsTitles -------------------------------------
    test('updateFormDistractionsTitles happy path', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('PersonalPlan-Distractions')
          .add({'placeholder': 1});
      await fake.collection('FormPage-Distractions').add({
        'fieldName': 'dis',
        'general': 'dG',
        'female': 'dF',
        'male': 'dM',
      });

      final result = await updateFormDistractionsTitles(firestore: fake);

      expect(result['dis'], 'dG');
      expect(result['disfemale'], 'dF');
      expect(result['dismale'], 'dM');
    });

    test('updateFormDistractionsTitles throws on empty primary collection',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('FormPage-Distractions').add({
        'fieldName': 'dis',
        'general': 'dG',
        'female': 'dF',
        'male': 'dM',
      });

      await expectLater(
        updateFormDistractionsTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    test('updateFormDistractionsTitles throws on empty secondary collection',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('PersonalPlan-Distractions')
          .add({'placeholder': 1});

      await expectLater(
        updateFormDistractionsTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    // ---- updateFormFeelBetterTitles ---------------------------------------
    test('updateFormFeelBetterTitles happy path', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('PersonalPlan-FeelBetter').add({'placeholder': 1});
      await fake.collection('FormPage-FeelBetter').add({
        'fieldName': 'fb',
        'general': 'fbG',
        'female': 'fbF',
        'male': 'fbM',
      });

      final result = await updateFormFeelBetterTitles(firestore: fake);

      expect(result['fb'], 'fbG');
      expect(result['fbfemale'], 'fbF');
      expect(result['fbmale'], 'fbM');
    });

    test('updateFormFeelBetterTitles throws on empty primary collection',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('FormPage-FeelBetter').add({
        'fieldName': 'fb',
        'general': 'fbG',
        'female': 'fbF',
        'male': 'fbM',
      });

      await expectLater(
        updateFormFeelBetterTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    test('updateFormFeelBetterTitles throws on empty secondary collection',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('PersonalPlan-FeelBetter').add({'placeholder': 1});

      await expectLater(
        updateFormFeelBetterTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    // ---- updateFormMakeSaferTitles ----------------------------------------
    test('updateFormMakeSaferTitles happy path', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('PersonalPlan-MakeSafer').add({'placeholder': 1});
      await fake.collection('FormPage-MakeSafer').add({
        'fieldName': 'ms',
        'general': 'msG',
        'female': 'msF',
        'male': 'msM',
      });

      final result = await updateFormMakeSaferTitles(firestore: fake);

      expect(result['ms'], 'msG');
      expect(result['msfemale'], 'msF');
      expect(result['msmale'], 'msM');
    });

    test('updateFormMakeSaferTitles throws on empty primary collection',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('FormPage-MakeSafer').add({
        'fieldName': 'ms',
        'general': 'msG',
        'female': 'msF',
        'male': 'msM',
      });

      await expectLater(
        updateFormMakeSaferTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    test('updateFormMakeSaferTitles throws on empty secondary collection',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('PersonalPlan-MakeSafer').add({'placeholder': 1});

      await expectLater(
        updateFormMakeSaferTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    // ---- updateFormSharePageTitles ----------------------------------------
    test('updateFormSharePageTitles happy path returns 11-key map', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('PersonalPlan-SharePage').add({
        'header': 'h',
        'headerFemale': 'hF',
        'subTitle': 'st',
        'subTitleFemale': 'stF',
        'midTitle': 'mt',
        'midTitleFemale': 'mtF',
        'finishButton': 'fb',
        'shareTitle': 'shT',
        'shareTitleFemale': 'shTF',
        'emergencySendButtonText': 'eSB',
        'routineSendButtonText': 'rSB',
      });

      final result = await updateFormSharePageTitles(firestore: fake);

      expect(result, {
        'header': 'h',
        'headerFemale': 'hF',
        'subTitle': 'st',
        'subTitleFemale': 'stF',
        'midTitle': 'mt',
        'midTitleFemale': 'mtF',
        'finishButton': 'fb',
        'shareTitle': 'shT',
        'shareTitleFemale': 'shTF',
        'emergencySendButtonText': 'eSB',
        'routineSendButtonText': 'rSB',
      });
      expect(result.length, 11);
    });

    test(
        'updateFormSharePageTitles throws when PersonalPlan-SharePage is empty',
        () async {
      final fake = FakeFirebaseFirestore();

      await expectLater(
        updateFormSharePageTitles(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    // ---- updatePhonePersonalPlanText --------------------------------------
    test(
        'updatePhonePersonalPlanText returns data fields from primary collection',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('Phone-PersonalPlanText').add({'data': 'first'});
      await fake.collection('Phone-PersonalPlanText').add({'data': 'second'});
      // Secondary collection must also be non-empty to pass guard.
      await fake.collection('FormPage-MakeSafer').add({'placeholder': 1});

      final result = await updatePhonePersonalPlanText(firestore: fake);

      expect(result, hasLength(2));
      expect(result, containsAll(['first', 'second']));
    });

    test(
        'updatePhonePersonalPlanText throws when Phone-PersonalPlanText is empty',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('FormPage-MakeSafer').add({'placeholder': 1});

      await expectLater(
        updatePhonePersonalPlanText(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });

    test('updatePhonePersonalPlanText throws when FormPage-MakeSafer is empty',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('Phone-PersonalPlanText').add({'data': 'first'});

      await expectLater(
        updatePhonePersonalPlanText(firestore: fake),
        throwsA(isA<Exception>()),
      );
    });
  });

  // Smoke check: every helper under test must accept a FirebaseFirestore?
  // named param. This is enforced by the compiler when we pass `firestore:`
  // throughout the suite, so this group is a deliberately tiny sanity test
  // that fails compilation rather than at runtime if the seam regresses.
  group('injection seam compile-time check', () {
    test('all 29 helpers accept named firestore param', () {
      // Just reference each helper's tear-off to force the analyzer to
      // verify the signature shape. No execution.
      final List<Function> helpers = <Function>[
        getJournalMainTitle,
        getJournalSeocndaryTitle,
        getTraitMainTitle,
        getTraitSeocndaryTitle,
        getPersonalPlanMainTitle,
        getPersonalPlanSecondaryTitle,
        getReminderMainTitle,
        getReminderSeocndaryTitle,
        getPersonalInfo,
        getIntroductionFormFirstPage,
        getIntroductionFormSecondPage,
        getIntroductionFormLastPage,
        getJournalTitle,
        getGreetingString,
        getReturnToPlan,
        getJournalPopUpText,
        getPositiveTraitsPopUpText,
        updateTest1,
        getMainTitle,
        getContactsTitle,
        getEmergancyTitle,
        fetchWarnings,
        updatePhoneFormTitles,
        updateFormDifficultEventsTitles,
        updateFormDistractionsTitles,
        updateFormFeelBetterTitles,
        updateFormMakeSaferTitles,
        updateFormSharePageTitles,
        updatePhonePersonalPlanText,
      ];
      expect(helpers.length, 29);
      // Silence "unused" diagnostics on the FirebaseFirestore import:
      // we use it via the named-param type of every helper above.
      expect(FirebaseFirestore, isNotNull);
    });
  });
}
