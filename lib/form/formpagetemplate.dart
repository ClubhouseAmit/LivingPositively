import 'package:auto_size_text/auto_size_text.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/FormAnswer.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class FormPageTemplate extends StatefulWidget {

  const FormPageTemplate({
    required this.next, required this.prev, required this.collectionName, super.key,
  });
  //next page:
  final Function next;
  //prev page:
  final Function prev;

  final String collectionName;

  @override
  State<FormPageTemplate> createState() => _FormPageTemplateState();
}

class _FormPageTemplateState extends LPExtendedState<FormPageTemplate> {
  final TextEditingController _controller = TextEditingController();
  int displayedLength = 3;
  int length = 0;
  List<String> selectedItems = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isAlreadySelected(String item) {
    return selectedItems.contains(item);
  }

  void editItem(int index, String text) {
    selectedItems[index] = text;
    setState(() {});
  }

  void removeItem(int index) {
    final text = selectedItems[index];
    selectedItems.removeWhere((element) => element == text);

    setState(() {});
  }

  void addItem(String text) {
    selectedItems.add(text.trim());

    setState(() {});
  }

  //generate 3 items in the database items list at the bottom of the screen:
  void addSuggestion() {
    if (length > displayedLength + 3) {
      displayedLength = displayedLength + 3;
    } else {
      displayedLength = length;
    }

    setState(() {});
  }

  Future<void> createSelection(UserInformation userInfo) async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    switch (widget.collectionName) {
      case 'PersonalPlan-DifficultEvents':
        userInfo.updateDifficultEvents([...selectedItems]);
      case 'PersonalPlan-MakeSafer':
        userInfo.updateMakeSafer([...selectedItems]);
      case 'PersonalPlan-FeelBetter':
        userInfo.updateFeelBetter([...selectedItems]);
      case 'PersonalPlan-Distractions':
        userInfo.updateDistractions([...selectedItems]);
      default:
    }
    await service.setItem(
      'disclaimerConfirmed',
      PersistentMemoryType.Bool,
      true,
    );
    await service.setItem(
      'userSelection${widget.collectionName}',
      PersistentMemoryType.StringList,
      [...selectedItems],
    );
    await service.setItem(
      'addedStrings${widget.collectionName}',
      PersistentMemoryType.StringList,
      [...selectedItems],
    );
  }

  void loadItems(UserInformation userInfo) {
    switch (widget.collectionName) {
      case 'PersonalPlan-DifficultEvents':
        selectedItems = [...userInfo.difficultEvents];
      case 'PersonalPlan-MakeSafer':
        selectedItems = [...userInfo.makeSafer];
      case 'PersonalPlan-FeelBetter':
        selectedItems = [...userInfo.feelBetter];
      case 'PersonalPlan-Distractions':
        selectedItems = [...userInfo.distractions];
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    final gender = userInfoProvider.gender;

    final displayInformation = retrieveInformation(
      widget.collectionName,
      gender,
      appLocale,
    );
    length = (displayInformation['list'] as List<dynamic>).length;
    loadItems(userInfoProvider);
    var validate = false;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                const SizedBox(height: Spacing.md),
                Column(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Semantics(
                        header: true,
                        child: AutoSizeText(
                          displayInformation['header'] as String,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      alignment: Alignment.topCenter,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: AutoSizeText(
                        displayInformation['subTitle'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.outline,
                              height: 1.3,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: selectedItems.length,
                  itemBuilder: (context, index) {
                    return FormAnswer(
                      text: selectedItems[index],
                      num: index + 1,
                      edit: (int index2, String text) {
                        editItem(index2, text);
                        createSelection(userInfoProvider);
                      },
                      remove: (int index2) {
                        removeItem(index2);
                        createSelection(userInfoProvider);
                      },
                    );
                  },
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Row(
                    
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      TextButton(
                        onPressed: () {
                          if (_controller.text.isEmpty) {
                            validate = true;
                          } else {
                            validate = false;
                            addItem(_controller.text);
                            createSelection(userInfoProvider);
                            _controller.clear();
                            setState(() {});
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface, // This is the color of the text
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest, // This is the background color of the button
                          shape: RoundedRectangleBorder(
                            // This is the shape of the button
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // This is the border radius
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface,
                            ), // This is the border color
                          ),
                          padding: const EdgeInsets.all(
                            10,
                          ), // This is the padding inside the button
                        ),
                        child: AutoSizeText(
                          appLocale.addFormPageTemplateAdd(gender),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          style: Theme.of(context).textTheme.bodyLarge,
                          controller: _controller,
                          decoration: InputDecoration(
                            errorText: validate
                                ? appLocale.validateEmpty
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Column(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: AutoSizeText(
                        displayInformation['midTitle'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      alignment: Alignment.topCenter,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: AutoSizeText(
                        displayInformation['midSubTitle'],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.outline,
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: displayedLength,
                  itemBuilder: (context, index) {
                    final String item = displayInformation['list'][index];
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 15,
                      ),
                      activeColor: Theme.of(context).colorScheme.tertiary,
                      checkboxShape: const CircleBorder(),
                      visualDensity: VisualDensity.compact,
                      title: isAlreadySelected(item)
                          ? DottedBorder(
                              options: RoundedRectDottedBorderOptions(
                                radius: const Radius.circular(20),
                                dashPattern: const [5, 5],
                                color: Theme.of(context).colorScheme.tertiary,
                                strokeWidth: 2,
                              ),
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                constraints: const BoxConstraints(minHeight: 55),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : DottedBorder(
                              options: RoundedRectDottedBorderOptions(
                                radius: const Radius.circular(20),
                                dashPattern: const [5, 5],
                                color: Theme.of(context).colorScheme.tertiary,
                                strokeWidth: 2,
                              ),
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                constraints: const BoxConstraints(minHeight: 55),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                      value: isAlreadySelected(item),
                      onChanged: (value) {
                        setState(() {
                          if (value != null) {
                            if (isAlreadySelected(item)) {
                              removeItem(selectedItems.indexOf(item));
                            } else {
                              addItem(item);
                            }
                            createSelection(userInfoProvider);
                          }
                        });
                      },
                    );
                  },
                ),
                //add more button:
                if (displayedLength < displayInformation['list'].length) TextButton(
                        onPressed: addSuggestion,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface, // This is the color of the text
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest, // This is the background color of the button
                          shape: RoundedRectangleBorder(
                            // This is the shape of the button
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // This is the border radius
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface,
                            ), // This is the border color
                          ),
                          padding: const EdgeInsets.all(
                            0,
                          ), // This is the padding inside the button
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: AutoSizeText(
                            displayInformation['showMoreButtonText'],
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ) else const SizedBox(height: Spacing.md),
                //spacing between add more and next button:
                const SizedBox(height: Spacing.md),
                //next button:
                ElevatedButton(
                  onPressed: () {
                    final mixPanelService =
                        GetIt.instance<AnalyticsService>();
                    mixPanelService.trackEvent('Plan edited', {
                      'page': widget.collectionName,
                    });
                    createSelection(userInfoProvider);
                    widget.next();
                  },
                  child: Text(displayInformation['nextButtonText']),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
  }
}
