part of '../../../pages/auth_page.dart';

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
      final user = result.user ?? GetIt.instance<FirebaseAuth>().currentUser;
      if (user == null) {
        throw StateError('Signed-in Firebase account has no user.');
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
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Button(
            label: appLocale.authForgotPassword,
            variant: ButtonVariant.secondary,
            fullWidth: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
            ),
          ),
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
          label: appLocale.authLoginButton,
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

// ─── Signup Form ──────────────────────────────────────────────────────────────
