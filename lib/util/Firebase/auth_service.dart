import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        debugPrint,
        defaultTargetPlatform,
        kIsWeb,
        visibleForTesting;
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String _googleSignInServerClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
    defaultValue: '',
  );
  static const bool _appleSignInEnabled = bool.fromEnvironment(
    'APPLE_SIGN_IN_ENABLED',
    defaultValue: false,
  );

  @visibleForTesting
  static bool? debugAppleSignInEnabledOverride;

  @visibleForTesting
  static String? debugGoogleSignInServerClientIdOverride;

  static String get _configuredGoogleSignInServerClientId =>
      (debugGoogleSignInServerClientIdOverride ?? _googleSignInServerClientId)
          .trim();

  static Future<UserCredential> signInWithEmail(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> signUpWithEmail(String email, String password) {
    debugPrint("gotten here");
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential?> signInWithGoogle() async {
    final serverClientId = _configuredGoogleSignInServerClientId;
    if (!isGoogleSignInAvailable) return null;
    final googleUser = await GoogleSignIn(
      serverClientId: serverClientId,
    ).signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  // Apple Sign In is only available on iOS.
  static Future<UserCredential?> signInWithApple() async {
    if (!isAppleSignInAvailable) return null;

    final appleProvider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    return FirebaseAuth.instance.signInWithProvider(appleProvider);
  }

  @visibleForTesting
  static bool googleSignInAvailableOn(
    TargetPlatform platform, {
    required bool isWeb,
    required String serverClientId,
  }) =>
      !isWeb &&
      platform == TargetPlatform.android &&
      serverClientId.trim().isNotEmpty;

  @visibleForTesting
  static bool appleSignInAvailableOn(
    TargetPlatform platform, {
    required bool isWeb,
    required bool appleSignInEnabled,
  }) => !isWeb && platform == TargetPlatform.iOS && appleSignInEnabled;

  static bool get isGoogleSignInAvailable => googleSignInAvailableOn(
    defaultTargetPlatform,
    isWeb: kIsWeb,
    serverClientId: _configuredGoogleSignInServerClientId,
  );

  static bool get isAppleSignInAvailable => appleSignInAvailableOn(
    defaultTargetPlatform,
    isWeb: kIsWeb,
    appleSignInEnabled: debugAppleSignInEnabledOverride ?? _appleSignInEnabled,
  );

  static bool get isSocialSignInAvailable =>
      isGoogleSignInAvailable || isAppleSignInAvailable;

  static Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  // Called after any successful sign-in to persist the user in Firestore.
  //Saving the user data in our own managed part of FireStore
  static Future<void> saveUserToFirestore(User user) async {
    final docRef = GetIt.instance<FirebaseFirestore>()
        .collection('users')
        .doc(user.uid);
    final doc = await docRef.get();
    final data = <String, dynamic>{
      'email': user.email,
      'displayName': user.displayName,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password',
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    if (!doc.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await docRef.set(data, SetOptions(merge: true));
  }

  static String? localizedError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'authErrorInvalidEmail';
        case 'weak-password':
          return 'authErrorWeakPassword';
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'authErrorUserNotFound';
        case 'email-already-in-use':
          return 'authErrorEmailInUse';
        default:
          return 'authErrorGeneric';
      }
    }
    return 'authErrorGeneric';
  }
}
