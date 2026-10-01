import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mazilon/features/auth/data/auth_repository.dart';
import 'package:mazilon/features/auth/data/google_auth_models.dart';
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
        await AuthService.signOut();
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
      'should await provider sign-out before ending the Firebase session',
      () async {
        await AuthService.signInWithGoogle();
        clearInteractions(firebaseAuth);
        final providerSignOut = Completer<void>();
        when(googleSignIn.signOut()).thenAnswer((_) => providerSignOut.future);

        final signOut = AuthService.signOut();
        await Future<void>.delayed(Duration.zero);
        verify(googleSignIn.signOut()).called(1);
        verifyNever(firebaseAuth.signOut());

        providerSignOut.complete();
        await signOut;
        verify(firebaseAuth.signOut()).called(1);

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

      verify(firebaseAuth.signOut()).called(1);
    });

    test(
      'should propagate Firebase failure after provider cleanup fails',
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

        verify(firebaseAuth.signOut()).called(1);
      },
    );
  });
}
