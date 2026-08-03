import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/circular_action_button.dart';

/// The shared dotted add control used by trait and thank-you suggestions.
class SuggestionAddButton extends StatelessWidget {

  const SuggestionAddButton({required this.onPressed, super.key, this.label});
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;
    final buttonLabel =
        label ?? AppLocalizations.of(context)?.addItemTooltip ?? 'Add';

    return circularActionButton(
      context,
      tooltip: buttonLabel,
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: color, size: 20),
      ),
    );
  }
}
