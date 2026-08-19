import 'package:flutter/material.dart';

import 'package:mazilon/l10n/app_localizations.dart';

/// Prompts the user to retain one custom Dreams and Goals selection.
///
/// The returned value is the selection-row index to retain. A null result
/// means the dialog was dismissed without changing the persisted selection.
Future<int?> showDreamsAndGoalsCustomConflictDialog(
  BuildContext context, {
  required List<String> selections,
  required List<int> customSelectionIndexes,
  required String gender,
}) {
  final validCustomSelectionIndexes = customSelectionIndexes
      .where((index) => index >= 0 && index < selections.length)
      .toList(growable: false);

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      final localizations = AppLocalizations.of(dialogContext)!;
      int? retainedSelectionIndex;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              localizations.dreamsAndGoalsCustomConflictTitle(gender),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: RadioGroup<int>(
                  groupValue: retainedSelectionIndex,
                  onChanged: (value) {
                    setDialogState(() {
                      retainedSelectionIndex = value;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localizations.dreamsAndGoalsCustomConflictMessage(
                          gender,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.dreamsAndGoalsCustomConflictSelect(
                          gender,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final selectionIndex in validCustomSelectionIndexes)
                        RadioListTile<int>(
                          key: Key(
                            'dreams-and-goals-custom-conflict-option-'
                            '$selectionIndex',
                          ),
                          contentPadding: EdgeInsets.zero,
                          value: selectionIndex,
                          title: Text(selections[selectionIndex]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                key: const Key('dreams-and-goals-custom-conflict-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(localizations.closeButton(gender)),
              ),
              TextButton(
                key: const Key('dreams-and-goals-custom-conflict-confirm'),
                onPressed: retainedSelectionIndex == null
                    ? null
                    : () => Navigator.of(
                        dialogContext,
                      ).pop(retainedSelectionIndex),
                child: Text(localizations.confirmButton(gender)),
              ),
            ],
          );
        },
      );
    },
  );
}
