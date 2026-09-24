part of '../../../pages/auth_page.dart';

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
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Button(label: label, onPressed: onPressed),
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
        borderRadius: BorderRadius.circular(AppRadii.button),
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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.button),
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
        const SizedBox(height: AppSpacing.md),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
      label: design.Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
