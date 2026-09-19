import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/editor.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/options.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/shell/ui/persistence_retry_snack_bar.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

/// Saves the category at [index]. Implementations must complete only after
/// the canonical and legacy snapshots have been queued or persisted.
typedef CustomCategorySave =
    Future<void> Function(int index, MapEntry<String, String> category);

/// A saved custom-category wizard page.
///
/// The editor validates both fields, preserves the entered text except for
/// outer whitespace, and awaits [onSave] before calling [next]. When the
/// category is deleted, the supplied callback owns the persistence retry path.
class CustomCategoryStep extends WizardStep {
  /// Position of [category] in the saved custom-category list.
  final int index;

  /// Saved title and description displayed by this step.
  final MapEntry<String, String> category;

  /// Called after a successful save to advance the wizard.
  final VoidCallback next;

  /// Persists the edited category at [index].
  final CustomCategorySave onSave;

  /// Removes [index] after the user confirms deletion.
  final Future<void> Function(int index)? onDelete;

  /// Localized suggestions, in display order, for the title field.
  final List<String> predefinedTitles;

  const CustomCategoryStep({
    required super.key,
    required this.index,
    required this.category,
    required this.next,
    required this.onSave,
    this.onDelete,
    this.predefinedTitles = const <String>[],
  });

  @override
  String primaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.saveButton(Provider.of<UserInformation>(context, listen: false).gender);

  @override
  CustomCategoryStepState createState() => CustomCategoryStepState();
}

/// State for [CustomCategoryStep].
class CustomCategoryStepState extends WizardStepState<CustomCategoryStep> {
  final editorKey = GlobalKey<CustomCategoryEditorState>();

  @override
  Future<void> onPrimaryAction() async {
    try {
      final saved = await editorKey.currentState?.save() ?? false;
      if (saved && mounted) widget.next();
    } catch (error, stackTrace) {
      if (mounted) {
        showPersistenceRetrySnackBar(context, () => onPrimaryAction());
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> persistBeforeExit() async {
    await Provider.of<UserInformation>(
      context,
      listen: false,
    ).pendingCustomCategoriesSave;
  }

  @override
  Future<void> retryPersistBeforeExit() async {
    final user = Provider.of<UserInformation>(context, listen: false);
    await user.retryCustomCategoriesSave(user.customCategoriesSaveRevision);
  }

  Future<void> _delete() async {
    if (widget.onDelete == null || !mounted) return;
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteButton('other')),
        content: Text(localizations.customCategoryDeleteConfirmation),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.closeButton('other')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.deleteButton('other')),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onDelete!(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final predefinedTitles = widget.predefinedTitles.isNotEmpty
        ? widget.predefinedTitles
        : localizedCustomCategoryTitles(localizations);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.category.key,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomCategoryEditor(
            key: editorKey,
            initialCategory: widget.category,
            predefinedTitles: predefinedTitles,
            saveLabel: localizations.saveButton(
              Provider.of<UserInformation>(context, listen: false).gender,
            ),
            onSave: (category) => widget.onSave(widget.index, category),
            onDelete: widget.onDelete == null ? null : _delete,
            showDelete: widget.onDelete != null,
          ),
        ],
      ),
    );
  }
}
