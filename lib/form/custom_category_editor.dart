import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/spacing.dart';

export 'custom_category_card.dart';

/// The shared editor used by the wizard and the Share/My Plan summaries.
///
/// Controllers remain local to this widget, so switching between add and edit
/// never leaks text into the next category. Values are trimmed only at the
/// boundary; the text between the outer whitespace is kept byte-for-byte.
class CustomCategoryEditor extends StatefulWidget {
  /// Existing category to edit. A null value creates an empty category.
  final MapEntry<String, String>? initialCategory;

  /// Localized suggestions in stable display order. The final suggestion may
  /// be the caller's free-form input option.
  final List<String> predefinedTitles;

  /// Validated category save callback. It is awaited before the editor exits
  /// its saving state.
  final Future<void> Function(MapEntry<String, String>) onSave;

  /// Optional action used to close an add/edit form without saving.
  final VoidCallback? onCancel;

  /// Optional asynchronous delete action. Failures are converted into the
  /// shared persistence retry prompt by the editor boundary.
  final Future<void> Function()? onDelete;

  /// Optional localized save button label.
  final String? saveLabel;

  /// Optional localized cancel button label.
  final String? cancelLabel;

  /// Whether the delete control is rendered when [onDelete] is supplied.
  final bool showDelete;

  /// Direction used by the suggestions overlay.
  final OptionsViewOpenDirection optionsViewOpenDirection;

  const CustomCategoryEditor({
    super.key,
    this.initialCategory,
    this.predefinedTitles = const <String>[],
    required this.onSave,
    this.onCancel,
    this.onDelete,
    this.saveLabel,
    this.cancelLabel,
    this.showDelete = false,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.down,
  });

  @override
  CustomCategoryEditorState createState() => CustomCategoryEditorState();
}

class CustomCategoryEditorState extends State<CustomCategoryEditor> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final FocusNode titleFocusNode;
  bool showValidation = false;
  bool saving = false;
  int _titleOptionsRefresh = 0;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.initialCategory?.key ?? '',
    )..addListener(_onTextChanged);
    descriptionController = TextEditingController(
      text: widget.initialCategory?.value ?? '',
    )..addListener(_onTextChanged);
    titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    titleController
      ..removeListener(_onTextChanged)
      ..dispose();
    descriptionController
      ..removeListener(_onTextChanged)
      ..dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomCategoryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCategory = oldWidget.initialCategory;
    final newCategory = widget.initialCategory;
    if (oldCategory?.key != newCategory?.key ||
        oldCategory?.value != newCategory?.value) {
      titleController.text = newCategory?.key ?? '';
      descriptionController.text = newCategory?.value ?? '';
      showValidation = false;
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  TextDirection _directionFor(String value) {
    return getDirectionOfText(value) == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  TextAlign _alignmentFor(String value) {
    return _directionFor(value) == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
  }

  String? _errorFor(TextEditingController controller) {
    if (!showValidation || controller.text.trim().isNotEmpty) return null;
    return AppLocalizations.of(context)!.validateEmpty;
  }

  /// Returns the trimmed category when both fields are non-empty.
  ///
  /// Outer whitespace is removed at this boundary only; all inner and mixed
  /// Hebrew/English text is preserved exactly.
  Future<MapEntry<String, String>?> readValidatedCategory() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      setState(() => showValidation = true);
      return null;
    }
    return MapEntry(title, description);
  }

  /// Validates and awaits [CustomCategoryEditor.onSave].
  ///
  /// Returns `false` when validation fails or another save is already in
  /// progress, and `true` after the callback completes successfully.
  Future<bool> save() async {
    if (saving) return false;
    final category = await readValidatedCategory();
    if (category == null) return false;
    setState(() => saving = true);
    try {
      await widget.onSave(category);
      return true;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _refreshTitleOptions(TextEditingController controller) {
    final value = controller.value;
    final refreshId = ++_titleOptionsRefresh;
    final refreshText = '${value.text} ';

    // RawAutocomplete refreshes its options only when the field text changes.
    // A temporary trailing space keeps the trimmed query identical while
    // forcing the widget to calculate and display the suggestions for an
    // unchanged field, including an empty Hebrew field.
    controller.value = value.copyWith(
      text: refreshText,
      selection: TextSelection.collapsed(
        offset: refreshText.length,
        affinity: value.selection.affinity,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || refreshId != _titleOptionsRefresh) return;
      if (controller.text != refreshText) return;
      controller.value = value;
    });
  }

  Future<void> _runDelete() async {
    try {
      await widget.onDelete!();
    } catch (_) {
      if (mounted) {
        showPersistenceRetrySnackBar(context, _runDelete);
      }
    }
  }

  Widget _actionRow(AppLocalizations localizations) {
    return Row(
      children: [
        if (widget.onCancel != null)
          Expanded(
            child: TextButton(
              onPressed: saving ? null : widget.onCancel,
              child: Text(
                widget.cancelLabel ?? localizations.closeButton('other'),
              ),
            ),
          ),
        if (widget.showDelete && widget.onDelete != null)
          IconButton(
            key: const Key('custom-category-editor-delete-button'),
            tooltip: localizations.deleteButton('other'),
            onPressed: saving ? null : () => unawaited(_runDelete()),
            icon: const Icon(Icons.delete_outline),
          ),
        Expanded(
          child: TextButton(
            key: const Key('custom-category-editor-save-button'),
            onPressed: saving ? null : () => unawaited(save()),
            style: primaryButtonStyle(context),
            child: Text(
              saving
                  ? '…'
                  : widget.saveLabel ?? localizations.saveButton('other'),
              style: primaryButtonTextStyle(
                context,
              ).copyWith(fontSize: 16.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _titleField() {
    return RawAutocomplete<String>(
      key: const Key('custom-category-title-autocomplete'),
      textEditingController: titleController,
      focusNode: titleFocusNode,
      optionsViewOpenDirection: widget.optionsViewOpenDirection,
      displayStringForOption: (option) => option,
      optionsBuilder: (value) {
        final query = value.text.trim();
        if (query.isEmpty || widget.initialCategory?.key.trim() == query) {
          return widget.predefinedTitles;
        }
        return widget.predefinedTitles.where(
          (option) => option.toLowerCase().contains(query.toLowerCase()),
        );
      },
      onSelected: (option) {
        if (widget.predefinedTitles.isNotEmpty &&
            option == widget.predefinedTitles.last) {
          titleController.clear();
          titleFocusNode.requestFocus();
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          key: const Key('custom-category-title-field'),
          controller: controller,
          focusNode: focusNode,
          textDirection: _directionFor(controller.text),
          textAlign: _alignmentFor(controller.text),
          enableSuggestions: true,
          autocorrect: true,
          onSubmitted: (_) => onSubmitted(),
          onTap: () => _refreshTitleOptions(controller),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(
              context,
            )!.sharePageCustomCategoryTitle,
            errorText: _errorFor(titleController),
            suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
                ? SpeechDictationSuffixAction(
                    controller: controller,
                    onTextApplied: (_) => _refreshTitleOptions(controller),
                  )
                : null,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: options
                  .map(
                    (option) => ListTile(
                      title: Directionality(
                        textDirection: _directionFor(option),
                        child: Text(option, textAlign: _alignmentFor(option)),
                      ),
                      onTap: () => onSelected(option),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width > 1000
        ? 600.0
        : MediaQuery.sizeOf(context).width * .85;
    return Container(
      key: const Key('custom-category-editor'),
      width: width,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleField(),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('custom-category-description-field'),
            controller: descriptionController,
            minLines: 3,
            maxLines: 6,
            textDirection: _directionFor(descriptionController.text),
            textAlign: _alignmentFor(descriptionController.text),
            enableSuggestions: true,
            autocorrect: true,
            decoration: InputDecoration(
              labelText: localizations.sharePageCustomCategoryDescription,
              alignLabelWithHint: true,
              errorText: _errorFor(descriptionController),
              suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
                  ? SpeechDictationSuffixAction(
                      controller: descriptionController,
                    )
                  : null,
            ),
          ),
          if (widget.onCancel != null || widget.showDelete) ...[
            const SizedBox(height: AppSpacing.md),
            _actionRow(localizations),
          ],
        ],
      ),
    );
  }
}
