// ignore_for_file: prefer_const_constructors, sort_child_properties_last

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/PersonalPlan/myPlan.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/util/userInformation.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mazilon/l10n/app_localizations.dart';

const String _customCategoryTitlesKey = 'customCategoryTitles';
const String _customCategoryDescriptionsKey = 'customCategoryDescriptions';

// This widget displays the user's personalized plan with sections for various topics.
// It allows the user to view their selected answers and navigate to additional forms or options.
class MyPlanPageFull extends StatefulWidget {
  final PhonePageData phonePageData; // Data related to phone numbers
  final bool hasFilled; // Whether the user has filled out the required forms
  final Function changeLocale;

  MyPlanPageFull(
      {super.key,
      required this.phonePageData,
      required this.hasFilled,
      required this.changeLocale});

  @override
  State<MyPlanPageFull> createState() => _MyPlanPageFullState();
}

class _MyPlanPageFullState extends LPExtendedState<MyPlanPageFull> {
  List<List<String>> userAnswers = []; // User's answers for each section
  List<String> phoneInformation = []; // User's phone-related information
  final List<MapEntry<String, String>> customCategories = [];

  // Field names for different sections of the personal plan
  List<String> fieldNames = [
    'PersonalPlan-DifficultEvents',
    'PersonalPlan-MakeSafer',
    'PersonalPlan-FeelBetter',
    'PersonalPlan-Distractions'
  ];

  // Names for the providers managing each section
  List<String> providerNames = [
    'difficultEvents',
    'makeSafer',
    'feelBetter',
    'distractions'
  ];

  // Retrieve the user's answers for each section and update the state
  void getUserAnswers(userSelectionDifficultEvents, userSelectionMakeSafer,
      userSelectionFeelBetter, userSelectionDistractions) {
    setState(() {
      userAnswers = [
        userSelectionDifficultEvents,
        userSelectionMakeSafer,
        userSelectionFeelBetter,
        userSelectionDistractions
      ];
    });
  }

  // Combine phone names and numbers into a formatted string and update the state
  void setPhones(names, numbers) {
    List<String> temp = [];
    for (var i = 0; i < names.length; i++) {
      temp.add(names[i] + ':' + numbers[i]);
    }
    setState(() {
      phoneInformation = [...temp];
    });
  }

  // Launch a URL in the default browser
  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  initState() {
    super.initState();
    loadCustomCategories();
  }

  Future<void> loadCustomCategories() async {
    if (!GetIt.instance.isRegistered<PersistentMemoryService>()) {
      return;
    }

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
      customCategories
        ..clear()
        ..addAll(loadedCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Providers to get app and user information
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: true);

    // Set up phone and answer information based on the user's data
    setPhones(widget.phonePageData.savedPhoneNames,
        widget.phonePageData.savedPhoneNumbers);
    getUserAnswers(userInfoProvider.difficultEvents, userInfoProvider.makeSafer,
        userInfoProvider.feelBetter, userInfoProvider.distractions);

    final gender = userInfoProvider.gender;
    Map<String, String> texts = appInfoProvider.sharePDFtexts;

    // Extract relevant texts for display of the bottom text
    String text1 = texts['firstLine'] ?? '';
    String text2 = texts['firstLinkText'] ?? '';
    String text2Link = texts['firstLinkURL'] ?? '';
    String text3 = texts['secondLine'] ?? '';
    String text4 = texts['thirdLine'] ?? '';
    String text5 = texts['secondLinkText'] ?? '';
    String text5Link = texts['secondLinkURL'] ?? '';
    String text6 = texts['forthLine'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          title: SingleChildScrollView(
            child: Center(
                child: myAutoSizedText(
                    appLocale!.personalPlanPageMyPlan(gender),
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 30.sp),
                    null,
                    40)),
          ),
          backgroundColor: primaryPurple,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25.0),
                  bottomRight: Radius.circular(25.0))),
          toolbarHeight: 100),
      body: SingleChildScrollView(
        child: Column(
          // Main content area for displaying the user's plan
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display a list of plan sections with their corresponding answers
            ListView.builder(
              itemBuilder: (context, index) {
                var info = retrieveInformation(
                    fieldNames[index], userInfoProvider.gender, appLocale);

                return MyPlanSection(
                  title: info["header"] ?? '',
                  subTitle: info["subTitle"] ?? '',
                  answers: userAnswers[index],
                );
              },
              itemCount: 4,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
            ),
            // Additional section for phone-related information
            MyPlanSection(
              title: appLocale!.phonesPageHeader(gender),
              subTitle: appLocale!.phonesPageSubTitle(gender),
              answers: phoneInformation,
            ),
            ...customCategories.map(
              (category) => MyPlanSection(
                title: category.key,
                subTitle: '',
                answers: [category.value],
              ),
            ),
            SizedBox(
              height: 30,
            ),
            // Display additional text with links, if available
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              appLocale.localeName != 'he'
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(children: <TextSpan>[
                            TextSpan(
                              text: text1 + " ",
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black),
                            ),
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap =
                                    () => _launchURL(Uri.parse(text2Link)),
                              text: text2 + " ",
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                  color: Color.fromARGB(255, 6, 25, 231)),
                            ),
                            TextSpan(
                              text: text3 + " ",
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black),
                            ),
                            TextSpan(
                              text: text4 + " ",
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black),
                            ),
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap =
                                    () => _launchURL(Uri.parse(text5Link)),
                              text: text5 + " ",
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                  color: Color.fromARGB(255, 6, 25, 231)),
                            ),
                            TextSpan(
                              text: text6 + ".",
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black),
                            ),
                          ]))),
            ]),
            SizedBox(
              height: 30,
            ),
            // Button to navigate to another form or action
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FormProgressIndicator(
                      phonePageData: widget.phonePageData,
                      changeLocale: widget.changeLocale,
                    ), //place collections here
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      var begin = Offset(-1.0, 0.0);
                      var end = Offset.zero;
                      var tween = Tween(begin: begin, end: end);
                      var offsetAnimation = animation.drive(tween);

                      var fadeTween = Tween(begin: 0.0, end: 1.0);
                      var fadeAnimation = animation.drive(fadeTween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: child,
                        ),
                      );
                    },
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: primaryPurple,
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              child: myAutoSizedText(
                  widget.hasFilled
                      ? appLocale!.personalPlanPageHasFilled(gender)
                      : appLocale!.personalPlanPageDidNotFill(gender),
                  TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  null,
                  24),
            ),
            SizedBox(
              height: 45,
            ),
          ],
        ),
      ),
    );
  }
}
