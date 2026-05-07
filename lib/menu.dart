//import 'package:mazilon/pages/schedule.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/about.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/WellnessTools/wellnessTools.dart';
import 'package:mazilon/pages/notifications/notification_page.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:flutter/services.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/pages/UserSettings.dart';

import 'package:mazilon/pages/home.dart';
import 'package:mazilon/pages/journal.dart';
import 'package:mazilon/pages/phone.dart';
import 'package:mazilon/pages/positive.dart';
import 'package:mazilon/pages/PersonalPlan/myPlanPageFull.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/styles.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/HomePage/bottomNavigationItem.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class Menu extends StatefulWidget {
  final PhonePageData phonePageData;
  final bool hasFilled;
  final Function changeLocale;

  const Menu(
      {super.key,
      required this.phonePageData,
      required this.hasFilled,
      required this.changeLocale});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends LPExtendedState<Menu> {
  PagesCode current = PagesCode.Home;
  String version = "1.0.0";
  bool isFullScreen = false;
  late Widget currentScreen;

  //Function to set that the users has already opened the app before
  void loadFirstTime() async {
    PersistentMemoryService service = GetIt.instance<
        PersistentMemoryService>(); // Get the persistent memory service instance

    await service.setItem("enteredBefore", PersistentMemoryType.Bool, true);
  }

  void testingChange() async {
    PersistentMemoryService service = GetIt.instance<
        PersistentMemoryService>(); // Get the persistent memory service instance

    await service.setItem(
        "disclaimerConfirmed", PersistentMemoryType.Bool, true);
    var location =
        await service.getItem("location", PersistentMemoryType.String);

    if (location != null && location.toString().isNotEmpty) {
      debugPrint(location.toString());
    }
  }

//Function to check if the user wants to go full screen
  void setFullScreen(bool fullScreen) {
    setState(() {
      isFullScreen = fullScreen;
    });
  }

//Function to change the current displayed page in the "home"
  void changeCurrentIndex(BuildContext context, PagesCode index) {
    final appLocale = AppLocalizations.of(context)!;
    final userInformation =
        Provider.of<UserInformation>(context, listen: false);
    final gender = userInformation.gender;
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();

    setState(() {
      current = index;
      //adding pages to menu here:

      if (index == PagesCode.FullPlan) {
        mixPanelService.trackEvent(
          "Viewed full Personal Plan",
        );
        currentScreen = MyPlanPageFull(
          phonePageData: widget.phonePageData,
          hasFilled: widget.hasFilled,
          changeLocale: widget.changeLocale,
        );
      } else if (index == PagesCode.QualitiesList) {
        mixPanelService.trackEvent(
          "Viewed full Qualities List",
        );
        currentScreen = Positive();
      } else if (index == PagesCode.GratitudeJournal) {
        mixPanelService.trackEvent(
          "Viewed full Gratitude Journal",
        );
        currentScreen = Journal(
          fullSuggestionList:
              retrieveThanksList(appLocale, gender == "" ? "other" : gender),
        );
      } else if (index == PagesCode.EmergencyPhones) {
        currentScreen = PhonePage(phonePageData: widget.phonePageData);
      } else if (index == PagesCode.About) {
        currentScreen = About(version: version);
      } else if (index == PagesCode.NotificationPage) {
        currentScreen = NotificationPage();
      } else if (index == PagesCode.FeelGoodPage) {
        currentScreen = FeelGood();
      } /*else if (index == 9) {
        currentScreen = syncDevicesRealTime(
            collections: widget.collections,

            gender: userInformation.gender,
            phonePageData: widget.phonePageData);
      }*/
    });
  }

  void getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
  }

  Widget displayNotificationButton(gender) {
    return TextButton(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.notification_add),
          SizedBox(width: 20),
          Text(AppLocalizations.of(context)!.notifications(gender)),
        ],
      ),
      onPressed: () {
        setState(() {
          currentScreen = NotificationPage();

          current = PagesCode.NotificationPage;
        });
        Navigator.of(context).pop();
      },
    );
  }

  Map<String, List<String>> _filterVideoByLocal(
      Map<String, List<String>> videos) {
    var localizedVideos = {
      'videoId': <String>[],
      'videoHeadline': <String>[],
      'videoDescription': <String>[],
      'videoLocale': <String>[]
    };

    for (var i = 0; i < videos["videoLocale"]!.length; i++) {
      var video = videos["videoLocale"]![i] ?? "he";
      if (video == Localizations.localeOf(context).languageCode) {
        /*    'videoId': [],
    'videoHeadline': [],
    'videoDescription': [],
    'videoLocal': []*/
        localizedVideos['videoId']?.add(videos["videoId"]![i]);
        localizedVideos['videoHeadline']?.add(videos["videoHeadline"]![i]);
        localizedVideos['videoDescription']
            ?.add(videos["videoDescription"]![i]);
        localizedVideos['videoLocal']?.add(videos["videoLocal"]![i]);
      }
    }

    return localizedVideos;
  }

  @override
  void initState() {
    loadFirstTime();
    getVersion();
    super.initState();
    //this is the initial page
    currentScreen = Home(
      phonePageData: widget.phonePageData,
      changeCurrentIndex: changeCurrentIndex,
      changeLocale: widget.changeLocale,
    );
  }

  @override
  Widget build(BuildContext context) {
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    final userInformation = Provider.of<UserInformation>(context);
    final appInfoProvider = Provider.of<AppInformation>(context);
    final gender = userInformation.gender;
    final age = userInformation.age;
    testingChange();

    return PopScope(
      //this is the popscope widget that will handle the back button
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        } else {
          if (current == PagesCode.Home) {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }
          changeCurrentIndex(context, PagesCode.Home);
          currentScreen = Home(
            phonePageData: widget.phonePageData,
            changeCurrentIndex: changeCurrentIndex,
            changeLocale: widget.changeLocale,
          );
        }
      },
      child: Scaffold(
        backgroundColor: appWhite,
        resizeToAvoidBottomInset: false,
        body: currentScreen,
        //when full screen don't show the SOS button
        floatingActionButton: isFullScreen
            ? null
            : FloatingActionButton(
                shape: const CircleBorder(),
                backgroundColor: const Color.fromARGB(255, 33, 1, 101),
                foregroundColor: appWhite,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.phone),
                    myAutoSizedText(
                        'SOS',
                        TextStyle(
                          // for testing remove the .sp IDK why, // adjust the size as needed
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        null,
                        20),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    currentScreen =
                        PhonePage(phonePageData: widget.phonePageData);
                    current = PagesCode.EmergencyPhones;
                  });
                },
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        //when full screen don't show the bottom navigation bar
        bottomNavigationBar: isFullScreen
            ? null
            : BottomAppBar(
                elevation: 0,
                color: appWhite,
                shape: const CircularNotchedRectangle(),
                notchMargin: 10,
                child: Container(
                  color: appWhite,
                  height: 60,
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: appLocale.localeName == 'en'
                            ? MediaQuery.of(context).size.width / 6
                            : MediaQuery.of(context).size.width / 8,
                        alignment: appLocale.textDirection == "rtl"
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: TextButton(
                            onPressed: () {
                              setState(() {
                                currentScreen = Home(
                                  phonePageData: widget.phonePageData,
                                  changeCurrentIndex: changeCurrentIndex,
                                  changeLocale: widget.changeLocale,
                                );
                                current = PagesCode.Home;
                              });
                            },
                            child: bottomNavigationItem(current == 0,
                                Icons.home, appLocale.home(gender))),
                      ),
                      Container(
                        alignment: appLocale.textDirection == "rtl"
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        width: appLocale.localeName == 'en'
                            ? MediaQuery.of(context).size.width / 5
                            : MediaQuery.of(context).size.width / 4,
                        child: TextButton(
                            onPressed: () {
                              setState(() {
                                currentScreen = MyPlanPageFull(
                                  phonePageData: widget.phonePageData,
                                  hasFilled: widget.hasFilled,
                                  changeLocale: widget.changeLocale,
                                );
                                current = PagesCode.FullPlan;
                              });
                            },
                            child: bottomNavigationItem(
                                current == PagesCode.FullPlan,
                                Icons.assignment,
                                appLocale.personalPlanPageMyPlan(gender))),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 9,
                      ),
                      Container(
                        alignment: appLocale.textDirection == "rtl"
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        width: MediaQuery.of(context).size.width / 4,
                        child: TextButton(
                            onPressed: () {
                              setState(() {
                                mixPanelService.trackEvent(
                                  "Viewed Feel Good Page",
                                );
                                currentScreen = FeelGood();
                                current = PagesCode.FeelGoodPage;
                              });
                            },
                            child: bottomNavigationItem(
                                current == PagesCode.FeelGoodPage,
                                Icons.emoji_emotions_outlined,
                                AppLocalizations.of(context)!
                                    .homePageFeelGood(gender))),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 5.5,
                        child: Align(
                          alignment: appLocale.textDirection == "rtl"
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: MaterialLocalizations.of(context)
                                    .modalBarrierDismissLabel,
                                barrierColor: Colors.black45,
                                transitionDuration:
                                    const Duration(milliseconds: 200),
                                pageBuilder: (BuildContext buildContext,
                                    Animation animation,
                                    Animation secondaryAnimation) {
                                  return FractionallySizedBox(
                                    heightFactor: 0.85,
                                    widthFactor: 0.6,
                                    alignment: appLocale!.textDirection == "rtl"
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Align(
                                      alignment: Alignment
                                          .bottomCenter, // Change alignment to bottom center
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Material(
                                          color: Colors.white,
                                          elevation: 24.0,
                                          shape: Border.all(
                                            color: primaryPurple,
                                            width: 2,
                                          ),
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.5,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                Align(
                                                  alignment: AppLocalizations
                                                                  .of(context)!
                                                              .textDirection ==
                                                          "rtl"
                                                      ? Alignment.topRight
                                                      : Alignment.topLeft,
                                                  child: IconButton(
                                                    icon: Icon(Icons.close),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ),
                                                TextButton(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Icon(Icons.people),
                                                      SizedBox(width: 20),
                                                      Text(AppLocalizations.of(
                                                              context)!
                                                          .homePageAbout(
                                                              gender)),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      currentScreen = About(
                                                          version: version);
                                                      current = PagesCode.About;
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                displayNotificationButton(gender),
                                                TextButton(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Icon(Icons.settings),
                                                      SizedBox(width: 20),
                                                      Text(AppLocalizations.of(
                                                              context)!
                                                          .settings(gender)),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              UserSettings(
                                                                phonePageData:
                                                                    widget
                                                                        .phonePageData,
                                                                username:
                                                                    userInformation
                                                                        .name,
                                                                age: age,
                                                                gender: gender,
                                                                changeLocale: widget
                                                                    .changeLocale,
                                                              )),
                                                    );
                                                  },
                                                ),
                                                TextButton(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Icon(Icons.yard_outlined),
                                                      SizedBox(width: 20),
                                                      Text(AppLocalizations.of(
                                                              context)!
                                                          .homePageWellnessTools(
                                                              gender)),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      currentScreen = WellnessTools(
                                                          isFullScreen:
                                                              isFullScreen,
                                                          videoData:
                                                              _filterVideoByLocal(
                                                                  appInfoProvider
                                                                      .wellnessVideos),
                                                          setBool:
                                                              setFullScreen);
                                                      current = PagesCode
                                                          .WellnessToolsPage;
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                TextButton(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Icon(Icons.share),
                                                      SizedBox(width: 20),
                                                      Text(appLocale
                                                          .shareButtonText),
                                                    ],
                                                  ),
                                                  onPressed: () async {
                                                    // Share app text with others
                                                    await Share.share(
                                                      '${appLocale.shareAppMessage}\n https://sites.google.com/mishol.org/matzilon/%D7%91%D7%99%D7%AA',
                                                      subject:
                                                          'Living Positively App',
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                              setState(() {
                                current = PagesCode.WellnessToolsPage;
                              });
                            },
                            child: bottomNavigationItem(
                                current == PagesCode.WellnessToolsPage ||
                                    current == PagesCode.About ||
                                    current == PagesCode.NotificationPage,
                                Icons.menu,
                                appLocale!.menu(gender)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
