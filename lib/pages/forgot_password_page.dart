import 'package:flutter/material.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/features/auth/data/auth_repository.dart';
import 'package:mazilon/features/auth/ui/auth_error_reporting.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/styles.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends LPExtendedState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = appLocale.authErrorInvalidEmail);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } catch (error, stackTrace) {
      await reportAuthenticationError(error, stackTrace);
      if (mounted) {
        final key = AuthService.localizedError(error);
        if (key == 'authErrorUserNotFound') {
          // Keep the reset flow indistinguishable for unknown accounts.
          setState(() => _sent = true);
        } else {
          setState(
            () => _errorMessage = switch (key) {
              'authErrorInvalidEmail' => appLocale.authErrorInvalidEmail,
              _ => appLocale.authErrorGeneric,
            },
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appWhite,
      appBar: AppBar(
        backgroundColor: appWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryPurple),
        title: Text(
          appLocale.authForgotPasswordTitle,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: _sent
            ? _SuccessView(appLocale.authForgotPasswordSuccess)
            : _FormView(
                emailController: _emailController,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onSend: _send,
                appLocale: appLocale,
              ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String message;
  const _SuccessView(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.green),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSend;
  final dynamic appLocale;

  const _FormView({
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSend,
    required this.appLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Text(
          appLocale.authForgotPasswordHint,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: appLocale.authEmailHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
            ),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: AppSpacing.xxl),
        ElevatedButton(
          onPressed: isLoading ? null : onSend,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: AppSpacing.xl,
                  width: AppSpacing.xl,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  appLocale.authForgotPasswordButton,
                  style: const TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }
}
