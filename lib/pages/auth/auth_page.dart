import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/auth/forgot_password_page.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// ─── Shared mixin ─────────────────────────────────────────────────────────────

mixin _SocialSignIn<T extends StatefulWidget> on LPExtendedState<T> {
  Future<void> Function(User user) get _socialSuccessCallback;
  void _setSocialLoading(bool v);
  void _setSocialError(String? msg);

  Future<void> _signInWithGoogle() async {
    _setSocialLoading(true);
    _setSocialError(null);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result == null) {
        return;
      }
      final user = result.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Google authentication completed without a user.');
      }
      await _socialSuccessCallback(user);
    } catch (e) {
      if (mounted) _setSocialError(appLocale.authErrorGeneric);
    } finally {
      if (mounted) _setSocialLoading(false);
    }
  }

  Future<void> _signInWithApple() async {
    _setSocialLoading(true);
    _setSocialError(null);
    try {
      final result = await AuthService.signInWithApple();
      if (result == null) {
        return;
      }
      final user = result.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Apple authentication completed without a user.');
      }
      await _socialSuccessCallback(user);
    } catch (e) {
      if (mounted) _setSocialError(appLocale.authErrorGeneric);
    } finally {
      if (mounted) _setSocialLoading(false);
    }
  }

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
      debugPrint('Authenticated profile persistence failed: $error');
      if (!GetIt.instance.isRegistered<IncidentLoggerService>()) return;
      try {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (loggerError) {
        debugPrint(
          'Authenticated profile persistence reporting failed: $loggerError',
        );
      }
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              myText(
                appLocale.authWelcomeTitle,
                TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
                TextAlign.center,
              ),
              const SizedBox(height: 32),
              _ModeToggle(
                isLogin: _isLoginMode,
                loginLabel: appLocale.authLoginTab,
                signupLabel: appLocale.authSignupTab,
                onToggle: () => setState(() => _isLoginMode = !_isLoginMode),
              ),
              const SizedBox(height: 24),
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

class _LoginForm extends StatefulWidget {
  final bool fromNotifications;
  final Future<void> Function(User user) onSuccess;
  final VoidCallback onSkip;

  const _LoginForm({
    super.key,
    required this.fromNotifications,
    required this.onSuccess,
    required this.onSkip,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends LPExtendedState<_LoginForm>
    with _SocialSignIn<_LoginForm> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Future<void> Function(User) get _socialSuccessCallback => widget.onSuccess;
  @override
  void _setSocialLoading(bool v) => setState(() => _isLoading = v);
  @override
  void _setSocialError(String? msg) => setState(() => _errorMessage = msg);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await AuthService.signInWithEmail(email, password);
      final user = result.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Signed-in Firebase account has no user.');
      }
      await widget.onSuccess(user);
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = _resolveError(AuthService.localizedError(e)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //Email
        _AuthField(
          controller: _emailController,
          label: appLocale.authEmailHint,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        //Password
        _AuthField(
          controller: _passwordController,
          label: appLocale.authPasswordHint,
          icon: Icons.lock_outline,
          obscure: true,
        ),
        //Forgot Password Page
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: myText(
              appLocale.authForgotPassword,
              TextStyle(color: Theme.of(context).colorScheme.primary),
              TextAlign.start,
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          myText(
            _errorMessage!,
            TextStyle(color: Theme.of(context).colorScheme.error),
            TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        _AuthSubmitButton(
          label: appLocale.authLoginButton,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
        if (AuthService.isSocialSignInAvailable) ...[
          const SizedBox(height: 24),
          //Gray Divider
          _OrDivider(label: appLocale.authOr),
          const SizedBox(height: 16),
          if (AuthService.isGoogleSignInAvailable)
            //Sign with Google Button
            _SocialButton(
              label: appLocale.authGoogleButton,
              icon: Icons.g_mobiledata,
              onPressed: _isLoading ? null : _signInWithGoogle,
            ),
          if (AuthService.isAppleSignInAvailable) ...[
            if (AuthService.isGoogleSignInAvailable) const SizedBox(height: 10),
            //Sign with AppleID button
            _SocialButton(
              label: appLocale.authAppleButton,
              icon: Icons.apple,
              onPressed: _isLoading ? null : _signInWithApple,
            ),
          ],
        ],
        const SizedBox(height: 24),
        //Skip Button options
        if (!widget.fromNotifications)
          TextButton(
            onPressed: _isLoading ? null : widget.onSkip,
            child: myText(
              appLocale.authSkip,
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              TextAlign.center,
            ),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: myText(
              appLocale.closeButton(''),
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Signup Form ──────────────────────────────────────────────────────────────

class _SignupForm extends StatefulWidget {
  final bool fromNotifications;
  final Future<void> Function(User user) onSuccess;
  final VoidCallback onSkip;

  const _SignupForm({
    super.key,
    required this.fromNotifications,
    required this.onSuccess,
    required this.onSkip,
  });

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends LPExtendedState<_SignupForm>
    with _SocialSignIn<_SignupForm> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Future<void> Function(User) get _socialSuccessCallback => widget.onSuccess;
  @override
  void _setSocialLoading(bool v) => setState(() => _isLoading = v);
  @override
  void _setSocialError(String? msg) => setState(() => _errorMessage = msg);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    if (password != _confirmPasswordController.text) {
      setState(() => _errorMessage = appLocale.authErrorPasswordMismatch);
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = appLocale.authErrorWeakPassword);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await AuthService.signUpWithEmail(email, password);
      if (_nameController.text.trim().isNotEmpty) {
        try {
          await result.user?.updateDisplayName(_nameController.text.trim());
          await result.user?.reload();
        } catch (error, stackTrace) {
          // The Firebase account already exists at this point. A best-effort
          // profile update must not strand the user at a non-retryable
          // email-already-in-use sign-up form.
          if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
            unawaited(
              Future<void>.sync(
                () => GetIt.instance<IncidentLoggerService>().captureLog(
                  error,
                  stackTrace: stackTrace,
                ),
              ).catchError((Object _, StackTrace _) {}),
            );
          }
        }
      }
      final user = result.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Created Firebase account has no user.');
      }
      await widget.onSuccess(user);
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = _resolveError(AuthService.localizedError(e)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //Name
        _AuthField(
          controller: _nameController,
          label: appLocale.authNameHint,
          icon: Icons.person_outline,
        ),
        //Email
        _AuthField(
          controller: _emailController,
          label: appLocale.authEmailHint,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        //Password
        _AuthField(
          controller: _passwordController,
          label: appLocale.authPasswordHint,
          icon: Icons.lock_outline,
          obscure: true,
        ),
        //Confirm Password
        _AuthField(
          controller: _confirmPasswordController,
          label: appLocale.authConfirmPasswordHint,
          icon: Icons.lock_outline,
          obscure: true,
        ),
        if (_errorMessage != null) ...[
          myText(
            _errorMessage!,
            TextStyle(color: Theme.of(context).colorScheme.error),
            TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        _AuthSubmitButton(
          label: appLocale.authSignupButton,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
        if (AuthService.isSocialSignInAvailable) ...[
          const SizedBox(height: 24),
          //Gray Divider
          _OrDivider(label: appLocale.authOr),
          const SizedBox(height: 16),
          if (AuthService.isGoogleSignInAvailable)
            //Sign with Google Button
            _SocialButton(
              label: appLocale.authGoogleButton,
              icon: Icons.g_mobiledata,
              onPressed: _isLoading ? null : _signInWithGoogle,
            ),
          if (AuthService.isAppleSignInAvailable) ...[
            if (AuthService.isGoogleSignInAvailable) const SizedBox(height: 10),
            //Sign with AppleID Button
            _SocialButton(
              label: appLocale.authAppleButton,
              icon: Icons.apple,
              onPressed: _isLoading ? null : _signInWithApple,
            ),
          ],
        ],
        const SizedBox(height: 24),
        //Skip Button options
        if (!widget.fromNotifications)
          TextButton(
            onPressed: _isLoading ? null : widget.onSkip,
            child: myText(
              appLocale.authSkip,
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              TextAlign.center,
            ),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: myText(
              appLocale.closeButton(''),
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _AuthSubmitButton extends StatelessWidget {
  const _AuthSubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: formFieldWidth(context),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: primaryButtonStyle(context).copyWith(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : myText(
                label,
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                TextAlign.center,
              ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isLogin;
  final String loginLabel;
  final String signupLabel;
  final VoidCallback onToggle;

  const _ModeToggle({
    required this.isLogin,
    required this.loginLabel,
    required this.signupLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _Tab(
            label: loginLabel,
            selected: isLogin,
            onTap: isLogin ? null : onToggle,
          ),
          _Tab(
            label: signupLabel,
            selected: !isLogin,
            onTap: isLogin ? onToggle : null,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _Tab({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: myText(
            label,
            TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            ),
            TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: formFieldWidth(context),
          child: DecoratedBox(
            decoration: formFieldShadowDecoration(),
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              autocorrect: false,
              decoration: formFieldInputDecoration(
                context,
              ).copyWith(labelText: label, prefixIcon: Icon(icon)),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: myText(
            label,
            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            TextAlign.center,
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
