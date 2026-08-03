//import 'package:mazilon/initialForm/toFormPage.dart';
//import 'package:mazilon/menu.dart';
//import 'package:mazilon/util/myTextButton.dart';
//import 'package:mazilon/util/Reminders/reminder.dart';
//import 'package:mazilon/MainPageHelpers/reminderWidget.dart';
//import 'package:mazilon/depricated/Warning/warningSignsWidget.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_widget.dart';
import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/HomePage/inspirationalQuote.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

//the main page of the app
//allows navigation to all other pages
class Home extends StatefulWidget {

  const Home({
    required this.phonePageData, required this.changeCurrentIndex, required this.changeLocale, required this.openMainMenu, super.key,
  });
  final PhonePageData phonePageData;
  final Function(BuildContext, PagesCode) changeCurrentIndex;
  final Function changeLocale;
  final void Function(BuildContext) openMainMenu;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends LPExtendedState<Home> {
  String greetingString = '';
  String fileButtonString = '';

  List<String> traits = [];

  bool hasFilled = false;
  Map<String, dynamic> homeTitles = {};
  int? _selectedPersonalPlanIndex;

  //load information about the user from shared preferences
  Future<void> loadData() async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    final hasFilledValue = (await service.getItem(
      'hasFilled',
      PersistentMemoryType.Bool,
    ) as bool?) ?? false;

    if (!mounted) {
      return;
    }
    setState(() {
      hasFilled = hasFilledValue;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  //fuction to handle the removal of a thank you

  //this selects what information to show in the personal plan widget boxes
  void setRandomPersonalWidgetText(
    UserInformation userInfo,
    AppLocalizations appLocale,
  ) {
    _selectedPersonalPlanIndex ??= Random().nextInt(4);

    switch (_selectedPersonalPlanIndex) {
      case 0:
        homeTitles = {
          'SubTitle': appLocale.makeSaferSubTitle(userInfo.gender),
          'list': userInfo.makeSafer,
        };
      case 1:
        homeTitles = {
          'SubTitle': appLocale.difficultEventsSubTitle(userInfo.gender),
          'list': userInfo.difficultEvents,
        };
      case 2:
        homeTitles = {
          'SubTitle': appLocale.feelBetterSubTitle(userInfo.gender),
          'list': userInfo.feelBetter,
        };
      case 3:
        homeTitles = {
          'SubTitle': appLocale.distractionsSubTitle(userInfo.gender),
          'list': userInfo.distractions,
        };
      default:
        homeTitles = {'SubTitle': '', 'list': []};
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    setRandomPersonalWidgetText(userInfoProvider, appLocale);
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    final gender = userInfoProvider.gender;
    final colorScheme = Theme.of(context).colorScheme;

    return PageLayoutWrapper(
      sliverAppBar: PremiumGlassAppBar(
        variant: AppBarVariant.rootTab,
        isHome: true,
        titleText: '',
        actions: [
          Builder(
            builder: (menuButtonContext) => IconButton(
              key: const Key('homeSettingsButton'),
              icon: Icon(
                LucideIcons.settings,
                color: colorScheme.primary,
              ),
              onPressed: () => widget.openMainMenu(menuButtonContext),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Spacing.md),
          Text(
            appLocale.greetings(userInfoProvider.name),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: Spacing.xs),
          Text(
            appLocale.homePageGreetings(gender),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          SizedBox(height: Spacing.lg),
          PersonalPlanWidget(
            text: homeTitles,
            changeCurrentIndex: widget.changeCurrentIndex,
          ),
          const SizedBox(height: Spacing.xl),
          AffirmationCard(
            quotes: retrieveInspirationalQuotes(
              appLocale,
              gender == '' ? 'other' : gender,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          //This is the main widget for the gratitude journal
          ListWidget(
            onTabTapped: widget.changeCurrentIndex,
            pageCode: PagesCode.GratitudeJournal,
          ),
          const SizedBox(height: Spacing.xl),
          //This is the main widget for the positive traits list
          ListWidget(
            onTabTapped: widget.changeCurrentIndex,
            pageCode: PagesCode.QualitiesList,
          ),
        ],
      ),
    );
  }
}
