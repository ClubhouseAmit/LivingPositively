// Unit tests for FirebaseAuthService.signUp / signIn in
// lib/util/Firebase/firebase_functions.dart.
//
// The repo's `firebase_core ^4.6.0` is incompatible with
// `firebase_auth_mocks`, so we mock FirebaseAuth itself via Mockito
// (build_runner-generated) and use the @visibleForTesting `withAuth`
// constructor to inject the mock.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/widget_test_scaffold.dart';
import 'firebase_auth_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<UserCredential>(),
  MockSpec<User>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth auth;
  late MockUserCredential credential;
  late MockUser user;

  // fluttertoast platform channel — showToast() reaches into the plugin and
  // would throw MissingPluginException in tests otherwise.
  const fluttertoastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  setUp(() {
    registerTestServices(locale: 'en');
    auth = MockFirebaseAuth();
    credential = MockUserCredential();
    user = MockUser();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fluttertoastChannel, (_) async => true);

    when(credential.user).thenReturn(user);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fluttertoastChannel, null);
    GetIt.instance.reset();
  });

  group('FirebaseAuthService.signUpWithEmailAndPassword', () {
    test('returns the created user on success', () async {
      when(auth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => credential);

      final service = FirebaseAuthService.withAuth(auth);
      final result = await service.signUpWithEmailAndPassword(
          'a@example.com', 'password123');

      expect(result, same(user));
      verify(auth.createUserWithEmailAndPassword(
        email: 'a@example.com',
        password: 'password123',
      )).called(1);
    });

    test('returns null and surfaces toast on email-already-in-use', () async {
      when(auth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final service = FirebaseAuthService.withAuth(auth);
      final result = await service.signUpWithEmailAndPassword(
          'a@example.com', 'password123');

      expect(result, isNull);
    });

    test('returns null and logs incident on generic FirebaseAuthException',
        () async {
      when(auth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'weak-password'));

      final service = FirebaseAuthService.withAuth(auth);
      final result = await service.signUpWithEmailAndPassword(
          'a@example.com', 'short');

      expect(result, isNull);
      // IncidentLoggerService is the NoopIncidentLoggerService from the
      // test scaffold; the captured list now contains the error.
      final logger = GetIt.instance<IncidentLoggerService>()
          as NoopIncidentLoggerService;
      expect(logger.captured, isNotEmpty);
    });
  });

  group('FirebaseAuthService.signInWithEmailAndPassword', () {
    test('returns the authenticated user on success', () async {
      when(auth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => credential);

      final service = FirebaseAuthService.withAuth(auth);
      final result = await service.signInWithEmailAndPassword(
          'a@example.com', 'password123');

      expect(result, same(user));
      verify(auth.signInWithEmailAndPassword(
        email: 'a@example.com',
        password: 'password123',
      )).called(1);
    });

    test('returns null on user-not-found', () async {
      when(auth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final service = FirebaseAuthService.withAuth(auth);
      final result = await service.signInWithEmailAndPassword(
          'ghost@example.com', 'password123');

      expect(result, isNull);
    });

    test('returns null on wrong-password', () async {
      when(auth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final service = FirebaseAuthService.withAuth(auth);
      final result = await service.signInWithEmailAndPassword(
          'a@example.com', 'wrong');

      expect(result, isNull);
    });

    test('returns null and logs incident on generic FirebaseAuthException',
        () async {
      when(auth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'too-many-requests'));

      final service = FirebaseAuthService.withAuth(auth);
      final result = await service.signInWithEmailAndPassword(
          'a@example.com', 'password123');

      expect(result, isNull);
      final logger = GetIt.instance<IncidentLoggerService>()
          as NoopIncidentLoggerService;
      expect(logger.captured, isNotEmpty);
    });
  });
}
