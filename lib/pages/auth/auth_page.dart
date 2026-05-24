import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mazilon/pages/auth/forgot_password_page.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
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
        _setSocialLoading(false);
        return;
      }
      if (mounted) await _socialSuccessCallback(result.user!);
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
        _setSocialLoading(false);
        return;
      }
      if (mounted) await _socialSuccessCallback(result.user!);
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
      case 'authErrorWrongPassword':
        return appLocale.authErrorWrongPassword;
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

  Future<void> _onAuthSuccess(User user) async {
    final userInfo = Provider.of<UserInformation>(context, listen: false);
    await AuthService.saveUserToFirestore(user);
    await FcmService.onUserSignedIn();

    userInfo.updateLoggedIn(true);
    userInfo.updateUserId(user.uid);
    userInfo.updateEmail(user.email ?? '');
    userInfo.updateDisplayName(user.displayName ?? '');

    if (widget.fromNotifications) {
      if (mounted) Navigator.pop(context);
    } else {
      userInfo.updateAuthDecisionMade(true);
    }
  }

  void _onSkip() {
    final userInfo = Provider.of<UserInformation>(context, listen: false);
    userInfo.updateAuthDecisionMade(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                appLocale.authWelcomeTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
                textAlign: TextAlign.center,
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
                        fromNotifications: widget.fromNotifications,
                        onSuccess: _onAuthSuccess,
                        onSkip: _onSkip,
                      )
                    : _SignupForm(
                        key: const ValueKey('signup'),
                        fromNotifications: widget.fromNotifications,
                        onSuccess: _onAuthSuccess,
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
      final user = result.user ?? FirebaseAuth.instance.currentUser!;
      if (mounted) await widget.onSuccess(user);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _resolveError(AuthService.localizedError(e)));
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
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
            ),
            child: Text(appLocale.authForgotPassword,
                style: TextStyle(color: primaryPurple)),
          ),
        ),
        if (_errorMessage != null) ...[
          Text(_errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
        ],
        //Sign In Button
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(appLocale.authLoginButton,
                  style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 24),
        //Gray Divider
        _OrDivider(label: appLocale.authOr),
        const SizedBox(height: 16),
        //Sign with Google Button
        _SocialButton(
          label: appLocale.authGoogleButton,
          icon: Icons.g_mobiledata,
          onPressed: _isLoading ? null : _signInWithGoogle,
        ),
        if (!kIsWeb && Platform.isIOS) ...[
          const SizedBox(height: 10),
          //Sign with AppleID button
          _SocialButton(
            label: appLocale.authAppleButton,
            icon: Icons.apple,
            onPressed: _isLoading ? null : _signInWithApple,
          ),
        ],
        const SizedBox(height: 24),
        //Skip Button options
        if (!widget.fromNotifications)
          TextButton(
            onPressed: _isLoading ? null : widget.onSkip,
            child: Text(appLocale.authSkip,
                style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocale.closeButton(''),
                style: TextStyle(color: Colors.grey.shade600)),
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
        await result.user?.updateDisplayName(_nameController.text.trim());
        await result.user?.reload();
      }
      final user = FirebaseAuth.instance.currentUser!;
      if (mounted) await widget.onSuccess(user);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _resolveError(AuthService.localizedError(e)));
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
          Text(_errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
        ],
        //Sign Up Button
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(appLocale.authSignupButton,
                  style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 24),
        //Gray Divider
        _OrDivider(label: appLocale.authOr),
        const SizedBox(height: 16),
        //Sign with Google Button
        _SocialButton(
          label: appLocale.authGoogleButton,
          icon: Icons.g_mobiledata,
          onPressed: _isLoading ? null : _signInWithGoogle,
        ),
        if (!kIsWeb && Platform.isIOS) ...[
          const SizedBox(height: 10),
          //Sign with AppleID Button
          _SocialButton(
            label: appLocale.authAppleButton,
            icon: Icons.apple,
            onPressed: _isLoading ? null : _signInWithApple,
          ),
        ],
        const SizedBox(height: 24),
        //Skip Button options
        if (!widget.fromNotifications)
          TextButton(
            onPressed: _isLoading ? null : widget.onSkip,
            child: Text(appLocale.authSkip,
                style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocale.closeButton(''),
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _Tab(
            label: loginLabel,
            selected: isLogin,
            onTap: isLogin ? null : onToggle),
        _Tab(
            label: signupLabel,
            selected: !isLogin,
            onTap: isLogin ? onToggle : null),
      ]),
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
            color: selected ? primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
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
    return Column(children: [
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: const TextStyle(color: Colors.grey)),
      ),
      const Expanded(child: Divider()),
    ]);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
        foregroundColor: Colors.black87,
      ),
    );
  }
}
