import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mazilon/features/personal_plan/ui/personal_plan_info_modal.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/phone/ui/phoneTextAndIcon.dart';

/// Presents the Personal Plan information modal from an icon-only action.
final class PersonalPlanInfoButton extends StatelessWidget {
  const PersonalPlanInfoButton({super.key, this.actionKey});

  /// Key applied to the actionable hit target when a caller needs to identify it.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return SizedBox(
      key: actionKey,
      child: circularActionButton(
        context,
        tooltip: l10n.personalPlanInfoTooltip,
        icon: Icons.info_outline,
        diameter: 32,
        iconSize: 20,
        onTap: () {
          unawaited(showPersonalPlanInfoModal(context));
        },
      ),
    );
  }
}
