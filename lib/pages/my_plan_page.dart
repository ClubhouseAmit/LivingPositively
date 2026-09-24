import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/features/personal_plan/ui/personal_plan_custom_categories_section.dart';
import 'package:mazilon/features/personal_plan/ui/my_plan_section.dart';
import 'package:mazilon/features/personal_plan/ui/personal_plan_info_button.dart';
import 'package:mazilon/features/personal_plan/ui/retrieveInformation.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/pages/personal_plan_editor_page.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/util/userInformation.dart';

import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

// This widget displays the user's personalized plan with sections for various topics.
// It allows the user to view their selected answers and navigate to additional forms or options.
class MyPlanPageFull extends StatefulWidget {
  final PhonePageData phonePageData; // Data related to phone numbers
  final bool hasFilled; // Whether the user has filled out the required forms
  final Function changeLocale;
  final PersistentMemoryService? memoryService;

  const MyPlanPageFull({
    super.key,
    required this.phonePageData,
    required this.hasFilled,
    required this.changeLocale,
    this.memoryService,
  });

  @override
  _MyPlanPageFullState createState() => _MyPlanPageFullState();
}

class _MyPlanPageFullState extends LPExtendedState<MyPlanPageFull> {
  List<List<String>> userAnswers = []; // User's answers for each section
  List<String> phoneInformation = []; // User's phone-related information

  // Field names for different sections of the personal plan
  List<String> fieldNames = [
    'PersonalPlan-Distractions',
    'PersonalPlan-DifficultEvents',
    'PersonalPlan-FeelBetter',
    'PersonalPlan-MakeSafer',
    'PersonalPlan-SafeEnvironment',
    'PersonalPlan-DreamsAndGoals',
  ];

  // Names for the providers managing each section
  List<String> providerNames = [
    'distractions',
    'difficultEvents',
    'feelBetter',
    'makeSafer',
    'safeEnvironment',
    'dreamsAndGoals',
  ];

  // Retrieve the user's answers for each section and update the state
  void getUserAnswers(
    List<String> distractions,
    List<String> difficultEvents,
    List<String> feelBetter,
    List<String> makeSafer,
    List<String> safeEnvironment,
    List<String> dreamsAndGoals,
  ) {
    userAnswers = [
      distractions,
      difficultEvents,
      feelBetter,
      makeSafer,
      safeEnvironment,
      dreamsAndGoals,
    ];
  }

  // Combine and format the phone-related information
  void setPhones(List<String> names, List<String> numbers) {
    phoneInformation = [];
    final count = math.min(names.length, numbers.length);
    for (var i = 0; i < count; i++) {
      phoneInformation.add('${names[i]}:${numbers[i]}');
    }
  }

  // Opens a specified URL using url_launcher
  void _launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    setPhones(
      widget.phonePageData.savedPhoneNames,
      widget.phonePageData.savedPhoneNumbers,
    );
    getUserAnswers(
      userInfoProvider.distractions,
      userInfoProvider.difficultEvents,
      userInfoProvider.feelBetter,
      userInfoProvider.makeSafer,
      userInfoProvider.safeEnvironment,
      userInfoProvider.dreamsAndGoals,
    );

    final gender = userInfoProvider.gender;
    final colorScheme = Theme.of(context).colorScheme;
    final texts = appInfoProvider.sharePDFtexts;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _planHeader(gender, colorScheme),
            ..._planSections(userInfoProvider, gender),
            const SizedBox(height: AppSpacing.xxxl),
            _shareFooter(texts, colorScheme),
            const SizedBox(height: AppSpacing.xxxl),
            _editPlanButton(gender, colorScheme),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _planHeader(String gender, ColorScheme colorScheme) {
    return Material(
      color: colorScheme.primary,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.dashedAddSlot),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Row(
            children: [
              Expanded(
                child: myAutoSizedText(
                  appLocale.personalPlanPageMyPlan(gender),
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.sp,
                    color: colorScheme.onPrimary,
                  ),
                  null,
                  40,
                ),
              ),
              DecoratedBox(
                decoration: ShapeDecoration(
                  shape: CircleBorder(
                    side: BorderSide(
                      color: colorScheme.onPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
                child: const PersonalPlanInfoButton(
                  actionKey: Key('fullPlanInfoButton'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _planSections(UserInformation userInfo, String gender) {
    final safeEnvironmentInfo = retrieveInformation(
      fieldNames[4],
      gender,
      appLocale,
    );
    final dreamsAndGoalsInfo = retrieveInformation(
      fieldNames[5],
      gender,
      appLocale,
    );
    return [
      ListView.builder(
        itemBuilder: (context, index) {
          final info = retrieveInformation(
            fieldNames[index],
            gender,
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
        physics: const NeverScrollableScrollPhysics(),
      ),
      MyPlanSection(
        title: appLocale.phonesPageHeader(gender),
        subTitle: appLocale.phonesPageSubTitle(gender),
        answers: phoneInformation,
      ),
      MyPlanSection(
        title: safeEnvironmentInfo['header'] ?? '',
        subTitle: safeEnvironmentInfo['subTitle'] ?? '',
        answers: userAnswers[4],
      ),
      if (userAnswers[5].isNotEmpty)
        MyPlanSection(
          title: dreamsAndGoalsInfo['header'] ?? '',
          subTitle: dreamsAndGoalsInfo['subTitle'] ?? '',
          answers: userAnswers[5],
        ),
      PersonalPlanCustomCategoriesSection(
        userInformation: userInfo,
        memoryService: widget.memoryService,
      ),
    ];
  }

  Widget _shareFooter(Map<String, String> texts, ColorScheme colorScheme) {
    if (appLocale.localeName != 'he') {
      return const SizedBox.shrink();
    }
    final text1 = texts['firstLine'] ?? '';
    final text2 = texts['firstLinkText'] ?? '';
    final text2Link = texts['firstLinkURL'] ?? '';
    final text3 = texts['secondLine'] ?? '';
    final text4 = texts['thirdLine'] ?? '';
    final text5 = texts['secondLinkText'] ?? '';
    final text5Link = texts['secondLinkURL'] ?? '';
    final text6 = texts['forthLine'] ?? '';
    TextStyle bodyStyle({required Color color}) => TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: '$text1 ',
              style: bodyStyle(color: colorScheme.onSurface),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () => _launchURL(Uri.parse(text2Link)),
              text: '$text2 ',
              style: bodyStyle(color: colorScheme.primary),
            ),
            TextSpan(
              text: '$text3 ',
              style: bodyStyle(color: colorScheme.onSurface),
            ),
            TextSpan(
              text: '$text4 ',
              style: bodyStyle(color: colorScheme.onSurface),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () => _launchURL(Uri.parse(text5Link)),
              text: '$text5 ',
              style: bodyStyle(color: colorScheme.primary),
            ),
            TextSpan(
              text: '$text6.',
              style: bodyStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editPlanButton(String gender, ColorScheme colorScheme) {
    return TextButton(
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FormProgressIndicator(
                  phonePageData: widget.phonePageData,
                  changeLocale: widget.changeLocale,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final offsetAnimation = animation.drive(
                    Tween(begin: const Offset(-1, 0), end: Offset.zero),
                  );
                  final fadeAnimation = animation.drive(
                    Tween(begin: 0.0, end: 1.0),
                  );
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
      ),
      child: myAutoSizedText(
        widget.hasFilled
            ? appLocale.personalPlanPageHasFilled(gender)
            : appLocale.personalPlanPageDidNotFill(gender),
        TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimary,
        ),
        null,
        24,
      ),
    );
  }
}
