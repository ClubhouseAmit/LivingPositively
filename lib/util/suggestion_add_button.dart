import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// The shared dotted add control used by trait and thank-you suggestions.
class SuggestionAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? label;

  const SuggestionAddButton({super.key, required this.onPressed, this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    final buttonLabel =
        label ?? AppLocalizations.of(context)?.addItemTooltip ?? 'Add';

    return Tooltip(
      message: buttonLabel,
      child: Semantics(
        button: true,
        label: buttonLabel,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Center(
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    radius: const Radius.circular(20),
                    dashPattern: const [5, 5],
                    color: color,
                    strokeWidth: 2,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Icon(Icons.add, color: color, size: 20),
                        Transform.translate(
                          offset: const Offset(0.5, 0.5),
                          child: Icon(Icons.add, color: color, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
