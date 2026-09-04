import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mazilon/form/custom_category_editor.dart';
import 'package:mazilon/form/custom_category_options.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
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
          TextButton(
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
          const SizedBox(height: 16),
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

/// The trailing wizard page used to add a new custom category.
///
/// Saving awaits [onSave] before the wizard coordinator inserts the category
/// and navigates to its newly created page. The secondary action skips the
/// page without creating or persisting an incomplete category.
class AddCustomCategoryStep extends WizardStep {
  /// Index the new category will receive when it is saved.
  final int index;

  /// Advances to the newly inserted category or the next wizard step.
  final VoidCallback next;

  /// Persists a validated new category and inserts it into the wizard.
  final Future<void> Function(MapEntry<String, String> category) onSave;

  /// Localized suggestions, in display order, for the title field.
  final List<String> predefinedTitles;

  const AddCustomCategoryStep({
    required super.key,
    required this.index,
    required this.next,
    required this.onSave,
    this.predefinedTitles = const <String>[],
  });

  @override
  String primaryActionLabel(BuildContext context) =>
      AppLocalizations.of(context)!.sharePageSaveCustomCategory;

  @override
  String? secondaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.skipButton(Provider.of<UserInformation>(context, listen: false).gender);

  @override
  AddCustomCategoryStepState createState() => AddCustomCategoryStepState();
}

/// State for [AddCustomCategoryStep].
class AddCustomCategoryStepState
    extends WizardStepState<AddCustomCategoryStep> {
  final editorKey = GlobalKey<CustomCategoryEditorState>();

  @override
  Future<void> onPrimaryAction() async {
    try {
      await editorKey.currentState?.save();
      // The coordinator inserts the new category before this step and moves
      // the wizard to it, so the user sees it immediately after saving.
    } catch (error, stackTrace) {
      if (mounted) {
        showPersistenceRetrySnackBar(context, () => onPrimaryAction());
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> onSecondaryAction() async {
    widget.next();
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
            localizations.sharePageAddCustomCategory,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          CustomCategoryEditor(
            key: editorKey,
            predefinedTitles: predefinedTitles,
            saveLabel: localizations.sharePageSaveCustomCategory,
            onSave: widget.onSave,
          ),
        ],
      ),
    );
  }
}
