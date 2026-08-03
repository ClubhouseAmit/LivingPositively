import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

const String _customCategoryTitlesKey = 'customCategoryTitles';
const String _customCategoryDescriptionsKey = 'customCategoryDescriptions';

class ShareForm extends StatefulWidget {

  const ShareForm({required this.prev, required this.submit, super.key});
  final Function prev;
  final Function submit;

  @override
  State<ShareForm> createState() => _ShareFormState();
}

class _ShareFormState extends LPExtendedState<ShareForm> {
  late FileService fileService;
  final TextEditingController _customCategoryTitleController =
      TextEditingController();
  final TextEditingController _customCategoryDescriptionController =
      TextEditingController();
  final FocusNode _customCategoryTitleFocusNode = FocusNode();
  final List<MapEntry<String, String>> _customCategories = [];
  bool _isAddingCustomCategory = false;
  bool _showCustomCategoryValidation = false;
  int? _editingCustomCategoryIndex;
  int _customCategoryFormGeneration = 0;

  Future<void> setHasFilled() async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.setItem('hasFilled', PersistentMemoryType.Bool, true);
  }

  @override
  void initState() {
    super.initState();
    fileService = GetIt.instance<FileService>();
    setHasFilled();
    loadCustomCategories();
  }

  @override
  void dispose() {
    _customCategoryTitleController.dispose();
    _customCategoryDescriptionController.dispose();
    _customCategoryTitleFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadCustomCategories() async {
    final service = GetIt.instance<PersistentMemoryService>();
    final titles = TypeUtils.castToStringList(
      await service.getItem(
        _customCategoryTitlesKey,
        PersistentMemoryType.StringList,
      ),
    );
    final descriptions = TypeUtils.castToStringList(
      await service.getItem(
        _customCategoryDescriptionsKey,
        PersistentMemoryType.StringList,
      ),
    );
    final loadedCategories = <MapEntry<String, String>>[];

    for (var i = 0; i < titles.length && i < descriptions.length; i++) {
      final title = titles[i].trim();
      final description = descriptions[i].trim();
      if (title.isEmpty || description.isEmpty) {
        continue;
      }
      loadedCategories.add(MapEntry(title, description));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(loadedCategories);
    });
  }

  Future<void> saveCustomCategories() async {
    final service = GetIt.instance<PersistentMemoryService>();
    await service.setItem(
      _customCategoryTitlesKey,
      PersistentMemoryType.StringList,
      _customCategories.map((category) => category.key).toList(),
    );
    await service.setItem(
      _customCategoryDescriptionsKey,
      PersistentMemoryType.StringList,
      _customCategories.map((category) => category.value).toList(),
    );
  }

  List<String> predefinedCategoryTitles() {
    return [
      appLocale.customCategoryOptionEmpoweringQuotes,
      appLocale.customCategoryOptionPastEvents,
      appLocale.customCategoryOptionAboutMe,
      appLocale.customCategoryOptionCustomInput,
    ];
  }

  TextDirection textDirectionFor(String text) {
    return getDirectionOfText(text) == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  TextAlign textAlignFor(String text) {
    return getDirectionOfText(text) == 'rtl' ? TextAlign.right : TextAlign.left;
  }

  void resetCustomCategoryForm() {
    _customCategoryTitleController.clear();
    _customCategoryDescriptionController.clear();
    _customCategoryTitleFocusNode.unfocus();
    _showCustomCategoryValidation = false;
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
    final category = _customCategories[index];
    setState(() {
      _customCategoryTitleController.text = category.key;
      _customCategoryDescriptionController.text = category.value;
      _showCustomCategoryValidation = false;
      _editingCustomCategoryIndex = index;
      _isAddingCustomCategory = true;
      _customCategoryFormGeneration++;
    });
  }

  Future<void> deleteCustomCategory(int index) async {
    if (index < 0 || index >= _customCategories.length) {
      return;
    }

    setState(() {
      _customCategories.removeAt(index);
      if (_editingCustomCategoryIndex == index) {
        resetCustomCategoryForm();
        _isAddingCustomCategory = false;
      } else if (_editingCustomCategoryIndex != null &&
          _editingCustomCategoryIndex! > index) {
        _editingCustomCategoryIndex = _editingCustomCategoryIndex! - 1;
      }
    });

    await saveCustomCategories();
  }

  Future<void> saveCustomCategory() async {
    final title = _customCategoryTitleController.text.trim();
    final description = _customCategoryDescriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      setState(() {
        _showCustomCategoryValidation = true;
      });
      return;
    }

    setState(() {
      final editingIndex = _editingCustomCategoryIndex;
      if (editingIndex != null &&
          editingIndex >= 0 &&
          editingIndex < _customCategories.length) {
        _customCategories[editingIndex] = MapEntry(title, description);
      } else {
        _customCategories.add(MapEntry(title, description));
      }
      resetCustomCategoryForm();
      _isAddingCustomCategory = false;
    });

    await saveCustomCategories();
  }

  String? _customCategoryValidationError(TextEditingController controller) {
    return _showCustomCategoryValidation && controller.text.trim().isEmpty
        ? appLocale.validateEmpty
        : null;
  }

  void refreshCustomCategoryTitleOptions(
    TextEditingController textEditingController,
  ) {
    final value = textEditingController.value;
    final offset = value.selection.isValid
        ? value.selection.baseOffset.clamp(0, value.text.length)
        : value.text.length;
    final nextAffinity = value.selection.affinity == TextAffinity.downstream
        ? TextAffinity.upstream
        : TextAffinity.downstream;

    // Nudges RawAutocomplete to rebuild options when tapping unchanged text.
    textEditingController.value = value.copyWith(
      selection: TextSelection.collapsed(
        offset: offset,
        affinity: nextAffinity,
      ),
    );
  }

  Widget buildCustomCategoryTitleField() {
    return RawAutocomplete<String>(
      key: ValueKey(
        'custom-category-title-autocomplete-$_customCategoryFormGeneration',
      ),
      textEditingController: _customCategoryTitleController,
      focusNode: _customCategoryTitleFocusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (textEditingValue) {
        final input = textEditingValue.text.trim();
        final options = predefinedCategoryTitles();
        final editingIndex = _editingCustomCategoryIndex;
        final isInitialEditingTitle =
            editingIndex != null &&
            editingIndex >= 0 &&
            editingIndex < _customCategories.length &&
            _customCategories[editingIndex].key == input;
        if (input.isEmpty || isInitialEditingTitle) {
          return options;
        }
        return options.where((option) => option.contains(input));
      },
      onSelected: (option) {
        if (option == appLocale.customCategoryOptionCustomInput) {
          _customCategoryTitleController.clear();
          _customCategoryTitleFocusNode.requestFocus();
        }
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              key: const Key('custom-category-title-field'),
              controller: textEditingController,
              focusNode: focusNode,
              textDirection: appLocale.textDirection == 'rtl'
                  ? TextDirection.rtl
                  : null,
              onTap: () =>
                  refreshCustomCategoryTitleOptions(textEditingController),
              decoration: InputDecoration(
                labelText: appLocale.sharePageCustomCategoryTitle,
                errorText: _customCategoryValidationError(
                  _customCategoryTitleController,
                ),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 340),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    return ListTile(
                      title: Directionality(
                        textDirection: textDirectionFor(option),
                        child: Text(option, textAlign: textAlignFor(option)),
                      ),
                      onTap: () => onSelected(option),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildCustomCategoryForm(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          buildCustomCategoryTitleField(),
          const SizedBox(height: 12),
          TextField(
            key: const Key('custom-category-description-field'),
            controller: _customCategoryDescriptionController,
            minLines: 3,
            maxLines: 6,
            textDirection: appLocale.textDirection == 'rtl'
                ? TextDirection.rtl
                : null,
            decoration: InputDecoration(
              labelText: appLocale.sharePageCustomCategoryDescription,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              errorText: _customCategoryValidationError(
                _customCategoryDescriptionController,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: saveCustomCategory,
            child: Text(appLocale.sharePageSaveCustomCategory),
          ),
        ],
      ),
      ),
    );
  }

  Widget buildCustomCategoryCard(
    MapEntry<String, String> category,
    int index,
    String gender,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Directionality(
        textDirection: textDirectionFor(category.key),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      fontFamily: 'Rubix',
                    ),
                    textAlign: textAlignFor(category.key),
                  ),
                ),
                IconButton(
                  key: Key('custom-category-edit-button-$index'),
                  tooltip: appLocale.addFormEdit(gender),
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => editCustomCategory(index),
                ),
                IconButton(
                  key: Key('custom-category-delete-button-$index'),
                  tooltip: appLocale.deleteButton(gender),
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => deleteCustomCategory(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: textDirectionFor(category.value),
              child: Text(
                category.value,
                style: TextStyle(fontSize: 14.sp, fontFamily: 'Rubix'),
                textAlign: textAlignFor(category.value),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget buildCustomCategoriesSection(BuildContext context, String gender) {
    return Column(
      children: [
        ..._customCategories.asMap().entries.map(
          (entry) => buildCustomCategoryCard(entry.value, entry.key, gender),
        ),
        if (_isAddingCustomCategory) buildCustomCategoryForm(context),
        if (!_isAddingCustomCategory)
          TextButton(
            onPressed: startAddingCustomCategory,
            child: AutoSizeText(
              appLocale.sharePageAddCustomCategory,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appInfoProvider = Provider.of<AppInformation>(context);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    final gender = userInfoProvider.gender;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(height: Spacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Semantics(
                    header: true,
                    child: AutoSizeText(
                      appLocale.sharePageHeader(gender),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
                AutoSizeText(
                  appLocale.sharePageSubTitle(gender),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                  child: Image.asset('assets/images/FormSubmit.png'),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: AutoSizeText(
                    appLocale.sharePageMidTitle(gender),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      //share personal plan PDF button:
                      IconButton(
                        onPressed: () {
                          showShareDialog(context);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest, // Set the background color to white
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(7),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ), // Set the border color
                          ),
                        ),
                        icon: Icon(
                          Icons.share,
                          color: Theme.of(context).colorScheme.primary,
                        ), // Set the icon color
                        padding: const EdgeInsets.all(10),
                      ),
                      //download personal plan PDF button:
                      IconButton(
                        onPressed: () async {
                          final result = await fileService.download(
                            [
                              appLocale.difficultEventsHeader(gender),
                              appLocale.makeSaferHeader(gender),
                              appLocale.feelBetterHeader(gender),
                              appLocale.distractionsHeader(gender),
                              appLocale.phonesPageHeader(gender),
                            ],
                            [
                              appLocale.difficultEventsSubTitle(gender),
                              appLocale.makeSaferSubTitle(gender),
                              appLocale.feelBetterSubTitle(gender),
                              appLocale.distractionsSubTitle(gender),
                              appLocale.phonesPageHeader(gender),
                            ],
                            appInfoProvider.sharePDFtexts,
                            ShareFileType.PDF,
                            appLocale.textDirection,
                          );
                          if (result == null) {
                            // Show him a message
                            showToast(
                              message: appLocale.downloadFailed(gender),
                            );
                            return;
                          }
                          // Show a toast message to the user
                          showToast(
                            message: appLocale.finishedDownloading(gender),
                          );
                        },

                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest, // Set the background color to white
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(7),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ), // Set the border color
                          ),
                        ),
                        icon: Icon(
                          Icons.download,
                          color: Theme.of(context).colorScheme.primary,
                        ), // Set the icon color
                        padding: const EdgeInsets.all(10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                buildCustomCategoriesSection(context, gender),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.submit(context);
                  },
                  child: Text(appLocale.sharePageFinishButton(gender)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
