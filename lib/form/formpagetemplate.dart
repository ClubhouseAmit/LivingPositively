import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';

import 'package:mazilon/pages/FormAnswer.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/styles.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';

class FormPageTemplate extends StatefulWidget {
  //next page:
  final Function next;
  //prev page:
  final Function prev;

  final String collectionName;

  const FormPageTemplate({
    super.key,
    required this.next,
    required this.prev,
    required this.collectionName,
  });

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

  void createSelection(userInfo) async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    switch (widget.collectionName) {
      case 'PersonalPlan-DifficultEvents':
        userInfo.updateDifficultEvents([...selectedItems]);
        break;
      case 'PersonalPlan-MakeSafer':
        userInfo.updateMakeSafer([...selectedItems]);
        break;
      case 'PersonalPlan-FeelBetter':
        userInfo.updateFeelBetter([...selectedItems]);
        break;
      case 'PersonalPlan-Distractions':
        userInfo.updateDistractions([...selectedItems]);
        break;
      default:
    }
    await service.setItem(
      "disclaimerConfirmed",
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

  void loadItems(userInfo) {
    switch (widget.collectionName) {
      case 'PersonalPlan-DifficultEvents':
        selectedItems = [...userInfo.difficultEvents];
        break;
      case 'PersonalPlan-MakeSafer':
        selectedItems = [...userInfo.makeSafer];
        break;
      case 'PersonalPlan-FeelBetter':
        selectedItems = [...userInfo.feelBetter];
        break;
      case 'PersonalPlan-Distractions':
        selectedItems = [...userInfo.distractions];
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    Map<String, dynamic> displayInformation = retrieveInformation(
      widget.collectionName,
      gender,
      appLocale,
    );
    length = displayInformation['list'].length;
    loadItems(userInfoProvider);
    bool validate = false;
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          //widthFactor: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      child: myAutoSizedText(
                        displayInformation['header'],
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                          height: 1.5,
                        ),
                        TextAlign.center,
                        40,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      alignment: Alignment.topCenter,
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      child: myAutoSizedText(
                        displayInformation['subTitle'],
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                          fontSize: 14.sp,
                          height: 1.3,
                        ),
                        TextAlign.center,
                        25,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Flexible(
                  fit: FlexFit.loose,
                  //generate list based on added strings(strings the user chose to manually add
                  // or items chosen from database item list at the bottom of the screen):
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: selectedItems.length,
                    itemBuilder: (context, index) {
                      return FormAnswer(
                        text: selectedItems[index],
                        num: (index + 1),
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
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 1000
                      ? 800
                      : MediaQuery.of(context).size.width,
                  child: Row(
                    //mainAxisSize: MediaQuery.of(context).size.width,
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
                          foregroundColor:
                              Colors.black, // This is the color of the text
                          backgroundColor: Colors
                              .white, // This is the background color of the button
                          shape: RoundedRectangleBorder(
                            // This is the shape of the button
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // This is the border radius
                            side: const BorderSide(
                              color: Colors.black,
                            ), // This is the border color
                          ),
                          padding: const EdgeInsets.all(
                            10,
                          ), // This is the padding inside the button
                        ),
                        child: myAutoSizedText(
                          appLocale.addFormPageTemplateAdd(gender),
                          TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                          null,
                          20,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 14.sp > 40 ? 40 : 14.sp,
                          ),
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
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      child: myAutoSizedText(
                        displayInformation['midTitle'],
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
                        TextAlign.center,
                        40,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      alignment: Alignment.topCenter,
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      child: myAutoSizedText(
                        displayInformation['midSubTitle'],
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                        TextAlign.center,
                        25,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Flexible(
                  fit: FlexFit.loose,
                  //database items(rowy) check box list:
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: displayedLength,
                    itemBuilder: (context, index) {
                      String item = displayInformation["list"][index];
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 15.0,
                        ),
                        activeColor: appGreen,
                        checkboxShape: CircleBorder(),
                        visualDensity: VisualDensity.compact,
                        title: isAlreadySelected(item)
                            ? DottedBorder(
                                options: RoundedRectDottedBorderOptions(
                                  radius: const Radius.circular(20),
                                  dashPattern: const [5, 5],
                                  color: appGreen,
                                  strokeWidth: 2,
                                ),
                                child: Container(
                                  alignment: appLocale.textDirection == "rtl"
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  constraints: BoxConstraints(minHeight: 55),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontFamily: "Rubix",
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              )
                            : DottedBorder(
                                options: RoundedRectDottedBorderOptions(
                                  radius: const Radius.circular(20),
                                  dashPattern: const [5, 5],
                                  color: appGreen,
                                  strokeWidth: 2,
                                ),
                                child: Container(
                                  alignment: appLocale.textDirection == "rtl"
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  //height: returnSizedBox(context, 70),
                                  constraints: BoxConstraints(minHeight: 55),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    //border: Border.all(color: Color.fromARGB(255, 187, 167, 235))
                                  ),
                                  //color: widget.answer1.contains(widget.suggestions[index]) ? Colors.transparent : Color.fromARGB(255, 223, 218, 218),
                                  child: Text(
                                    item,

                                    //overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: "Rubix",
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                        value: isAlreadySelected(item),
                        onChanged: (bool? value) {
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
                ),
                //add more button:
                displayedLength < displayInformation['list'].length
                    ? TextButton(
                        onPressed: () {
                          addSuggestion();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Colors.black, // This is the color of the text
                          backgroundColor: Colors
                              .white, // This is the background color of the button
                          shape: RoundedRectangleBorder(
                            // This is the shape of the button
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // This is the border radius
                            side: const BorderSide(
                              color: Colors.black,
                            ), // This is the border color
                          ),
                          padding: const EdgeInsets.all(
                            0,
                          ), // This is the padding inside the button
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: myAutoSizedText(
                            displayInformation['showMoreButtonText'],
                            TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                            null,
                            40,
                          ),
                        ),
                      )
                    //nothing to add:
                    : SizedBox(height: returnSizedBox(context, 10)),
                //spacing between add more and next button:
                SizedBox(height: returnSizedBox(context, 10)),
                //next button:
                ConfirmationButton(
                  context,
                  () {
                    AnalyticsService mixPanelService =
                        GetIt.instance<AnalyticsService>();
                    mixPanelService.trackEvent("Plan edited", {
                      'page': widget.collectionName,
                    });
                    createSelection(userInfoProvider);
                    widget.next();
                  },
                  displayInformation['nextButtonText'],
                  myTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
