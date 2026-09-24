import 'package:flutter/material.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/editor.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/options.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/shell/ui/persistence_retry_snack_bar.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

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
          const SizedBox(height: AppSpacing.lg),
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
