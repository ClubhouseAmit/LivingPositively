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
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';

import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';

import 'package:mazilon/util/HomePage/inspirationalQuote.dart';
import 'package:mazilon/util/styles.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/HomePage/NameBar.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//the main page of the app
//allows navigation to all other pages
class Home extends StatefulWidget {
  final PhonePageData phonePageData;
  final Function(BuildContext, PagesCode) changeCurrentIndex;
  final Function changeLocale;
  final void Function(BuildContext) openMainMenu;

  const Home({
    super.key,
    required this.phonePageData,
    required this.changeCurrentIndex,
    required this.changeLocale,
    required this.openMainMenu,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends LPExtendedState<Home> {
  String greetingString = '';
  String fileButtonString = '';

  List<String> traits = [];

  bool hasFilled = false;
  Map<String, dynamic> homeTitles = {};

  //load information about the user from shared preferences
  void loadData() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    var hasFilledValue = await service.getItem(
      "hasFilled",
      PersistentMemoryType.Bool,
    );

    setState(() {
      hasFilled = hasFilledValue;
    });
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  //fuction to handle the removal of a thank you

  //this selects what information to show in the personal plan widget boxes
  void setRandomPersonalWidgetText(
    UserInformation userInfo,
    AppLocalizations appLocale,
  ) {
    var random = Random();
    var randomHeader = random.nextInt(4);

    switch (randomHeader) {
      case 0:
        setState(() {
          homeTitles = {
            'SubTitle': appLocale.makeSaferSubTitle(userInfo.gender),
            'list': userInfo.makeSafer,
          };
        });
        break;
      case 1:
        setState(() {
          homeTitles = {
            'SubTitle': appLocale.difficultEventsSubTitle(userInfo.gender),
            'list': userInfo.difficultEvents,
          };
        });
        break;
      case 2:
        setState(() {
          homeTitles = {
            'SubTitle': appLocale.feelBetterSubTitle(userInfo.gender),
            'list': userInfo.feelBetter,
          };
        });
        break;
      case 3:
        setState(() {
          homeTitles = {
            'SubTitle': appLocale.distractionsSubTitle(userInfo.gender),
            'list': userInfo.distractions,
          };
        });
        break;
      default:
        setState(() {
          homeTitles = {'SubTitle': '', 'list': []};
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    //add random header and user-selected info from personal plan:
    setRandomPersonalWidgetText(userInfoProvider, appLocale);

    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0, backgroundColor: lightGray),
      backgroundColor: lightGray,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              //This shows the "hello <username>" banner and header buttons
              NameBar(
                greetingString: appLocale.homePageGreetings(gender),
                icons: [
                  Builder(
                    builder: (menuButtonContext) => myTextButton(
                      () => widget.openMainMenu(menuButtonContext),
                      Icons.menu,
                      primaryPurple,
                      tooltip: appLocale.menuTooltip,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: Column(
                  children: [
                    //this is the Personal Plan widget section
                    PersonalPlanWidget(
                      text: homeTitles,
                      changeCurrentIndex: widget.changeCurrentIndex,
                    ),
                    const SizedBox(height: 20.0),

                    //inspirational quote widget:
                    InspirationalQuote(
                      quotes: retrieveInspirationalQuotes(
                        appLocale,
                        gender == "" ? "other" : gender,
                      ),
                    ),

                    const SizedBox(height: 20),
                    //This is the main widget for the positive traits list
                    ListWidget(
                      onTabTapped: widget.changeCurrentIndex,
                      pageCode: PagesCode.QualitiesList,
                    ),
                    //  TraitListWidget(
                    //   onTabTapped: widget.changeCurrentIndex,
                    // ),
                    const SizedBox(height: 20),
                    ListWidget(
                      onTabTapped: widget.changeCurrentIndex,
                      pageCode: PagesCode.GratitudeJournal,
                    ),
                    //This is the main widget for the thank yous list
                    //  ThanksListWidget(onTabTapped: widget.changeCurrentIndex),
                  ],
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}
