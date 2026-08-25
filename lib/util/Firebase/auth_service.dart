import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mazilon/util/Firebase/firebase_options.dart';

typedef GoogleSignInStarter =
    Future<GoogleSignInAccount?> Function({
      required String serverClientId,
      String? clientId,
    });

class AuthService {
  static const String _runnerIosBundleId = 'com.clubhouse.livingpositively';
  static const String _googleSignInServerClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
    defaultValue: '',
  );
  static const String _googleSignInIosClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_IOS_CLIENT_ID',
    defaultValue: '',
  );
  static const bool _appleSignInEnabled = bool.fromEnvironment(
    'APPLE_SIGN_IN_ENABLED',
    defaultValue: false,
  );

  /// Test-only override for the Apple Sign-In compile-time flag.
  @visibleForTesting
  static bool? debugAppleSignInEnabledOverride;

  /// Test-only override for the Google server client ID.
  @visibleForTesting
  static String? debugGoogleSignInServerClientIdOverride;

  @visibleForTesting
  static String? debugGoogleSignInIosClientIdOverride;

  @visibleForTesting
  static String? debugFirebaseIosClientIdOverride;

  @visibleForTesting
  static String? debugFirebaseIosBundleIdOverride;

  @visibleForTesting
  static GoogleSignInStarter? debugGoogleSignInStarterOverride;

  static String get _configuredGoogleSignInServerClientId =>
      (debugGoogleSignInServerClientIdOverride ?? _googleSignInServerClientId)
          .trim();

  static String get _configuredGoogleSignInIosClientId =>
      (debugGoogleSignInIosClientIdOverride ?? _googleSignInIosClientId).trim();

  static String get _configuredFirebaseIosClientId =>
      (debugFirebaseIosClientIdOverride ??
              DefaultFirebaseOptions.ios.iosClientId ??
              '')
          .trim();

  static String get _configuredFirebaseIosBundleId =>
      (debugFirebaseIosBundleIdOverride ??
              DefaultFirebaseOptions.ios.iosBundleId ??
              '')
          .trim();

  static Future<UserCredential> signInWithEmail(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> signUpWithEmail(String email, String password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential?> signInWithGoogle() async {
    final serverClientId = _configuredGoogleSignInServerClientId;
    final iosClientId = _configuredGoogleSignInIosClientId;
    if (!isGoogleSignInAvailable) return null;
    final clientId = defaultTargetPlatform == TargetPlatform.iOS
        ? iosClientId
        : null;
    final startGoogleSignIn = debugGoogleSignInStarterOverride;
    final googleUser = startGoogleSignIn == null
        ? await GoogleSignIn(
            clientId: clientId,
            serverClientId: serverClientId,
          ).signIn()
        : await startGoogleSignIn(
            clientId: clientId,
            serverClientId: serverClientId,
          );
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

  /// Whether Google Sign-In can be offered for the supplied platform and
  /// configuration.
  ///
  /// Google is unavailable on web and without a server client ID. iOS also
  /// requires matching configured and Firebase iOS client IDs for this app's
  /// bundle ID. Unsupported or incomplete configurations return `false`.
  @visibleForTesting
  static bool googleSignInAvailableOn(
    TargetPlatform platform, {
    required bool isWeb,
    required String serverClientId,
    required String iosClientId,
    required String firebaseIosClientId,
    required String firebaseIosBundleId,
  }) {
    if (isWeb || serverClientId.trim().isEmpty) return false;
    return switch (platform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS =>
        iosClientId.trim().isNotEmpty &&
            iosClientId.trim() == firebaseIosClientId.trim() &&
            firebaseIosBundleId.trim() == _runnerIosBundleId,
      _ => false,
    };
  }

  /// Whether Apple Sign-In can be offered for the supplied platform and flag.
  ///
  /// Apple is available only in non-web iOS builds with the compile-time
  /// capability flag enabled. Unsupported configurations return `false`.
  @visibleForTesting
  static bool appleSignInAvailableOn(
    TargetPlatform platform, {
    required bool isWeb,
    required bool appleSignInEnabled,
  }) => !isWeb && platform == TargetPlatform.iOS && appleSignInEnabled;

  /// Whether the current build can offer Google Sign-In.
  ///
  /// Returns `false` when its platform or native configuration is unsupported.
  static bool get isGoogleSignInAvailable => googleSignInAvailableOn(
    defaultTargetPlatform,
    isWeb: kIsWeb,
    serverClientId: _configuredGoogleSignInServerClientId,
    iosClientId: _configuredGoogleSignInIosClientId,
    firebaseIosClientId: _configuredFirebaseIosClientId,
    firebaseIosBundleId: _configuredFirebaseIosBundleId,
  );

  /// Whether the current build can offer Apple Sign-In.
  ///
  /// Returns `false` unless this is a capability-enabled iOS build.
  static bool get isAppleSignInAvailable => appleSignInAvailableOn(
    defaultTargetPlatform,
    isWeb: kIsWeb,
    appleSignInEnabled: debugAppleSignInEnabledOverride ?? _appleSignInEnabled,
  );

  /// Whether at least one configured social provider is available to this build.
  static bool get isSocialSignInAvailable =>
      isGoogleSignInAvailable || isAppleSignInAvailable;

  static Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() {
    if (GetIt.instance.isRegistered<FirebaseAuth>()) {
      return GetIt.instance<FirebaseAuth>().signOut();
    }
    return FirebaseAuth.instance.signOut();
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
