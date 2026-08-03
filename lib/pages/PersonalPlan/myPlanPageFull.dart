// ignore_for_file: prefer_const_constructors

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/PersonalPlan/myPlan.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const String _customCategoryTitlesKey = 'customCategoryTitles';
const String _customCategoryDescriptionsKey = 'customCategoryDescriptions';

// This widget displays the user's personalized plan with sections for various topics.
// It allows the user to view their selected answers and navigate to additional forms or options.
class MyPlanPageFull extends StatefulWidget {
  const MyPlanPageFull({
    required this.phonePageData,
    required this.hasFilled,
    required this.changeLocale,
    super.key,
  });
  final PhonePageData phonePageData; // Data related to phone numbers
  final bool hasFilled; // Whether the user has filled out the required forms
  final Function changeLocale;

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
    'PersonalPlan-Distractions',
  ];

  // Names for the providers managing each section
  List<String> providerNames = [
    'difficultEvents',
    'makeSafer',
    'feelBetter',
    'distractions',
  ];

  // Retrieve the user's answers for each section and update the state
  void getUserAnswers(
    userSelectionDifficultEvents,
    userSelectionMakeSafer,
    userSelectionFeelBetter,
    userSelectionDistractions,
  ) {
    setState(() {
      userAnswers = [
        userSelectionDifficultEvents,
        userSelectionMakeSafer,
        userSelectionFeelBetter,
        userSelectionDistractions,
      ];
    });
  }

  // Combine phone names and numbers into a formatted string and update the state
  void setPhones(names, numbers) {
    final temp = <String>[];
    for (var i = 0; i < names.length; i++) {
      temp.add('${names[i]}:${numbers[i]}');
    }
    setState(() {
      phoneInformation = [...temp];
    });
  }

  // Launch a URL in the default browser
  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    loadCustomCategories();
  }

  Future<void> loadCustomCategories() async {
    if (!GetIt.instance.isRegistered<PersistentMemoryService>()) {
      return;
    }

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
      customCategories
        ..clear()
        ..addAll(loadedCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Providers to get app and user information
    final appInfoProvider = Provider.of<AppInformation>(context);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );

    // Set up phone and answer information based on the user's data
    setPhones(
      widget.phonePageData.savedPhoneNames,
      widget.phonePageData.savedPhoneNumbers,
    );
    getUserAnswers(
      userInfoProvider.difficultEvents,
      userInfoProvider.makeSafer,
      userInfoProvider.feelBetter,
      userInfoProvider.distractions,
    );

    final gender = userInfoProvider.gender;
    final texts = appInfoProvider.sharePDFtexts;

    // Extract relevant texts for display of the bottom text
    final text1 = texts['firstLine'] ?? '';
    final text2 = texts['firstLinkText'] ?? '';
    final text2Link = texts['firstLinkURL'] ?? '';
    final text3 = texts['secondLine'] ?? '';
    final text4 = texts['thirdLine'] ?? '';
    final text5 = texts['secondLinkText'] ?? '';
    final text5Link = texts['secondLinkURL'] ?? '';
    final text6 = texts['forthLine'] ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return PageLayoutWrapper(
      sliverAppBar: PremiumGlassAppBar(
        variant: AppBarVariant.rootTab,
        titleText: appLocale.personalPlanPageMyPlan(gender),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Spacing.md),
          ListView.builder(
            itemBuilder: (context, index) {
              final info = retrieveInformation(
                fieldNames[index],
                userInfoProvider.gender,
                appLocale,
              );

              return MyPlanSection(
                title: info['header'] ?? '',
                subTitle: info['subTitle'] ?? '',
                answers: userAnswers[index],
              );
            },
            itemCount: 4,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
          ),
          // Additional section for phone-related information
          MyPlanSection(
            title: appLocale.phonesPageHeader(gender),
            subTitle: appLocale.phonesPageSubTitle(gender),
            answers: phoneInformation,
          ),
          ...customCategories.map(
            (category) => MyPlanSection(
              title: category.key,
              subTitle: '',
              answers: [category.value],
            ),
          ),
          SizedBox(height: Spacing.lg),
          // Display additional text with links, if available
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (appLocale.localeName != 'he')
                Container()
              else
                Padding(
                  padding: EdgeInsets.all(Spacing.sm),
                  child: RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '$text1 ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchURL(Uri.parse(text2Link)),
                          text: '$text2 ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text: '$text3 ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: '$text4 ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchURL(Uri.parse(text5Link)),
                          text: '$text5 ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text: '$text6.',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: Spacing.lg),
          // Button to navigate to another form or action
          Center(
            child: TextButton(
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
                          final begin = Offset(-1, 0);
                          const end = Offset.zero;
                          final tween = Tween(begin: begin, end: end);
                          final offsetAnimation = animation.drive(tween);

                          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
                          final fadeAnimation = animation.drive(fadeTween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: fadeAnimation,
                              child: child,
                            ),
                          );
                        },
                  ),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.md,
                ),
                // shape: const RoundedRectangleBorder(
                //   borderRadius: BorderRadius.all(Radius.circular(20)),
                // ),
              ),
              child: AutoSizeText(
                widget.hasFilled
                    ? appLocale.personalPlanPageHasFilled(gender)
                    : appLocale.personalPlanPageDidNotFill(gender),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          SizedBox(height: Spacing.bottomPadding),
        ],
      ),
    );
  }
}
