import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';

/// Stub that implements every method called by `retrieveInformation` and the
/// related `retrieve*List` helpers. Each method records the call and returns a
/// deterministic string based on its method name and the supplied gender.
class _FakeLocalization {
  final List<String> calls = [];

  String _record(String key, String gender) {
    calls.add('$key:$gender');
    return '$key($gender)';
  }

  // Headers used by retrieveInformation switch cases.
  String difficultEventsHeader(String g) => _record('difficultEventsHeader', g);
  String difficultEventsSubTitle(String g) =>
      _record('difficultEventsSubTitle', g);
  String difficultEventsMidTitle(String g) =>
      _record('difficultEventsMidTitle', g);
  String difficultEventsMidSubTitle(String g) =>
      _record('difficultEventsMidSubTitle', g);

  String makeSaferHeader(String g) => _record('makeSaferHeader', g);
  String makeSaferSubTitle(String g) => _record('makeSaferSubTitle', g);
  String makeSaferMidTitle(String g) => _record('makeSaferMidTitle', g);
  String makeSaferMidSubTitle(String g) => _record('makeSaferMidSubTitle', g);

  String feelBetterHeader(String g) => _record('feelBetterHeader', g);
  String feelBetterSubTitle(String g) => _record('feelBetterSubTitle', g);
  String feelBetterMidTitle(String g) => _record('feelBetterMidTitle', g);
  String feelBetterMidSubTitle(String g) => _record('feelBetterMidSubTitle', g);

  String distractionsHeader(String g) => _record('distractionsHeader', g);
  String distractionsSubTitle(String g) => _record('distractionsSubTitle', g);
  String distractionsMidTitle(String g) => _record('distractionsMidTitle', g);
  String distractionsMidSubTitle(String g) =>
      _record('distractionsMidSubTitle', g);

  String nextButton(String g) => _record('nextButton', g);
  String showMoreButton(String g) => _record('showMoreButton', g);

  // List item entries (only first one needed for sanity check; the rest just
  // need to be defined so the noSuchMethod fallback is not triggered.)
  String _listEntry(String list, int index, String g) =>
      _record('${list}No$index', g);

  // The lists used by retrieveDifficultEventsList, retrieveMakeSaferList,
  // retrieveFeelBetterList, retrieveDistractionsList, retrieveThanksList,
  // retrieveTraitsList, retrieveInspirationalQuotes are all referenced
  // dynamically; we use noSuchMethod to handle them all.
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    final clean = name.replaceAll('Symbol("', '').replaceAll('")', '');
    final gender =
        invocation.positionalArguments.isNotEmpty ? invocation.positionalArguments[0] : '';
    calls.add('$clean:$gender');
    return '$clean($gender)';
  }
}

void main() {
  late _FakeLocalization loc;

  setUp(() {
    loc = _FakeLocalization();
  });

  group('retrieveInformation switch cases', () {
    test('PersonalPlan-DifficultEvents returns the difficult events bundle',
        () {
      final result = retrieveInformation(
          'PersonalPlan-DifficultEvents', 'male', loc);
      expect(result['header'], 'difficultEventsHeader(male)');
      expect(result['subTitle'], 'difficultEventsSubTitle(male)');
      expect(result['midTitle'], 'difficultEventsMidTitle(male)');
      expect(result['midSubTitle'], 'difficultEventsMidSubTitle(male)');
      expect(result['nextButtonText'], 'nextButton(male)');
      expect(result['showMoreButtonText'], 'showMoreButton(male)');
      expect(result['list'], isA<List<String>>());
      expect((result['list'] as List).isNotEmpty, isTrue);
    });

    test('PersonalPlan-MakeSafer returns the make safer bundle', () {
      final result = retrieveInformation('PersonalPlan-MakeSafer', 'female', loc);
      expect(result['header'], 'makeSaferHeader(female)');
      expect(result['subTitle'], 'makeSaferSubTitle(female)');
      expect(result['midTitle'], 'makeSaferMidTitle(female)');
      expect(result['midSubTitle'], 'makeSaferMidSubTitle(female)');
    });

    test('PersonalPlan-FeelBetter returns the feel better bundle', () {
      final result =
          retrieveInformation('PersonalPlan-FeelBetter', 'other', loc);
      expect(result['header'], 'feelBetterHeader(other)');
      expect(result['subTitle'], 'feelBetterSubTitle(other)');
      expect(result['midTitle'], 'feelBetterMidTitle(other)');
      expect(result['midSubTitle'], 'feelBetterMidSubTitle(other)');
    });

    test('PersonalPlan-Distractions returns the distractions bundle', () {
      final result =
          retrieveInformation('PersonalPlan-Distractions', 'male', loc);
      expect(result['header'], 'distractionsHeader(male)');
      expect(result['subTitle'], 'distractionsSubTitle(male)');
      expect(result['midTitle'], 'distractionsMidTitle(male)');
      expect(result['midSubTitle'], 'distractionsMidSubTitle(male)');
    });

    test('empty gender is replaced with "other" for the list lookup', () {
      retrieveInformation('PersonalPlan-DifficultEvents', '', loc);
      // The list helper is invoked with "other" rather than the empty string.
      expect(
          loc.calls.any((c) => c.startsWith('difficultEventsListNo0:other')),
          isTrue);
    });

    test('unknown collection name throws an Exception', () {
      expect(
        () => retrieveInformation('Unknown-Page', 'male', loc),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('retrieve*List helpers populate non-empty lists', () {
    test('retrieveInspirationalQuotes returns 20 quotes', () {
      final list = retrieveInspirationalQuotes(loc, 'male');
      expect(list, hasLength(20));
    });

    test('retrieveThanksList returns 12 entries', () {
      final list = retrieveThanksList(loc, 'female');
      expect(list, hasLength(12));
    });

    test('retrieveTraitsList returns at least 20 entries', () {
      final list = retrieveTraitsList(loc, 'other');
      expect(list.length, greaterThanOrEqualTo(20));
    });

    test('retrieveDifficultEventsList returns multiple entries', () {
      final list = retrieveDifficultEventsList(loc, 'male');
      expect(list.length, greaterThanOrEqualTo(15));
    });

    test('retrieveMakeSaferList returns multiple entries', () {
      final list = retrieveMakeSaferList(loc, 'male');
      expect(list.length, greaterThanOrEqualTo(15));
    });

    test('retrieveFeelBetterList returns multiple entries', () {
      final list = retrieveFeelBetterList(loc, 'male');
      expect(list.length, greaterThanOrEqualTo(15));
    });

    test('retrieveDistractionsList returns ~33 entries', () {
      final list = retrieveDistractionsList(loc, 'male');
      expect(list.length, greaterThanOrEqualTo(30));
    });
  });
}
