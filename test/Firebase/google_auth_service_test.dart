import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mazilon/features/auth/data/auth_repository.dart';
import 'package:mazilon/features/auth/data/auth_telemetry.dart';
import 'package:mazilon/features/auth/data/google_auth_models.dart';
import 'package:mazilon/features/auth/data/google_auth_lifecycle.dart';
import 'package:mazilon/features/auth/ui/auth_error_reporting.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mockito/mockito.dart';

import 'firebase_auth_service_test.mocks.dart';
import '../helpers/widget_test_scaffold.dart' show NoopAnalyticsService;

class _MockGoogleSignIn extends Mock implements GoogleSignIn {
  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) => super.noSuchMethod(
    Invocation.method(#initialize, [], {
      #clientId: clientId,
      #serverClientId: serverClientId,
      #nonce: nonce,
      #hostedDomain: hostedDomain,
    }),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  ) as Future<void>;

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) => super.noSuchMethod(
    Invocation.method(#authenticate, [], {#scopeHint: scopeHint}),
    returnValue: Future<GoogleSignInAccount>.value(const _GoogleAccount()),
  ) as Future<GoogleSignInAccount>;

  @override
  Future<void> signOut() => super.noSuchMethod(
    Invocation.method(#signOut, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  ) as Future<void>;
}

class _GoogleAccount implements GoogleSignInAccount {
  const new({this.idToken = 'google-id-token'});

  final String? idToken;

  @override
  GoogleSignInAuthentication get authentication =>
      GoogleSignInAuthentication(idToken: idToken);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingAnalytics extends NoopAnalyticsService {
  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async => throw StateError('offline');
}

class _MockIncidentLoggerService extends Mock implements IncidentLoggerService {
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) => super.noSuchMethod(
    Invocation.method(
      #captureLog,
      [exception],
      {#stackTrace: stackTrace, #exceptionData: exceptionData},
    ),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  ) as Future<void>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Google authentication', () {
    late _MockGoogleSignIn googleSignIn;
    late _GoogleAccount account;
    late MockFirebaseAuth firebaseAuth;
    late MockUserCredential firebaseCredential;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AuthService.debugGoogleSignInServerClientIdOverride = ' server-client ';
      googleSignIn = _MockGoogleSignIn();
      account = const _GoogleAccount();
      firebaseAuth = MockFirebaseAuth();
      firebaseCredential = MockUserCredential();
      GetIt.instance.registerSingleton<GoogleSignIn>(googleSignIn);
      GetIt.instance.registerSingleton<FirebaseAuth>(firebaseAuth);
      when(googleSignIn.authenticate()).thenAnswer((_) async => account);
      when(firebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => firebaseCredential);
    });

    tearDown(() async {
      googleAuthTelemetryClock = DateTime.now;
      debugDefaultTargetPlatformOverride = null;
      AuthService.debugGoogleSignInServerClientIdOverride = null;
      AuthService.debugGoogleSignInIosClientIdOverride = null;
      AuthService.debugFirebaseIosClientIdOverride = null;
      AuthService.debugFirebaseIosBundleIdOverride = null;
      await GetIt.instance.reset();
    });

    test(
      'should initialize once and pass only the ID token to Firebase',
      () async {
        expect(await AuthService.signInWithGoogle(), same(firebaseCredential));
        expect(await AuthService.signInWithGoogle(), same(firebaseCredential));

        verify(googleSignIn.initialize(serverClientId: 'server-client'))
            .called(1);
        verify(googleSignIn.authenticate()).called(2);
        final credentials = verify(
          firebaseAuth.signInWithCredential(captureAny),
        ).captured.cast<OAuthCredential>();
        expect(credentials, hasLength(2));
        for (final credential in credentials) {
          expect(credential.providerId, 'google.com');
          expect(credential.idToken, 'google-id-token');
          expect(credential.accessToken, isNull);
        }
      },
    );

    for (final idToken in <String?>[null, '', ' \t\n ']) {
      test(
        'should reject an unusable ID token ($idToken) before Firebase',
        () async {
          when(googleSignIn.authenticate())
              .thenAnswer((_) async => _GoogleAccount(idToken: idToken));

          await expectLater(
            AuthService.signInWithGoogle(),
            throwsA(
              isA<GoogleSignInException>().having(
                (error) => error.code,
                'code',
                GoogleSignInExceptionCode.clientConfigurationError,
              ),
            ),
          );

          verifyNever(firebaseAuth.signInWithCredential(any));
        },
      );
    }

    test('should await one initialization for overlapping requests', () async {
      final initialization = Completer<void>();
      when(googleSignIn.initialize(serverClientId: 'server-client'))
          .thenAnswer((_) => initialization.future);

      final first = AuthService.signInWithGoogle();
      final second = AuthService.signInWithGoogle();
      verify(googleSignIn.initialize(serverClientId: 'server-client'))
          .called(1);
      verifyNever(googleSignIn.authenticate());
      verifyNever(firebaseAuth.signInWithCredential(any));

      initialization.complete();
      expect(await first, same(firebaseCredential));
      expect(await second, same(firebaseCredential));
      verify(googleSignIn.authenticate()).called(2);
    });

    test('should initialize with the configured iOS client ID', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AuthService.debugGoogleSignInIosClientIdOverride = ' ios-client ';
      AuthService.debugFirebaseIosClientIdOverride = 'ios-client';
      AuthService.debugFirebaseIosBundleIdOverride =
          'com.clubhouse.livingpositively';

      await AuthService.signInWithGoogle();

      verify(
        googleSignIn.initialize(
          clientId: 'ios-client',
          serverClientId: 'server-client',
        ),
      ).called(1);
    });

    test(
      'should return null on cancellation without signing into Firebase',
      () async {
        when(googleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        );

        expect(await AuthService.signInWithGoogle(), isNull);

        verifyNever(firebaseAuth.signInWithCredential(any));
      },
    );

    for (final code in [
      GoogleSignInExceptionCode.canceled,
      GoogleSignInExceptionCode.interrupted,
      GoogleSignInExceptionCode.uiUnavailable,
    ]) {
      test('should count $code without sending provider details', () async {
        final analytics = NoopAnalyticsService();
        GetIt.instance.registerSingleton<AnalyticsService>(analytics);
        when(googleSignIn.authenticate()).thenThrow(
          GoogleSignInException(
            code: code,
            description: 'private provider description',
          ),
        );
        try {
          await AuthService.signInWithGoogle();
        } on GoogleSignInException {
          // The repository preserves these retryable errors for the form.
        }
        await Future<void>.delayed(Duration.zero);
        expect(
          analytics.events.map((event) => event.key),
          everyElement('Google sign-in outcome'),
        );
        expect(analytics.events.map((event) => event.value), [
          {'outcome': 'started', 'platform': 'android'},
          {'outcome': code.name, 'platform': 'android'},
        ]);
        verifyNever(firebaseAuth.signInWithCredential(any));
      });
    }

    test('should count completed Firebase authentication', () async {
      final analytics = NoopAnalyticsService();
      GetIt.instance.registerSingleton<AnalyticsService>(analytics);
      await AuthService.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(analytics.events.last.value, {
        'outcome': 'success',
        'platform': 'android',
      });
    });

    test('should preserve sign-in when outcome analytics fails', () async {
      GetIt.instance.registerSingleton<AnalyticsService>(_FailingAnalytics());
      expect(await AuthService.signInWithGoogle(), same(firebaseCredential));
      await Future<void>.delayed(Duration.zero);
    });

    test('should cache synchronous initialization failures too', () async {
      when(googleSignIn.initialize(serverClientId: 'server-client'))
          .thenThrow(StateError('setup failed'));
      Object? cachedFailure;
      try {
        await AuthService.signInWithGoogle();
        fail('Initialization should fail');
      } on GoogleSignInInitializationFailure catch (error) {
        cachedFailure = error;
      }
      await expectLater(
        AuthService.signInWithGoogle(),
        throwsA(same(cachedFailure)),
      );
      verify(googleSignIn.initialize(serverClientId: 'server-client'))
          .called(1);
      verifyNever(googleSignIn.authenticate());
    });

    for (final code in [
      GoogleSignInExceptionCode.interrupted,
      GoogleSignInExceptionCode.uiUnavailable,
      GoogleSignInExceptionCode.clientConfigurationError,
      GoogleSignInExceptionCode.providerConfigurationError,
      GoogleSignInExceptionCode.unknownError,
      GoogleSignInExceptionCode.userMismatch,
    ]) {
      test(
        'should propagate interactive authentication failure $code',
        () async {
          final failure = GoogleSignInException(code: code);
          when(googleSignIn.authenticate()).thenThrow(failure);

          await expectLater(
            AuthService.signInWithGoogle(),
            throwsA(same(failure)),
          );

          verifyNever(firebaseAuth.signInWithCredential(any));
        },
      );
    }

    test(
      'should report interactive Android no-credential outcome as a failure',
      () async {
        const failure = GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'No credential available: no eligible account',
        );
        when(googleSignIn.authenticate()).thenThrow(failure);

        await expectLater(
          AuthService.signInWithGoogle(),
          throwsA(same(failure)),
        );

        verifyNever(firebaseAuth.signInWithCredential(any));
      },
    );

    test(
      'should allow a new authentication attempt after cancellation',
      () async {
        when(googleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        );
        expect(await AuthService.signInWithGoogle(), isNull);
        when(googleSignIn.authenticate()).thenAnswer((_) async => account);

        expect(await AuthService.signInWithGoogle(), same(firebaseCredential));

        verify(googleSignIn.initialize(serverClientId: 'server-client'))
            .called(1);
        verify(googleSignIn.authenticate()).called(2);
        verify(firebaseAuth.signInWithCredential(any)).called(1);
      },
    );

    test(
      'should keep initialization failures without reinitializing',
      () async {
        const failure = GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        );
        when(googleSignIn.initialize(serverClientId: 'server-client'))
            .thenAnswer((_) async => throw failure);

        await expectLater(
          AuthService.signInWithGoogle(),
          throwsA(
            isA<GoogleSignInInitializationFailure>().having(
              (error) => error.cause,
              'cause',
              same(failure),
            ),
          ),
        );
        await expectLater(
          AuthService.signInWithGoogle(),
          throwsA(
            isA<GoogleSignInInitializationFailure>().having(
              (error) => error.cause,
              'cause',
              same(failure),
            ),
          ),
        );

        verify(googleSignIn.initialize(serverClientId: 'server-client'))
            .called(1);
        verifyNever(googleSignIn.authenticate());
        verifyNever(firebaseAuth.signInWithCredential(any));
      },
    );

    test(
      'should allow Firebase sign-out after Google initialization fails',
      () async {
        const failure = GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        );
        when(googleSignIn.initialize(serverClientId: 'server-client'))
            .thenAnswer((_) async => throw failure);
        await expectLater(
          AuthService.signInWithGoogle(),
          throwsA(
            isA<GoogleSignInInitializationFailure>().having(
              (error) => error.cause,
              'cause',
              same(failure),
            ),
          ),
        );

        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);

        verifyNever(googleSignIn.signOut());
        verify(firebaseAuth.signOut()).called(1);
      },
    );

    test(
      'should report initialization once across cleanup and later sign-in',
      () async {
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        const failure = GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        );
        when(googleSignIn.initialize(serverClientId: 'server-client'))
            .thenAnswer((_) async => throw failure);
        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        try {
          await AuthService.signInWithGoogle();
          fail('Initialization should remain failed');
        } on GoogleSignInInitializationFailure catch (error) {
          await reportAuthenticationError(error, StackTrace.current);
        }
        await Future<void>.delayed(Duration.zero);
        verify(logger.captureLog(failure, stackTrace: anyNamed('stackTrace')))
            .called(1);
        verify(googleSignIn.initialize(serverClientId: 'server-client'))
            .called(1);
        verifyNever(googleSignIn.authenticate());
        verify(firebaseAuth.signOut()).called(2);
      },
    );

    for (final asynchronous in [false, true]) {
      test(
        'should retry a rejected initialization report (async: $asynchronous)',
        () async {
          final logger = _MockIncidentLoggerService();
          GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
          final cause = StateError('initialization failed');
          final originalStack = StackTrace.current;
          when(googleSignIn.initialize(serverClientId: 'server-client'))
              .thenAnswer((_) => Future<void>.error(cause, originalStack));
          when(logger.captureLog(cause, stackTrace: originalStack))
              .thenAnswer((_) {
                final failure = StateError('logger failed');
                if (asynchronous) return Future<void>.error(failure);
                throw failure;
              });

          await AuthService.signOut();
          await Future<void>.delayed(Duration.zero);
          verify(firebaseAuth.signOut()).called(1);

          when(logger.captureLog(cause, stackTrace: originalStack))
              .thenAnswer((_) async {});
          try {
            await AuthService.signInWithGoogle();
            fail('Initialization should remain failed');
          } on GoogleSignInInitializationFailure catch (error) {
            await reportAuthenticationError(error, StackTrace.current);
            await reportAuthenticationError(error, StackTrace.current);
          }

          verify(logger.captureLog(cause, stackTrace: originalStack)).called(2);
          verifyNever(googleSignIn.authenticate());
          verifyNever(firebaseAuth.signInWithCredential(any));
        },
      );
    }

    test(
      'should preserve Flutter fallback after a rejected cleanup report',
      () async {
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        final cause = StateError('initialization failed');
        final originalStack = StackTrace.current;
        when(googleSignIn.initialize(serverClientId: 'server-client'))
            .thenAnswer((_) => Future<void>.error(cause, originalStack));
        when(logger.captureLog(cause, stackTrace: originalStack))
            .thenAnswer((_) async => throw StateError('logger failed'));
        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        await GetIt.instance.unregister<IncidentLoggerService>();
        final reports = <FlutterErrorDetails>[];
        final originalHandler = FlutterError.onError;
        FlutterError.onError = reports.add;
        addTearDown(() => FlutterError.onError = originalHandler);

        try {
          await AuthService.signInWithGoogle();
          fail('Initialization should remain failed');
        } on GoogleSignInInitializationFailure catch (error) {
          await reportAuthenticationError(error, StackTrace.current);
          await reportAuthenticationError(error, StackTrace.current);
        }

        expect(reports, hasLength(1));
        expect(reports.single.exception, same(cause));
        expect(reports.single.stack, same(originalStack));
        verify(firebaseAuth.signOut()).called(1);
      },
    );

    test(
      'should skip the Google lifecycle when the provider is unavailable',
      () async {
        AuthService.debugGoogleSignInServerClientIdOverride = '';

        expect(await AuthService.signInWithGoogle(), isNull);

        verifyZeroInteractions(googleSignIn);
        verifyZeroInteractions(firebaseAuth);
      },
    );

    test('should clean up Google on sign-out after a cold start', () async {
      await AuthService.signOut();
      await Future<void>.delayed(Duration.zero);

      verify(firebaseAuth.signOut()).called(1);
      verify(googleSignIn.initialize(serverClientId: 'server-client'))
          .called(1);
      verify(googleSignIn.signOut()).called(1);
      verifyNever(googleSignIn.authenticate());
    });

    test(
      'should skip unconfigured Google cleanup after a cold start',
      () async {
        AuthService.debugGoogleSignInServerClientIdOverride = '';
        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        verifyZeroInteractions(googleSignIn);
        verify(firebaseAuth.signOut()).called(1);
      },
    );

    test(
      'should use the configured iOS client for cold-start sign-out',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        AuthService.debugGoogleSignInIosClientIdOverride = 'ios-client';
        AuthService.debugFirebaseIosClientIdOverride = 'ios-client';
        AuthService.debugFirebaseIosBundleIdOverride =
            'com.clubhouse.livingpositively';
        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        verify(
          googleSignIn.initialize(
            clientId: 'ios-client',
            serverClientId: 'server-client',
          ),
        ).called(1);
        verify(googleSignIn.signOut()).called(1);
        verifyNever(googleSignIn.authenticate());
        verify(firebaseAuth.signOut()).called(1);
      },
    );

    test(
      'should end the Firebase session before provider cleanup finishes',
      () async {
        await AuthService.signInWithGoogle();
        clearInteractions(firebaseAuth);
        final providerSignOut = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => providerSignOut.future);

        final signOut = AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        verify(googleSignIn.signOut()).called(1);
        verify(firebaseAuth.signOut()).called(1);

        providerSignOut.complete();
        await signOut;
        verifyNever(firebaseAuth.signOut());

        await AuthService.signInWithGoogle();
        verify(googleSignIn.initialize(serverClientId: 'server-client'))
            .called(1);
      },
    );
    test('should sign out Firebase when provider cleanup fails', () async {
      await AuthService.signInWithGoogle();
      const failure = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );
      when(googleSignIn.signOut()).thenThrow(failure);

      await AuthService.signOut();
      await Future<void>.delayed(Duration.zero);

      verify(firebaseAuth.signOut()).called(1);
    });

    test(
      'should propagate Firebase failure before provider cleanup',
      () async {
        await AuthService.signInWithGoogle();
        const googleFailure = GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        );
        final firebaseFailure = FirebaseAuthException(
          code: 'network-request-failed',
        );
        when(googleSignIn.signOut()).thenThrow(googleFailure);
        when(firebaseAuth.signOut()).thenThrow(firebaseFailure);

        await expectLater(
          AuthService.signOut(),
          throwsA(same(firebaseFailure)),
        );

        verify(firebaseAuth.signOut()).called(1);
      },
    );

    test(
      'should report repeated Android cancellations without analytics',
      () async {
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        when(googleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        );

        for (var attempt = 0; attempt < 2; attempt++) {
          expect(await AuthService.signInWithGoogle(), isNull);
        }
        verifyZeroInteractions(logger);
        for (var attempt = 0; attempt < 4; attempt++) {
          expect(await AuthService.signInWithGoogle(), isNull);
        }
        await Future<void>.delayed(Duration.zero);

        final incident = verify(
          logger.captureLog(captureAny, stackTrace: anyNamed('stackTrace')),
        ).captured.single;
        expect(incident, isA<StateError>());
        expect(
          incident.toString(),
          contains('Repeated Android Google sign-in cancellations'),
        );
        verifyNever(firebaseAuth.signInWithCredential(any));
      },
    );

    test(
      'should finish Firebase logout and clean up after late initialization',
      () async {
        final initialization = Completer<void>();
        when(googleSignIn.initialize(serverClientId: 'server-client'))
            .thenAnswer((_) => initialization.future);
        await AuthService.signOut().timeout(const Duration(seconds: 1));
        verify(firebaseAuth.signOut()).called(1);
        verifyNever(googleSignIn.signOut());
        initialization.complete();
        await Future<void>.delayed(Duration.zero);
        verify(googleSignIn.signOut()).called(1);
      },
    );

    test(
      'should defer new authentication until pending cleanup completes',
      () async {
        final cleanup = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => cleanup.future);
        await AuthService.signOut().timeout(const Duration(seconds: 1));
        final signIn = AuthService.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        verify(firebaseAuth.signOut()).called(1);
        verifyNever(googleSignIn.authenticate());
        cleanup.complete();
        expect(await signIn, same(firebaseCredential));
        verify(googleSignIn.authenticate()).called(1);
      },
    );

    test(
      'should cancel a pending initialization attempt when logout begins',
      () async {
        final initialized = Completer<void>();
        when(googleSignIn.initialize(serverClientId: 'server-client'))
            .thenAnswer((_) => initialized.future);
        final signIn = AuthService.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        await AuthService.signOut();
        initialized.complete();
        expect(await signIn, isNull);
        await Future<void>.delayed(Duration.zero);
        verifyNever(googleSignIn.authenticate());
        verifyNever(firebaseAuth.signInWithCredential(any));
        verify(googleSignIn.signOut()).called(1);
      },
    );

    test(
      'should block new Google authentication during Firebase logout',
      () async {
        final firebaseLogout = Completer<void>();
        when(firebaseAuth.signOut()).thenAnswer((_) => firebaseLogout.future);
        final signOut = AuthService.signOut();
        final signIn = AuthService.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        verifyNever(googleSignIn.authenticate());
        firebaseLogout.complete();
        await signOut;
        expect(await signIn, same(firebaseCredential));
        verifyInOrder([googleSignIn.signOut(), googleSignIn.authenticate()]);
      },
    );

    test(
      'should abort a new sign-in when its pending Firebase logout fails',
      () async {
        final firebaseLogout = Completer<void>();
        final failure = StateError('Firebase logout failed');
        when(firebaseAuth.signOut()).thenAnswer((_) => firebaseLogout.future);
        final signOut = expectLater(
          AuthService.signOut(),
          throwsA(same(failure)),
        );
        final signIn = expectLater(
          AuthService.signInWithGoogle(),
          throwsA(
            isA<GoogleSignInAborted>().having(
              (error) => error.outcome,
              'outcome',
              GoogleSignInAbortReason.cleanupPending,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        firebaseLogout.completeError(failure);
        await Future.wait([signOut, signIn]);
        verifyNever(googleSignIn.authenticate());
        verifyNever(firebaseAuth.signInWithCredential(any));
        when(firebaseAuth.signOut()).thenAnswer((_) async {});
        expect(await AuthService.signInWithGoogle(), same(firebaseCredential));
      },
    );

    test(
      'should clean up the provider after a successful overlapping logout',
      () async {
        final first = Completer<void>();
        final second = Completer<void>();
        var logouts = 0;
        when(firebaseAuth.signOut()).thenAnswer(
          (_) => ++logouts == 1 ? first.future : second.future,
        );
        final failure = StateError('first logout failed');
        final failedLogout = expectLater(
          AuthService.signOut(),
          throwsA(same(failure)),
        );
        final successfulLogout = AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        first.completeError(failure);
        await failedLogout;
        verifyNever(googleSignIn.signOut());
        second.complete();
        await successfulLogout;
        await Future<void>.delayed(Duration.zero);
        verify(googleSignIn.signOut()).called(1);
      },
    );

    test(
      'should fence success when logout starts after the exchange returns',
      () async {
        final lifecycle = GoogleAuthLifecycle();
        final sessionGeneration = lifecycle.sessionGeneration;
        final credential = lifecycle.exchange(
          () async => firebaseCredential,
          lifecycle.generation,
        );
        Future<void>? logout;
        unawaited(
          credential.then((_) {
            logout = lifecycle
                .startCleanup(
                  googleSignIn,
                  firebaseAuth.signOut,
                  () async {},
                )
                .firebase;
          }),
        );
        final published = credential.then((result) async {
          while (lifecycle.hasPendingFirebaseLogout) {
            await lifecycle.waitForFirebaseLogouts();
          }
          lifecycle.checkSession(sessionGeneration);
          return result;
        });
        await expectLater(published, throwsA(isA<GoogleSignInAborted>()));
        await logout;
      },
    );

    test(
      'should preserve an issued credential if a late logout fails',
      () async {
        final lifecycle = GoogleAuthLifecycle();
        final sessionGeneration = lifecycle.sessionGeneration;
        final firebaseLogout = Completer<void>();
        final failure = StateError('late logout failed');
        final credential = lifecycle.exchange(
          () async => firebaseCredential,
          lifecycle.generation,
        );
        Future<void>? failedLogout;
        unawaited(
          credential.then((_) {
            failedLogout = expectLater(
              lifecycle
                  .startCleanup(
                    googleSignIn,
                    () => firebaseLogout.future,
                    () async {},
                  )
                  .firebase,
              throwsA(same(failure)),
            );
          }),
        );
        var published = false;
        final handoff = credential.then((result) async {
          while (lifecycle.hasPendingFirebaseLogout) {
            await lifecycle.waitForFirebaseLogouts();
          }
          lifecycle.checkSession(sessionGeneration);
          published = true;
          return result;
        });
        await Future<void>.delayed(Duration.zero);
        expect(published, isFalse);
        firebaseLogout.completeError(failure);
        expect(await handoff, same(firebaseCredential));
        await failedLogout;
        verifyNever(googleSignIn.signOut());
      },
    );

    testWidgets(
      'should report a provider failure that arrives after cleanup times out',
      (tester) async {
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        final cleanup = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => cleanup.future);
        await AuthService.signOut();
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        final timeout = verify(
          logger.captureLog(captureAny, stackTrace: anyNamed('stackTrace')),
        ).captured.single;
        expect(timeout, isA<TimeoutException>());
        final failure = StateError('late provider failure');
        final stackTrace = StackTrace.current;
        cleanup.completeError(failure, stackTrace);
        await tester.pump();
        verify(logger.captureLog(failure, stackTrace: stackTrace)).called(1);
        verifyNoMoreInteractions(logger);
        expect(await AuthService.signInWithGoogle(), same(firebaseCredential));
        debugDefaultTargetPlatformOverride = null;
      },
    );

    test(
      'should serialize active authentication with cleanup and the next sign-in',
      () async {
        final selected = Completer<GoogleSignInAccount>();
        when(googleSignIn.authenticate()).thenAnswer((_) => selected.future);
        final oldSignIn = AuthService.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        await AuthService.signOut();
        final newSignIn = AuthService.signInWithGoogle();
        selected.complete(account);
        expect(await oldSignIn, isNull);
        expect(await newSignIn, same(firebaseCredential));
        verify(firebaseAuth.signInWithCredential(any)).called(1);
        verifyInOrder([
          googleSignIn.authenticate(),
          googleSignIn.signOut(),
          googleSignIn.authenticate(),
        ]);
      },
    );

    test(
      'should clear a new email session while provider cleanup is pending',
      () async {
        final cleanup = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => cleanup.future);
        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        when(
          firebaseAuth.signInWithEmailAndPassword(
            email: 'new@example.com',
            password: 'password',
          ),
        ).thenAnswer((_) async => firebaseCredential);
        await AuthService.signInWithEmail('new@example.com', 'password');
        await AuthService.signOut();
        verify(firebaseAuth.signOut()).called(2);
        verify(googleSignIn.signOut()).called(1);
        cleanup.complete();
        await Future<void>.delayed(Duration.zero);
      },
    );

    test(
      'should block authentication during a second pending Firebase logout',
      () async {
        final cleanup = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => cleanup.future);
        await AuthService.signOut();
        final cleared = Completer<void>();
        when(firebaseAuth.signOut()).thenAnswer((_) => cleared.future);
        final logout = AuthService.signOut();
        cleanup.complete();
        await Future<void>.delayed(Duration.zero);
        final signIn = AuthService.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        verifyNever(googleSignIn.authenticate());
        cleared.complete();
        await logout;
        expect(await signIn, same(firebaseCredential));
      },
    );

    test(
      'should drain an issued credential exchange before Firebase logout',
      () async {
        final exchanged = Completer<UserCredential>();
        when(firebaseAuth.signInWithCredential(any))
            .thenAnswer((_) => exchanged.future);
        final signIn = AuthService.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        final signOut = AuthService.signOut();
        verifyNever(firebaseAuth.signOut());
        exchanged.complete(firebaseCredential);
        expect(await signIn, isNull);
        await signOut;
        verify(firebaseAuth.signOut()).called(1);
      },
    );

    test(
      'should deliver an issued credential when Firebase logout fails',
      () async {
        final exchanged = Completer<UserCredential>();
        final failure = StateError('Firebase sign-out failed');
        when(firebaseAuth.signInWithCredential(any))
            .thenAnswer((_) => exchanged.future);
        when(firebaseAuth.signOut()).thenThrow(failure);
        final signIn = AuthService.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        final logout = expectLater(
          AuthService.signOut(),
          throwsA(same(failure)),
        );
        exchanged.complete(firebaseCredential);
        expect(await signIn, same(firebaseCredential));
        await logout;
        verifyNever(googleSignIn.signOut());
      },
    );

    testWidgets(
      'should deliver a late credential after logout times out',
      (tester) async {
        try {
          final exchanged = Completer<UserCredential>();
          User? currentUser;
          final authenticatedUser = MockUser();
          when(firebaseCredential.user).thenReturn(authenticatedUser);
          when(firebaseAuth.currentUser).thenAnswer((_) => currentUser);
          when(firebaseAuth.signInWithCredential(any)).thenAnswer((_) async {
            final credential = await exchanged.future;
            currentUser = credential.user;
            return credential;
          });
          when(firebaseAuth.signOut()).thenAnswer((_) async {
            currentUser = null;
          });
          final signIn = AuthService.signInWithGoogle();
          await tester.pump();
          final failedLogout = expectLater(
            AuthService.signOut(),
            throwsA(isA<TimeoutException>()),
          );
          await tester.pump(const Duration(seconds: 5));
          await failedLogout;
          verifyNever(firebaseAuth.signOut());
          exchanged.complete(firebaseCredential);
          await tester.pump();
          expect(await signIn, same(firebaseCredential));
          expect(firebaseAuth.currentUser, same(authenticatedUser));
          // Timeout must not schedule a stale Firebase logout after another login.
          verifyNever(firebaseAuth.signOut());
          await AuthService.signOut();
          await tester.pump();
          verify(firebaseAuth.signOut()).called(1);
          expect(firebaseAuth.currentUser, isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'should not time out cleanup while the account picker is still open',
      (tester) async {
        try {
          final logger = _MockIncidentLoggerService();
          GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
          final selected = Completer<GoogleSignInAccount>();
          when(googleSignIn.authenticate()).thenAnswer((_) => selected.future);
          final signIn = AuthService.signInWithGoogle();
          await tester.pump();
          await AuthService.signOut();
          await tester.pump(const Duration(seconds: 6));
          verifyZeroInteractions(logger);
          verifyNever(googleSignIn.signOut());
          selected.complete(account);
          await tester.pump();
          expect(await signIn, isNull);
          verify(googleSignIn.signOut()).called(1);
          verifyZeroInteractions(logger);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    test(
      'should not report Firebase failure through the cleanup observer',
      () async {
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        final failure = FirebaseAuthException(code: 'network-request-failed');
        when(firebaseAuth.signOut()).thenThrow(failure);
        await expectLater(AuthService.signOut(), throwsA(same(failure)));
        await Future<void>.delayed(Duration.zero);
        verifyZeroInteractions(logger);
        verifyNever(googleSignIn.signOut());
      },
    );

    test(
      'should allow sign-in after a pending provider cleanup fails',
      () async {
        final cleanup = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => cleanup.future);
        await AuthService.signOut();
        final signIn = AuthService.signInWithGoogle();
        cleanup.completeError(StateError('provider cleanup failed'));
        expect(await signIn, same(firebaseCredential));
      },
    );

    test(
      'should expose retry guidance and fail fast after cleanup wait expires',
      () async {
        final cleanup = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => cleanup.future);
        await AuthService.signOut();
        await expectLater(
          AuthService.signInWithGoogle(),
          throwsA(
            isA<GoogleSignInAborted>().having(
              (error) => error.outcome,
              'outcome',
              GoogleSignInAbortReason.cleanupPending,
            ),
          ),
        );
        await expectLater(
          AuthService.signInWithGoogle().timeout(const Duration(seconds: 1)),
          throwsA(
            isA<GoogleSignInAborted>().having(
              (error) => error.outcome,
              'outcome',
              GoogleSignInAbortReason.cleanupPending,
            ),
          ),
        );
        verifyNever(googleSignIn.authenticate());
        cleanup.complete();
        await Future<void>.delayed(Duration.zero);
        expect(await AuthService.signInWithGoogle(), same(firebaseCredential));
      },
    );

    test(
      'should classify native dismissal caused by logout as app cancellation',
      () async {
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        for (var i = 0; i < 3; i++) {
          final selected = Completer<GoogleSignInAccount>();
          when(googleSignIn.authenticate()).thenAnswer((_) => selected.future);
          final signIn = AuthService.signInWithGoogle();
          await Future<void>.delayed(Duration.zero);
          await AuthService.signOut();
          selected.completeError(
            const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled,
            ),
          );
          expect(await signIn, isNull);
          await Future<void>.delayed(Duration.zero);
        }
        verifyZeroInteractions(logger);
      },
    );

    test(
      'should exclude app interruptions and old dismissals from incidents',
      () async {
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        var now = DateTime(2026);
        googleAuthTelemetryClock = () => now;
        trackGoogleSignInOutcome('canceled');
        trackGoogleSignInOutcome('canceled');
        trackGoogleSignInOutcome('appCanceled');
        trackGoogleSignInOutcome('cleanupPending');
        now = now.add(const Duration(minutes: 6));
        trackGoogleSignInOutcome('canceled');
        trackGoogleSignInOutcome('canceled');
        await Future<void>.delayed(Duration.zero);
        verifyZeroInteractions(logger);
        trackGoogleSignInOutcome('canceled');
        await Future<void>.delayed(Duration.zero);
        verify(logger.captureLog(any, stackTrace: anyNamed('stackTrace')))
            .called(1);
      },
    );

    test(
      'should report provider cleanup failure with its stack trace',
      () async {
        await AuthService.signInWithGoogle();
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        const failure = GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        );
        when(googleSignIn.signOut()).thenThrow(failure);

        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);

        final stackTrace = verify(
          logger.captureLog(failure, stackTrace: captureAnyNamed('stackTrace')),
        ).captured.single;
        expect(stackTrace, isA<StackTrace>());
        verify(firebaseAuth.signOut()).called(1);
      },
    );

    test(
      'should sign out Firebase when cleanup failure reporting also fails',
      () async {
        await AuthService.signInWithGoogle();
        final logger = _MockIncidentLoggerService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        const failure = GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        );
        when(googleSignIn.signOut()).thenThrow(failure);
        when(logger.captureLog(failure, stackTrace: anyNamed('stackTrace')))
            .thenThrow(StateError('logger failed'));

        await AuthService.signOut();
        await Future<void>.delayed(Duration.zero);

        verify(firebaseAuth.signOut()).called(1);
      },
    );
  });
}
