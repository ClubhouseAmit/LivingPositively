import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';

void main() {
  group('BreathingSettings', () {
    test('should preserve defaults and measured duration precision', () {
      final settings = const BreathingSettings().copyWith(
        inhaleDuration: const Duration(milliseconds: 3501),
        showCircle: false,
      );
      final decoded = BreathingSettings.fromJson(settings.toJson());
      expect(decoded.inhaleDuration, const Duration(milliseconds: 3501));
      expect(decoded.exhaleDuration, const Duration(seconds: 3));
      expect(decoded.background, BreathingBackground.forest);
      expect(decoded.personalPhotoBase64, isNull);
      expect(decoded.showCircle, isFalse);
      expect(decoded.showText, isTrue);
    });

    test('should reject durations outside three to nine seconds', () {
      for (final duration in [
        Duration.zero,
        const Duration(microseconds: 2999999),
        const Duration(microseconds: 9000001),
      ]) {
        expect(
          () => const BreathingSettings().copyWith(inhaleDuration: duration),
          throwsFormatException,
        );
        expect(
          () => BreathingSettings(exhaleDuration: duration).toJson(),
          throwsFormatException,
        );
      }
    });

    test('should retain a remembered photo when selecting a preset', () {
      final photo = base64Encode([137, 80, 78, 71, 13, 10, 26, 10]);
      final settings = BreathingSettings(
        background: BreathingBackground.personal,
        personalPhotoBase64: photo,
      ).copyWith(background: BreathingBackground.forest);
      expect(settings.personalPhotoBase64, photo);
      expect(
        BreathingSettings.fromJson(settings.toJson()).personalPhotoBase64,
        photo,
      );
    });

    test('should reject invalid photo records and missing personal media', () {
      for (final photo in [
        'private/path.jpg',
        '',
        base64Encode([0, 1, 2]),
        'A' * 699053,
      ]) {
        expect(
          () => BreathingSettings(personalPhotoBase64: photo).toJson(),
          throwsFormatException,
        );
      }
      expect(
        () => const BreathingSettings(
          background: BreathingBackground.personal,
        ).toJson(),
        throwsFormatException,
      );
    });
  });

  group('BreathingSession', () {
    test(
      'should round trip complete and stopped attempts with null ratings',
      () {
        for (final cycles in [0, 3, 8]) {
          final session = _session(cycles: cycles);
          final decoded = BreathingSession.fromJson(session.toJson());
          expect(decoded.toJson(), session.toJson());
          expect(decoded.isComplete, cycles == 8);
          expect(decoded.stressBefore, isNull);
          expect(decoded.stressAfter, isNull);
        }
      },
    );

    test('should update the same attempt with explicitly supplied ratings', () {
      final original = _session(cycles: 8);
      final updated = original.copyWith(
        stressBefore: 10,
        stressAfter: 1,
        revision: 1,
      );
      expect(updated.id, original.id);
      expect(updated.startedAt, original.startedAt);
      expect(updated.stressBefore, 10);
      expect(updated.stressAfter, 1);
      expect(updated.revision, 1);
      expect(original.stressAfter, isNull);
    });

    test('should reject invalid ratings, counts, and chronology', () {
      for (final rating in [0, 11]) {
        expect(
          () => _session().copyWith(stressBefore: rating),
          throwsFormatException,
        );
        expect(
          () => _session().copyWith(stressAfter: rating),
          throwsFormatException,
        );
      }
      for (final cycles in [-1, 9]) {
        expect(() => _session(cycles: cycles), throwsFormatException);
      }
      expect(() => _session().copyWith(revision: -1), throwsFormatException);
      expect(
        () => _session().copyWith(endedAt: DateTime.utc(2000)),
        throwsFormatException,
      );
      expect(() => _session(id: ' '), throwsFormatException);
    });
  });

  group('BreathingSnapshot', () {
    test(
      'should freeze its session collection and round trip all patterns',
      () {
        final sessions = [
          for (final pattern in BreathingPattern.values)
            BreathingSession(
              id: pattern.name,
              startedAt: DateTime.utc(2026, 9, 13),
              endedAt: DateTime.utc(2026, 9, 13, 0, 1),
              pattern: pattern,
              completedCycles: 8,
            ),
        ];
        final snapshot = BreathingSnapshot(sessions: sessions);
        sessions.clear();
        expect(snapshot.sessions, hasLength(3));
        expect(() => snapshot.sessions.clear(), throwsUnsupportedError);
        expect(
          BreathingSnapshot.decode(snapshot.encode()).toJson(),
          snapshot.toJson(),
        );
      },
    );

    test('should reject every malformed envelope without dropping records', () {
      final good = BreathingSnapshot(sessions: [_session()]).toJson();
      for (final bad in [
        '',
        ' ',
        'not-json',
        'null',
        '[]',
        '{}',
        jsonEncode({...good, 'version': 2}),
        jsonEncode({...good, 'version': 1.5}),
        jsonEncode({...good, 'settings': null}),
        jsonEncode({...good, 'sessions': null}),
        jsonEncode({
          ...good,
          'sessions': [null],
        }),
        jsonEncode({
          ...good,
          'sessions': [_session().toJson(), _session().toJson()],
        }),
      ]) {
        expect(() => BreathingSnapshot.decode(bad), throwsFormatException);
      }
    });

    test('should reject malformed settings fields and unknown identifiers', () {
      final good = const BreathingSettings().toJson();
      for (final change in <Map<String, dynamic>>[
        {'background': 'unknown'},
        {'showCircle': 1},
        {'showText': null},
        {'personalPhotoBase64': 7},
        {'inhaleMicroseconds': 3000000.5},
        {'exhaleMicroseconds': 10000000},
      ]) {
        expect(
          () => BreathingSettings.fromJson({...good, ...change}),
          throwsFormatException,
        );
      }
      final missing = {...good}..remove('personalPhotoBase64');
      expect(() => BreathingSettings.fromJson(missing), throwsFormatException);
    });

    test('should reject inconsistent or normalized session fields', () {
      final good = _session().toJson();
      for (final change in <Map<String, dynamic>>[
        {'id': null},
        {'pattern': 'unknown'},
        {'isComplete': true},
        {'stressBefore': 1.5},
        {'stressAfter': '1'},
        {'startedAt': '2026-02-31T00:00:00.000Z'},
        {'startedAt': '2026-09-13'},
        {'endedAt': 'broken'},
        {'revision': -1},
      ]) {
        expect(
          () => BreathingSession.fromJson({...good, ...change}),
          throwsFormatException,
        );
      }
    });
  });
}

BreathingSession _session({String id = 'attempt', int cycles = 0}) =>
    BreathingSession(
      id: id,
      startedAt: DateTime.utc(2026, 9, 13),
      endedAt: DateTime.utc(2026, 9, 13, 0, 1),
      pattern: BreathingPattern.basic,
      completedCycles: cycles,
    );
