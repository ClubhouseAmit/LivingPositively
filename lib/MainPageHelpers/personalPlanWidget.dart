import 'package:fluttericon/elusive_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';

import 'package:mazilon/util/personalPlanItem.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/HomePage/sectionBarHome.dart';

import 'dart:math';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// the personal plan widget, thats related to the personal plan section in home page
class PersonalPlanWidget extends StatefulWidget {
  final Map<String, dynamic> text; // the text of the personal plan
  final Function(BuildContext, PagesCode)
  changeCurrentIndex; // the function to change the current index
  const PersonalPlanWidget({
    super.key,
    required this.text,
    required this.changeCurrentIndex,
  });

  @override
  State<PersonalPlanWidget> createState() => _PersonalPlanWidgetState();
}

class _PersonalPlanWidgetState extends LPExtendedState<PersonalPlanWidget> {
  late FileService fileService;
  late List<String> randomItems = ['1', '2'];
  List<String> feelBetter = [];
  void loadFeelBetter() {
    var random = Random();
    var index1 = 0;
    var index2 = 0;
    final items = List<String>.from(widget.text['list'] ?? const <String>[]);
    // taking two random items from the list of the feel better answers or other question
    // that user filled in the form
    if (items.length >= 2) {
      index1 = random.nextInt(items.length);
      do {
        index2 = random.nextInt(items.length);
      } while (index1 == index2);
      randomItems = [items[index1], items[index2]];
    } else if (items.length == 1) {
      index1 = 0;
      randomItems = [items[index1]];
    } else {
      randomItems = [];
    }
  }

  @override
  void initState() {
    super.initState();
    fileService = GetIt.instance<FileService>();
    loadFeelBetter();
  }

  @override
  void didUpdateWidget(PersonalPlanWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      loadFeelBetter();
    }
  }

  // the build function of the personal plan widget
  @override
  Widget build(BuildContext context) {
    // the providers of the app information and the user information
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          children: [
            // the section bar of the personal plan section in the home page,
            // with the title of the section and the icon of the section , and share and download buttons
            // and the sub title of the section, when the user presses the section bar,
            // it will take him to the personal plan page
            SectionBarHome(
              textWidget: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  widget.changeCurrentIndex(context, PagesCode.FullPlan);
                },
                // the title of the personal plan section in the home page
                child: myAutoSizedText(
                  appLocale.personalPlanPageMyPlan(gender),
                  TextStyle(
                    fontSize: 24.sp, // the font size of the title
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // the color of the title
                  ),
                  null,
                  40,
                ),
              ),
              icon: Icons.note_add, // the icon of the personal plan section
              icons: [
                // the share and download buttons
                myTextButton(
                  () async {
                    showShareDialog(context);
                    return;
                  },
                  Elusive.share,
                  Colors.black,
                  tooltip: appLocale.sharePlanTooltip,
                ),
                myTextButton(
                  () async {
                    // the function to download the pdf file of the personal plan
                    var result = await fileService.download(
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
                      showToast(message: appLocale.downloadFailed(gender));
                      return;
                    }
                    // Show a toast message to the user
                    showToast(message: appLocale.finishedDownloading(gender));
                  },
                  Icons.download,
                  Colors.black,
                  tooltip: appLocale.downloadPlanTooltip,
                ), // the download icon
              ],
              // the sub title of the personal plan section in the home page
              subHeader: widget.text['SubTitle'],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumn = constraints.maxWidth >= 520;
                final itemWidth = twoColumn
                    ? (constraints.maxWidth - 8) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: randomItems
                      .map(
                        (pPlan) => SizedBox(
                          width: itemWidth,
                          child: PersonalPlanItem(text: pPlan),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            // the button to take the user to the personal plan page.
            LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: TextButton(
                      key: const Key('personalPlanViewAllButton'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        widget.changeCurrentIndex(context, PagesCode.FullPlan);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: myAutoSizedText(
                              appLocale.personalPlanPageAllPlan(gender),
                              TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp, // the font size of the text
                              ),
                              TextAlign.start,
                              20,
                              2,
                            ),
                          ),
                          Icon(
                            appLocale.textDirection == "rtl"
                                ? Icons.arrow_left
                                : Icons.arrow_right,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
