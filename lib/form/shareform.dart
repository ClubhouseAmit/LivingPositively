import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get_it/get_it.dart';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/languages_util_functions.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/type_utils.dart';

import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';

const String _customCategoryTitlesKey = 'customCategoryTitles';
const String _customCategoryDescriptionsKey = 'customCategoryDescriptions';

class ShareForm extends StatefulWidget {
  final Function prev;
  final Function submit;

  ShareForm({
    Key? key,
    required this.prev,
    required this.submit,
  }) : super(key: key);

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

  void setHasFilled() async {
    PersistentMemoryService service = GetIt.instance<
        PersistentMemoryService>(); // Get the persistent memory service instance

    await service.setItem("hasFilled", PersistentMemoryType.Bool, true);
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
    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();
    final titles = TypeUtils.castToStringList(await service.getItem(
        _customCategoryTitlesKey, PersistentMemoryType.StringList));
    final descriptions = TypeUtils.castToStringList(await service.getItem(
        _customCategoryDescriptionsKey, PersistentMemoryType.StringList));
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
    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();
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

  void startAddingCustomCategory() {
    setState(() {
      _isAddingCustomCategory = true;
      _showCustomCategoryValidation = false;
    });
  }

  Future<void> addCustomCategory() async {
    final title = _customCategoryTitleController.text.trim();
    final description = _customCategoryDescriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      setState(() {
        _showCustomCategoryValidation = true;
      });
      return;
    }

    setState(() {
      _customCategories.add(MapEntry(title, description));
      _customCategoryTitleController.clear();
      _customCategoryDescriptionController.clear();
      _isAddingCustomCategory = false;
      _showCustomCategoryValidation = false;
    });

    await saveCustomCategories();
  }

  Widget buildCustomCategoryTitleField() {
    return RawAutocomplete<String>(
      textEditingController: _customCategoryTitleController,
      focusNode: _customCategoryTitleFocusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final input = textEditingValue.text.trim();
        final options = predefinedCategoryTitles();
        if (input.isEmpty) {
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
          textDirection:
              appLocale.textDirection == 'rtl' ? TextDirection.rtl : null,
          decoration: InputDecoration(
            labelText: appLocale.sharePageCustomCategoryTitle,
            errorText: _showCustomCategoryValidation &&
                    _customCategoryTitleController.text.trim().isEmpty
                ? appLocale.validateEmpty
                : null,
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
                        child: Text(
                          option,
                          textAlign: textAlignFor(option),
                        ),
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
    return Container(
      width: MediaQuery.sizeOf(context).width > 1000
          ? 600
          : MediaQuery.sizeOf(context).width * 0.85,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryPurple),
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
            textDirection:
                appLocale.textDirection == 'rtl' ? TextDirection.rtl : null,
            decoration: InputDecoration(
              labelText: appLocale.sharePageCustomCategoryDescription,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              errorText: _showCustomCategoryValidation &&
                      _customCategoryDescriptionController.text.trim().isEmpty
                  ? appLocale.validateEmpty
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: addCustomCategory,
            style: myButtonStyle,
            child: myAutoSizedText(
              appLocale.sharePageSaveCustomCategory,
              myTextStyle.copyWith(fontSize: 16.sp),
              null,
              24,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCustomCategoryCard(MapEntry<String, String> category) {
    return Container(
      width: MediaQuery.sizeOf(context).width > 1000
          ? 600
          : MediaQuery.sizeOf(context).width * 0.85,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: lightPurple),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Directionality(
        textDirection: textDirectionFor(category.key),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              category.key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                fontFamily: 'Rubix',
              ),
              textAlign: textAlignFor(category.key),
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
    );
  }

  Widget buildCustomCategoriesSection(BuildContext context) {
    return Column(
      children: [
        ..._customCategories.map(buildCustomCategoryCard),
        if (_isAddingCustomCategory) buildCustomCategoryForm(context),
        if (!_isAddingCustomCategory)
          TextButton(
            onPressed: startAddingCustomCategory,
            child: myAutoSizedText(
              appLocale.sharePageAddCustomCategory,
              TextStyle(
                color: primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
              null,
              24,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: true);
    final gender = userInfoProvider.gender;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: returnSizedBox(context, 25),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: myAutoSizedText(
                      appLocale!.sharePageHeader(gender),
                      TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      null,
                      80),
                ),
                myAutoSizedText(
                    appLocale!.sharePageSubTitle(gender),
                    TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 16.sp,
                        color: Colors.black),
                    null,
                    35),
                myImage('assets/images/FormSubmit.png', context, 0.8, 0.4),
                Container(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: myAutoSizedText(
                      appLocale!.sharePageMidTitle(gender),
                      TextStyle(fontWeight: FontWeight.normal, fontSize: 18.sp),
                      null,
                      35),
                ),
                const SizedBox(
                  height: 30,
                ),
                Container(
                  width: MediaQuery.sizeOf(context).width * 0.5,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //share personal plan PDF button:
                        IconButton(
                          onPressed: () {
                            showShareDialog(context);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors
                                .white, // Set the background color to white
                            padding: const EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(7)),
                              side: BorderSide(
                                  color: primaryPurple), // Set the border color
                            ),
                          ),
                          icon: Icon(Icons.share,
                              color: primaryPurple), // Set the icon color
                          padding: const EdgeInsets.all(10),
                        ),
                        //download personal plan PDF button:
                        IconButton(
                          onPressed: () async {
                            var result = await fileService.download([
                              appLocale.difficultEventsHeader(gender),
                              appLocale.makeSaferHeader(gender),
                              appLocale.feelBetterHeader(gender),
                              appLocale.distractionsHeader(gender),
                              appLocale.phonesPageHeader(gender),
                            ], [
                              appLocale.difficultEventsSubTitle(gender),
                              appLocale.makeSaferSubTitle(gender),
                              appLocale.feelBetterSubTitle(gender),
                              appLocale.distractionsSubTitle(gender),
                              appLocale.phonesPageHeader(gender),
                            ], appInfoProvider.sharePDFtexts, ShareFileType.PDF,
                                appLocale.textDirection);
                            if (result == null) {
                              // Show him a message
                              showToast(
                                  message: appLocale!.downloadFailed(gender));
                              return;
                            }
                            // Show a toast message to the user
                            showToast(
                                message:
                                    appLocale!.finishedDownloading(gender));
                          },

                          style: TextButton.styleFrom(
                            backgroundColor: Colors
                                .white, // Set the background color to white
                            padding: const EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(7)),
                              side: BorderSide(
                                  color: primaryPurple), // Set the border color
                            ),
                          ),
                          icon: Icon(Icons.download,
                              color: primaryPurple), // Set the icon color
                          padding: const EdgeInsets.all(10),
                        ),
                      ]),
                ),
                const SizedBox(
                  height: 30,
                ),
                ConfirmationButton(context, () {
                  widget.submit(context);
                },
                    appLocale!.sharePageFinishButton(gender),
                    myTextStyle.copyWith(
                        fontWeight: FontWeight.bold, fontSize: 22.sp)),
                const SizedBox(
                  height: 16,
                ),
                buildCustomCategoriesSection(context),
                const SizedBox(
                  height: 30,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
