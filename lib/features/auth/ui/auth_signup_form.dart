part of '../../../pages/auth_page.dart';

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
          await reportAuthenticationError(error, stackTrace);
        }
      }
      final user = result.user ?? AuthService.currentUser;
      if (user == null) {
        throw StateError('Created Firebase account has no user.');
      }
      await widget.onSuccess(user);
    } catch (error, stackTrace) {
      await reportAuthenticationError(error, stackTrace);
      if (mounted) {
        setState(
          () =>
              _errorMessage = _resolveError(AuthService.localizedError(error)),
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
        _AuthField(
          controller: _nameController,
          label: appLocale.authNameHint,
          icon: Icons.person_outline,
        ),
        _AuthField(
          controller: _emailController,
          label: appLocale.authEmailHint,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        _AuthField(
          controller: _passwordController,
          label: appLocale.authPasswordHint,
          icon: Icons.lock_outline,
          obscure: true,
        ),
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
          const SizedBox(height: AppSpacing.sm),
        ],
        _AuthSubmitButton(
          label: appLocale.authSignupButton,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
        if (AuthService.isSocialSignInAvailable) ...[
          const SizedBox(height: AppSpacing.xxl),
          _OrDivider(label: appLocale.authOr),
          const SizedBox(height: AppSpacing.lg),
          if (AuthService.isGoogleSignInAvailable)
            _SocialButton(
              label: appLocale.authGoogleButton,
              icon: Icons.g_mobiledata,
              onPressed: _isLoading ? null : _signInWithGoogle,
            ),
          if (AuthService.isAppleSignInAvailable) ...[
            if (AuthService.isGoogleSignInAvailable)
              const SizedBox(height: AppSpacing.md),
            _SocialButton(
              label: appLocale.authAppleButton,
              icon: Icons.apple,
              onPressed: _isLoading ? null : _signInWithApple,
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.xxl),
        if (!widget.fromNotifications)
          Button(
            onPressed: _isLoading ? null : widget.onSkip,
            label: appLocale.authSkip,
            variant: ButtonVariant.secondary,
          )
        else
          Button(
            onPressed: () => Navigator.pop(context),
            label: appLocale.closeButton(''),
            variant: ButtonVariant.secondary,
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
