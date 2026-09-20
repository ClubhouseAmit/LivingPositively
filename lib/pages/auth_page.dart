import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/auth/ui/auth_error_reporting.dart';
import 'package:mazilon/pages/forgot_password_page.dart';
import 'package:mazilon/features/auth/data/auth_repository.dart';
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/design_system/widgets/text.dart' as design;
import 'package:provider/provider.dart';

part '../features/auth/ui/auth_login_form.dart';
part '../features/auth/ui/auth_signup_form.dart';
part '../features/auth/ui/auth_form_widgets.dart';

@visibleForTesting
bool isSocialSignInCancellation(Object error) =>
    error is FirebaseAuthException &&
    (error.code == 'canceled' || error.code == 'web-context-canceled');

// ─── Shared mixin ─────────────────────────────────────────────────────────────

mixin _SocialSignIn<T extends StatefulWidget> on LPExtendedState<T> {
  Future<void> Function(User user) get _socialSuccessCallback;
  void _setSocialLoading(bool v);
  void _setSocialError(String? msg);

  Future<void> _runSocialSignIn(
    Future<UserCredential?> Function() signIn,
    String providerName,
  ) async {
    _setSocialLoading(true);
    _setSocialError(null);
    try {
      final result = await signIn();
      if (result == null) {
        return;
      }
      final user = result.user ?? GetIt.instance<FirebaseAuth>().currentUser;
      if (user == null) {
        throw StateError(
          '$providerName authentication completed without a user.',
        );
      }
      await _socialSuccessCallback(user);
    } catch (error, stackTrace) {
      if (isSocialSignInCancellation(error)) {
        return;
      }
      await reportAuthenticationError(error, stackTrace);
      if (mounted) _setSocialError(appLocale.authErrorGeneric);
    } finally {
      if (mounted) _setSocialLoading(false);
    }
  }

  Future<void> _signInWithGoogle() =>
      _runSocialSignIn(AuthService.signInWithGoogle, 'Google');

  Future<void> _signInWithApple() =>
      _runSocialSignIn(AuthService.signInWithApple, 'Apple');

  String _resolveError(String? key) {
    switch (key) {
      case 'authErrorInvalidEmail':
        return appLocale.authErrorInvalidEmail;
      case 'authErrorWeakPassword':
        return appLocale.authErrorWeakPassword;
      case 'authErrorUserNotFound':
        return appLocale.authErrorUserNotFound;
      case 'authErrorEmailInUse':
        return appLocale.authErrorEmailInUse;
      default:
        return appLocale.authErrorGeneric;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AuthPage extends StatefulWidget {
  // When true: shown from inside the app (notifications page).
  // Shows a back/cancel option instead of skip; pops on success.
  // When false (default): shown during onboarding flow.
  // Shows skip option; updates authDecisionMade on success/skip.
  final bool fromNotifications;

  const AuthPage({super.key, this.fromNotifications = false});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends LPExtendedState<AuthPage> {
  bool _isLoginMode = true;

  Future<void> _onAuthSuccess(
    User user,
    UserInformation userInfo, {
    required bool fromNotifications,
  }) async {
    userInfo.updateLoggedIn(true);
    userInfo.updateUserId(user.uid);
    userInfo.updateEmail(user.email ?? '');
    userInfo.updateDisplayName(user.displayName ?? '');

    if (fromNotifications) {
      if (mounted) Navigator.pop(context);
    } else {
      userInfo.updateAuthDecisionMade(true);
    }

    unawaited(_persistAuthenticatedUser(user));
    unawaited(
      FcmScheduledNotificationService.migrateLegacyDefaultReminderWithReporting(
        userInformation: userInfo,
      ),
    );
    unawaited(FcmService.onUserSignedIn());
  }

  Future<void> _persistAuthenticatedUser(User user) async {
    try {
      await AuthService.saveUserToFirestore(user);
    } catch (error, stackTrace) {
      await reportAuthenticationError(error, stackTrace);
    }
  }

  void _onSkip() {
    final userInfo = Provider.of<UserInformation>(context, listen: false);
    userInfo.updateAuthDecisionMade(true);
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserInformation>(context, listen: false);
    final fromNotifications = widget.fromNotifications;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              myText(
                appLocale.authWelcomeTitle,
                TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
                TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              _ModeToggle(
                isLogin: _isLoginMode,
                loginLabel: appLocale.authLoginTab,
                signupLabel: appLocale.authSignupTab,
                onToggle: () => setState(() => _isLoginMode = !_isLoginMode),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoginMode
                    ? _LoginForm(
                        key: const ValueKey('login'),
                        fromNotifications: fromNotifications,
                        onSuccess: (user) => _onAuthSuccess(
                          user,
                          userInfo,
                          fromNotifications: fromNotifications,
                        ),
                        onSkip: _onSkip,
                      )
                    : _SignupForm(
                        key: const ValueKey('signup'),
                        fromNotifications: fromNotifications,
                        onSuccess: (user) => _onAuthSuccess(
                          user,
                          userInfo,
                          fromNotifications: fromNotifications,
                        ),
                        onSkip: _onSkip,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Form ───────────────────────────────────────────────────────────────
