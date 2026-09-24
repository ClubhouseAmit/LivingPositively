import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/design_system/widgets/card.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Pushes [dialog] on a modal route. Pop with `Navigator.of(context).pop`.
Future<T?> showDialog<T>({
  required BuildContext context,
  required Widget dialog,
  bool barrierDismissible = true,
}) {
  return Navigator.of(context).push<T>(
    RawDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.onSurface.withValues(alpha: 0.5),
      barrierLabel: 'Dismiss',
      pageBuilder: _page,
      settings: RouteSettings(arguments: dialog),
    ),
  );
}

Widget _page(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
) {
  final Object? arguments = ModalRoute.of(context)?.settings.arguments;
  return Align(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: arguments is Widget ? arguments : const SizedBox.shrink(),
    ),
  );
}

/// Design-system dialog body — title, optional copy, at most two actions.
class Dialog extends StatelessWidget {
  const Dialog({
    super.key,
    required this.title,
    required this.primaryLabel,
    this.body,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyle.headlineMedium),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(body!, style: AppTextStyle.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.lg),
          Button(label: primaryLabel, onPressed: onPrimary),
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Button(
              label: secondaryLabel!,
              onPressed: onSecondary,
              variant: ButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
