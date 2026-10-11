import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/auth/data/auth_session_restoration.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../../../../test_support/contract_persistent_memory_service.dart';
import '../../../Firebase/firebase_auth_service_test.mocks.dart';

const Duration _timeout = Duration(milliseconds: 50);

final class _RecordingLogger implements IncidentLoggerService {
  final List<Object?> capturedExceptions = <Object?>[];

  @override
  Future<void> initializeSentry(Widget myApp) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    capturedExceptions.add(exception);
  }

  @override
  Future<void> captureWarning(
    String message, {
    required String contextName,
    required Map<String, Object> context,
  }) async {}
}

MockUser _user({
  bool isAnonymous = false,
  String uid = 'uid-1',
  String? email,
  String? displayName,
}) {
  final user = MockUser();
  when(user.isAnonymous).thenReturn(isAnonymous);
  when(user.uid).thenReturn(uid);
  when(user.email).thenReturn(email);
  when(user.displayName).thenReturn(displayName);
  return user;
}

void main() {
  late MockFirebaseAuth auth;
  late ContractPersistentMemoryService memory;
  late UserInformation userInfo;
  late int syncCalls;

  Future<void> restore({required bool hadMadeGuestDecision}) {
    return restoreAuthenticatedSession(
      userInfo,
      hadMadeGuestDecision: hadMadeGuestDecision,
      authStateTimeout: _timeout,
      onAuthenticatedSessionRestored: () async {
        syncCalls++;
      },
    );
  }

  setUp(() {
    auth = MockFirebaseAuth();
    when(auth.currentUser).thenReturn(null);
    when(auth.authStateChanges()).thenAnswer((_) => Stream<User?>.value(null));
    GetIt.instance.registerSingleton<FirebaseAuth>(auth);
    memory = ContractPersistentMemoryService();
    userInfo = UserInformation(
      service: memory,
      loggedIn: true,
      userId: 'stale-uid',
      email: 'stale@example.com',
      displayName: 'Stale',
    );
    syncCalls = 0;
  });

  tearDown(() async {
    userInfo.dispose();
    await GetIt.instance.reset();
  });

  group('restoreAuthenticatedSession with a current user', () {
    test('adopts the signed-in user without waiting for the stream', () async {
      final user = _user(
        uid: 'uid-1',
        email: 'a@example.com',
        displayName: 'Alice',
      );
      when(auth.currentUser).thenReturn(user);

      await restore(hadMadeGuestDecision: false);

      expect(userInfo.loggedIn, isTrue);
      expect(userInfo.authDecisionMade, isTrue);
      expect(userInfo.userId, 'uid-1');
      expect(userInfo.email, 'a@example.com');
      expect(userInfo.displayName, 'Alice');
      verifyNever(auth.authStateChanges());
    });

    test('does not resync the FCM token for an existing session', () async {
      final user = _user();
      when(auth.currentUser).thenReturn(user);

      await restore(hadMadeGuestDecision: false);
      await pumpEventQueue();

      expect(syncCalls, 0);
    });

    test('stores empty strings when email and name are missing', () async {
      final user = _user();
      when(auth.currentUser).thenReturn(user);

      await restore(hadMadeGuestDecision: false);

      expect(userInfo.email, isEmpty);
      expect(userInfo.displayName, isEmpty);
    });

    for (final hadMadeGuestDecision in <bool>[false, true]) {
      test(
        'treats an anonymous user as signed out '
        '(guest decision: $hadMadeGuestDecision)',
        () async {
          final user = _user(isAnonymous: true, uid: 'anon-uid');
          when(auth.currentUser).thenReturn(user);

          await restore(hadMadeGuestDecision: hadMadeGuestDecision);
          await pumpEventQueue();

          expect(userInfo.loggedIn, isFalse);
          expect(userInfo.authDecisionMade, hadMadeGuestDecision);
          expect(userInfo.userId, isEmpty);
          expect(userInfo.email, isEmpty);
          expect(userInfo.displayName, isEmpty);
          expect(syncCalls, 0);
        },
      );
    }

    test('persists the resolved sign-in flags', () async {
      final user = _user();
      when(auth.currentUser).thenReturn(user);

      await restore(hadMadeGuestDecision: false);
      await pumpEventQueue();

      expect(memory.durableStore['loggedIn'], isTrue);
      expect(memory.durableStore['authDecisionMade'], isTrue);
    });
  });

  group('restoreAuthenticatedSession from the auth stream', () {
    test('does not resync the FCM token for an anonymous user', () async {
      final user = _user(isAnonymous: true);
      when(
        auth.authStateChanges(),
      ).thenAnswer((_) => Stream<User?>.value(user));

      await restore(hadMadeGuestDecision: false);
      await pumpEventQueue();

      expect(userInfo.loggedIn, isFalse);
      expect(syncCalls, 0);
    });

    test('persists a resolved sign-out', () async {
      await restore(hadMadeGuestDecision: false);
      await pumpEventQueue();

      expect(userInfo.loggedIn, isFalse);
      expect(memory.durableStore['loggedIn'], isFalse);
      expect(memory.durableStore['authDecisionMade'], isFalse);
    });
  });

  group('restoreAuthenticatedSession when auth cannot resolve', () {
    test('does not report a FirebaseException', () async {
      final logger = _RecordingLogger();
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
      when(auth.authStateChanges()).thenAnswer(
        (_) => Stream<User?>.error(
          FirebaseException(plugin: 'firebase_auth', code: 'unavailable'),
        ),
      );

      await restore(hadMadeGuestDecision: false);
      await pumpEventQueue();

      expect(logger.capturedExceptions, isEmpty);
    });

    test('keeps the guest decision and clears identity in memory', () async {
      when(auth.authStateChanges()).thenAnswer(
        (_) => Stream<User?>.error(
          FirebaseException(plugin: 'firebase_auth', code: 'unavailable'),
        ),
      );

      await restore(hadMadeGuestDecision: true);

      expect(userInfo.loggedIn, isFalse);
      expect(userInfo.authDecisionMade, isTrue);
      expect(userInfo.userId, isEmpty);
      expect(userInfo.email, isEmpty);
      expect(userInfo.displayName, isEmpty);
    });

    test('does not write sign-in flags to storage', () async {
      final authState = StreamController<User?>();
      addTearDown(authState.close);
      when(auth.authStateChanges()).thenAnswer((_) => authState.stream);

      await restore(hadMadeGuestDecision: false);
      await pumpEventQueue();

      expect(memory.durableStore.containsKey('loggedIn'), isFalse);
      expect(memory.durableStore.containsKey('authDecisionMade'), isFalse);
    });

    test('completes without a registered incident logger', () async {
      when(auth.authStateChanges()).thenAnswer(
        (_) => Stream<User?>.error(MissingPluginException('no auth plugin')),
      );

      await expectLater(restore(hadMadeGuestDecision: false), completes);
      await pumpEventQueue();

      expect(userInfo.loggedIn, isFalse);
    });
  });
}
