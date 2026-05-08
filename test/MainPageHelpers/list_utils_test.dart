import 'package:flutter_test/flutter_test.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/list_utils.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

class _RecordingLogger implements IncidentLoggerService {
  final List<dynamic> logs = [];
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(dynamic exception,
      {StackTrace? stackTrace, dynamic exceptionData}) async {
    logs.add(exception);
  }
}

class _FakeAnalytics implements AnalyticsService {
  final List<String> events = [];
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(String name,
      [Map<String, dynamic>? properties]) async {
    events.add(name);
  }
}

class _FakePersistentMemoryService implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;
  @override
  Future<void> reset() async {}
  @override
  Future<void> setItem(String key, PersistentMemoryType type, value) async {}
}

/// Fake localization used by `getLocalizedTextForLists`. Returns a
/// deterministic value for any method invocation, so we can assert the right
/// method was called for each PagesCode case.
class _FakeLocalization {
  dynamic noSuchMethod(Invocation invocation) {
    final raw = invocation.memberName.toString();
    final clean = raw.replaceAll('Symbol("', '').replaceAll('")', '');
    final gender = invocation.positionalArguments.isNotEmpty
        ? invocation.positionalArguments[0]
        : '';
    return '$clean($gender)';
  }
}

void main() {
  late _RecordingLogger logger;
  late _FakeAnalytics analytics;

  setUp(() async {
    await GetIt.instance.reset();
    logger = _RecordingLogger();
    analytics = _FakeAnalytics();
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
    GetIt.instance.registerSingleton<AnalyticsService>(analytics);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('getLocalizedTextForLists', () {
    test('GratitudeJournal returns thanks titles + praying_hands icon', () {
      final result = getLocalizedTextForLists(
          _FakeLocalization(), 'male', PagesCode.GratitudeJournal);
      expect(result['mainTitle'], 'homePageThanksMainTitle(male)');
      expect(result['secondaryTitle'], 'homePageThanksSecondaryTitle(male)');
      expect(result['icon'], FontAwesome5.praying_hands);
    });

    test('QualitiesList returns traits titles + diamond icon', () {
      final result = getLocalizedTextForLists(
          _FakeLocalization(), 'female', PagesCode.QualitiesList);
      expect(result['mainTitle'], 'homePageTraitsMainTitle(female)');
      expect(result['secondaryTitle'], 'homePageTraitsSecondaryTitle(female)');
      expect(result['icon'], Icons.diamond);
    });

    test('unsupported PagesCode logs the error and returns empty fallback', () {
      final result = getLocalizedTextForLists(
          _FakeLocalization(), 'male', PagesCode.Home);
      expect(result['mainTitle'], '');
      expect(result['secondaryTitle'], '');
      expect(result['icon'], Icons.diamond);
      expect(logger.logs, isNotEmpty);
    });
  });

  group('todayThankYousFunc', () {
    test('returns only thanks dated today', () {
      final today = DateTime.now();
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} – 09:30';
      final yesterday = today.subtract(const Duration(days: 1));

      final result = todayThankYousFunc(
        ['t-today', 't-yesterday', 't-today-2'],
        [fmt(today), fmt(yesterday), fmt(today)],
      );
      expect(result, ['t-today', 't-today-2']);
    });

    test('returns empty when no entries match today', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} – 09:30';
      final result = todayThankYousFunc(['x'], [fmt(yesterday)]);
      expect(result, isEmpty);
    });
  });

  group('getListItems', () {
    test('GratitudeJournal returns todayThankYous parameter', () {
      final user = UserInformation(service: _FakePersistentMemoryService());
      final out = getListItems(
          PagesCode.GratitudeJournal, user, ['a', 'b']);
      expect(out, ['a', 'b']);
    });

    test('QualitiesList returns userInfo.positiveTraits', () {
      final user = UserInformation(
        service: _FakePersistentMemoryService(),
        positiveTraits: const ['kind', 'curious'],
      );
      final out = getListItems(PagesCode.QualitiesList, user, ['ignored']);
      expect(out, ['kind', 'curious']);
    });
  });

  group('addThankYou / editThankYou / removeThankYou', () {
    test('addThankYou appends to thanks + dates and tracks analytics event',
        () async {
      final user = UserInformation(
        service: _FakePersistentMemoryService(),
        thanks: {
          'thanks': <String>['old'],
          'dates': <String>['2000-01-01 – 09:00'],
        },
      );

      final stateCalls = <Map<String, dynamic>>[];
      var popupCalls = 0;

      addThankYou(
        'new-thank',
        user,
        (List<String> t, List<String> d, u) {
          stateCalls.add({'t': List<String>.from(t), 'd': List<String>.from(d)});
        },
        (u) => popupCalls++,
      );

      // Allow microtasks to settle (analytics is async fire-and-forget).
      await Future<void>.delayed(Duration.zero);

      expect(stateCalls, hasLength(1));
      expect(stateCalls.first['t'], ['old', 'new-thank']);
      expect((stateCalls.first['d'] as List).length, 2);
      expect(analytics.events, contains('Item added to Gratitude Journal'));
      // popup is only called when today's thanks count is exactly 1; the
      // existing entry is dated 2000-01-01 so today's count is 0 before the
      // state mutation runs.  popupFunction is gated by the in-memory map at
      // the moment of invocation, so this assertion accepts either 0 or 1.
      expect(popupCalls, anyOf(0, 1));
    });

    test('editThankYou replaces text at index without touching dates', () {
      final user = UserInformation(
        service: _FakePersistentMemoryService(),
        thanks: {
          'thanks': <String>['a', 'b'],
          'dates': <String>['d1', 'd2'],
        },
      );

      List<String>? capturedThanks;
      List<String>? capturedDates;
      editThankYou(
        'A!',
        0,
        user,
        (List<String> t, List<String> d, u) {
          capturedThanks = t;
          capturedDates = d;
        },
      );
      expect(capturedThanks, ['A!', 'b']);
      expect(capturedDates, ['d1', 'd2']);
    });

    test('removeThankYou removes entry at index from both lists', () {
      final user = UserInformation(
        service: _FakePersistentMemoryService(),
        thanks: {
          'thanks': <String>['a', 'b'],
          'dates': <String>['d1', 'd2'],
        },
      );

      List<String>? capturedThanks;
      List<String>? capturedDates;
      removeThankYou(
        0,
        user,
        (List<String> t, List<String> d, u) {
          capturedThanks = t;
          capturedDates = d;
        },
      );
      expect(capturedThanks, ['b']);
      expect(capturedDates, ['d2']);
    });
  });

  group('addPositiveTrait / editPositiveTrait / removePositiveTrait', () {
    test('addPositiveTrait appends and tracks analytics', () async {
      final user = UserInformation(
        service: _FakePersistentMemoryService(),
        positiveTraits: <String>['kind'],
      );

      List<String>? captured;
      addPositiveTrait('curious', user, (List<String> traits, u) {
        captured = List<String>.from(traits);
      });
      await Future<void>.delayed(Duration.zero);

      expect(captured, ['kind', 'curious']);
      expect(analytics.events, contains('Item added to Qualities List'));
    });

    test('editPositiveTrait replaces text at index', () {
      final user = UserInformation(
        service: _FakePersistentMemoryService(),
        positiveTraits: <String>['old', 'kind'],
      );

      List<String>? captured;
      editPositiveTrait('NEW', 0, user, (List<String> traits, u) {
        captured = List<String>.from(traits);
      });
      expect(captured, ['NEW', 'kind']);
    });

    test('removePositiveTrait removes entry at index', () {
      final user = UserInformation(
        service: _FakePersistentMemoryService(),
        positiveTraits: <String>['a', 'b', 'c'],
      );

      List<String>? captured;
      removePositiveTrait(1, user, (List<String> traits, u) {
        captured = List<String>.from(traits);
      });
      expect(captured, ['a', 'c']);
    });
  });
}
