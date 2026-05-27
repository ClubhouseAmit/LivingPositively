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
    // taking two random items from the list of the feel better answers or other question
    // that user filled in the form
    if (widget.text['list'].length >= 2) {
      index1 = random.nextInt(widget.text['list'].length);
      do {
        index2 = random.nextInt(widget.text['list'].length);
      } while (index1 == index2);
      setState(() {
        randomItems = [
          widget.text['list'][index1],
          widget.text['list'][index2],
        ];
      });
    } else if (widget.text['list'].length == 1) {
      index1 = 0;
      setState(() {
        randomItems = [widget.text['list'][index1]];
      });
    } else {
      setState(() {
        randomItems = [];
      });
    }
  }

  @override
  void initState() {
    fileService = GetIt.instance<FileService>();
    loadFeelBetter();
    super.initState();
  }

  // the build function of the personal plan widget
  @override
  Widget build(BuildContext context) {
    loadFeelBetter();
    // the providers of the app information and the user information
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    return Container(
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
                onPressed: () {
                  widget.changeCurrentIndex(context, PagesCode.FullPlan);
                },
                // the title of the personal plan section in the home page
                child: myAutoSizedText(
                  appLocale!.personalPlanPageMyPlan(gender),
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
                  tooltip: appLocale!.sharePlanTooltip,
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
                      showToast(message: appLocale!.downloadFailed(gender));
                      return;
                    }
                    // Show a toast message to the user
                    showToast(message: appLocale!.finishedDownloading(gender));
                  },
                  Icons.download,
                  Colors.black,
                  tooltip: appLocale!.downloadPlanTooltip,
                ), // the download icon
              ],
              // the sub title of the personal plan section in the home page
              subHeader: widget.text['SubTitle'],
            ),
            GridView.count(
              crossAxisCount: 2, // Set the number of items in each row
              crossAxisSpacing: 5,
              childAspectRatio: 12 / 4,
              shrinkWrap:
                  true, // Use this if the GridView is inside another scrolling widget
              physics:
                  const NeverScrollableScrollPhysics(), // Adjust this value as needed to change the aspect ratio of the items
              // the personal plan items that the user filled in the form
              children: randomItems
                  .map(
                    (pPlan) => Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 2.0,
                        start: 5,
                      ),
                      child: PersonalPlanItem(text: pPlan),
                    ),
                  )
                  .toList(),
              // Use this if the GridView is inside another scrolling widget
            ),
            // the button to take the user to the personal plan page.
            // `button: true` adds the role; the visible text inside is left
            // as the announced label so we don't double-announce.
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: () {
                  widget.changeCurrentIndex(context, PagesCode.FullPlan);
                  // Handle the button tap here
                },
                child: Row(
                  children: [
                    myAutoSizedText(
                      appLocale!.personalPlanPageAllPlan(gender),
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp, // the font size of the text
                      ),
                      null,
                      20,
                    ),
                    Icon(
                      appLocale!.textDirection == "rtl"
                          ? Icons.arrow_left
                          : Icons.arrow_right,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
