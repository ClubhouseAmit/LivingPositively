part of 'share_form.dart';

mixin _ShareFormCategories on _ShareFormCustomCategoriesController {
  late FileService fileService;
  final _dreamsAndGoalsStepKey = GlobalKey<WizardStepState>(
    debugLabel: 'share-dreams-and-goals',
  );
  bool _isEditingDreamsAndGoals = false;
  bool _isOpeningDreamsAndGoals = false;
  bool _hideDreamsAndGoalsSummaryUntilRepair = false;
  @override
  bool _isAddingCustomCategory = false;
  int? _editingCustomCategoryIndex;
  int _customCategoryFormGeneration = 0;

  @override
  void resetCustomCategoryForm() {
    _editingCustomCategoryIndex = null;
    _customCategoryFormGeneration++;
  }

  void startAddingCustomCategory() {
    setState(() {
      resetCustomCategoryForm();
      _isAddingCustomCategory = true;
    });
  }

  void editCustomCategory(int index) {
    final categories = _customCategories;
    if (index < 0 || index >= categories.length) {
      return;
    }
    setState(() {
      _editingCustomCategoryIndex = index;
      _isAddingCustomCategory = true;
      _customCategoryFormGeneration++;
    });
  }

  Future<void> deleteCustomCategory(int index) async {
    final categories = _customCategories;
    if (index < 0 || index >= categories.length) {
      return;
    }
    if (!await _confirmDelete(categories[index].key)) {
      return;
    }

    final updated = List<MapEntry<String, String>>.from(categories)
      ..removeAt(index);
    await _persistCustomCategoriesWithRetry(
      updated,
      onSuccess: () {
        if (!mounted) return;
        setState(() {
          if (_editingCustomCategoryIndex == index) {
            resetCustomCategoryForm();
            _isAddingCustomCategory = false;
          } else if (_editingCustomCategoryIndex != null &&
              _editingCustomCategoryIndex! > index) {
            _editingCustomCategoryIndex = _editingCustomCategoryIndex! - 1;
          }
        });
      },
    );
  }

  Widget buildCustomCategoryForm(BuildContext context) {
    final categories = _customCategories;
    final editingIndex = _editingCustomCategoryIndex;
    final initialCategory =
        editingIndex != null &&
            editingIndex >= 0 &&
            editingIndex < categories.length
        ? categories[editingIndex]
        : null;
    return CustomCategoryEditor(
      key: ValueKey(
        'share-custom-category-editor-$_customCategoryFormGeneration',
      ),
      initialCategory: initialCategory,
      predefinedTitles: localizedCustomCategoryTitles(appLocale),
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      saveLabel: appLocale.sharePageSaveCustomCategory,
      onCancel: () {
        setState(() {
          resetCustomCategoryForm();
          _isAddingCustomCategory = false;
        });
      },
      onSave: (category) async {
        final updated = List<MapEntry<String, String>>.from(categories);
        if (editingIndex != null &&
            editingIndex >= 0 &&
            editingIndex < updated.length) {
          updated[editingIndex] = category;
        } else {
          updated.add(category);
        }
        await _persistCustomCategoriesWithRetry(
          updated,
          onSuccess: () {
            if (!mounted) return;
            setState(() {
              resetCustomCategoryForm();
              _isAddingCustomCategory = false;
            });
          },
        );
      },
    );
  }

  Widget buildCustomCategoryCard(
    MapEntry<String, String> category,
    int index,
    String gender,
  ) {
    return CustomCategoryCard(
      category: category,
      index: index,
      onEdit: () => editCustomCategory(index),
      onDelete: () => unawaited(deleteCustomCategory(index)),
    );
  }

  Future<void> _deleteBuiltInCategory(String collectionName) async {
    final localizations = AppLocalizations.of(context)!;
    final userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (!await _confirmDelete(
      localizations.builtInCategoryDeleteConfirmation,
    )) {
      return;
    }
    try {
      await userInformation.saveCategorySelection(collectionName, const []);
    } catch (error, stackTrace) {
      await _captureDreamsAndGoalsFailure(error, stackTrace);
      if (mounted) {
        showPersistenceRetrySnackBar(
          context,
          () => _deleteBuiltInCategory(collectionName),
        );
      }
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final localizations = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.deleteButton('other')),
            content: Text(
              '$title\n\n${localizations.customCategoryDeleteConfirmation}',
            ),
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
        ) ??
        false;
  }

  Widget buildCustomCategoriesSection(BuildContext context, String gender) {
    return Column(
      children: [
        if (_isAddingCustomCategory) buildCustomCategoryForm(context),
        if (!_isAddingCustomCategory)
          InkWell(
            onTap: startAddingCustomCategory,
            child: Text(
              appLocale.sharePageAddCustomCategory,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildPlanSummary(
    BuildContext context,
    UserInformation userInformation,
    String gender,
  ) {
    final definitions = <({String collection, List<String> answers})>[
      (
        collection: 'PersonalPlan-Distractions',
        answers: userInformation.distractions,
      ),
      (
        collection: 'PersonalPlan-DifficultEvents',
        answers: userInformation.difficultEvents,
      ),
      (
        collection: 'PersonalPlan-FeelBetter',
        answers: userInformation.feelBetter,
      ),
      (
        collection: 'PersonalPlan-MakeSafer',
        answers: userInformation.makeSafer,
      ),
      (
        collection: 'PersonalPlan-SafeEnvironment',
        answers: userInformation.safeEnvironment,
      ),
    ];
    final result = <Widget>[];
    for (final definition in definitions) {
      if (definition.answers.isEmpty) continue;
      final info = retrieveInformation(
        definition.collection,
        gender,
        appLocale,
      );
      final step = definitions.indexOf(definition);
      result.add(
        MyPlanSection(
          key: ValueKey('share-summary-$step'),
          title: info['header'] ?? '',
          subTitle: info['subTitle'] ?? '',
          answers: definition.answers,
          onEdit: widget.goToStep == null ? null : () => widget.goToStep!(step),
          onDelete: () =>
              unawaited(_deleteBuiltInCategory(definition.collection)),
        ),
      );
    }
    for (final entry in _customCategories.indexed) {
      final categoryIndex = entry.$1;
      result.add(
        CustomCategoryCard(
          key: ValueKey('share-summary-custom-$categoryIndex'),
          category: entry.$2,
          index: categoryIndex,
          onEdit: widget.goToStep == null
              ? () => editCustomCategory(categoryIndex)
              : () => widget.goToStep!(6 + categoryIndex),
          onDelete: () => unawaited(deleteCustomCategory(categoryIndex)),
        ),
      );
    }
    return result;
  }
}
