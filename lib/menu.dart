//import 'package:mazilon/pages/schedule.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/main_menu_dialog.dart';
import 'package:mazilon/pages/about.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/WellnessTools/wellnessTools.dart';
import 'package:mazilon/pages/notifications/notification_page.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:flutter/services.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

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

class Menu extends StatefulWidget {
  final PhonePageData phonePageData;
  final bool hasFilled;
  final Function changeLocale;

  const Menu({
    super.key,
    required this.phonePageData,
    required this.hasFilled,
    required this.changeLocale,
  });

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends LPExtendedState<Menu> {
  static const double _bottomNavigationCenterGap = 72.0;

  final AutoSizeGroup _bottomNavigationLabelGroup = AutoSizeGroup();

  PagesCode current = PagesCode.Home;
  String version = "1.0.0";
  bool isFullScreen = false;
  late Widget currentScreen;

  //Function to set that the users has already opened the app before
  void loadFirstTime() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.setItem("enteredBefore", PersistentMemoryType.Bool, true);
  }

  void testingChange() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.setItem(
      "disclaimerConfirmed",
      PersistentMemoryType.Bool,
      true,
    );
    var location = await service.getItem(
      "location",
      PersistentMemoryType.String,
    );

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
    final userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final gender = userInformation.gender;
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();

    if (index == PagesCode.NotificationPage &&
        !NotificationsService.supportsReminderSettings()) {
      return;
    }

    setState(() {
      current = index;
      //adding pages to menu here:

      if (index == PagesCode.FullPlan) {
        mixPanelService.trackEvent("Viewed full Personal Plan");
        currentScreen = MyPlanPageFull(
          phonePageData: widget.phonePageData,
          hasFilled: widget.hasFilled,
          changeLocale: widget.changeLocale,
        );
      } else if (index == PagesCode.QualitiesList) {
        mixPanelService.trackEvent("Viewed full Qualities List");
        currentScreen = Positive();
      } else if (index == PagesCode.GratitudeJournal) {
        mixPanelService.trackEvent("Viewed full Gratitude Journal");
        currentScreen = Journal(
          fullSuggestionList: retrieveThanksList(
            appLocale,
            gender == "" ? "other" : gender,
          ),
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

  Map<String, List<String>> _filterVideoByLocal(
    Map<String, List<String>> videos,
  ) {
    var localizedVideos = {
      'videoId': <String>[],
      'videoHeadline': <String>[],
      'videoDescription': <String>[],
      'videoLocale': <String>[],
    };

    for (var i = 0; i < videos["videoLocale"]!.length; i++) {
      var video = videos["videoLocale"]![i];
      if (video == Localizations.localeOf(context).languageCode) {
        /*    'videoId': [],
    'videoHeadline': [],
    'videoDescription': [],
    'videoLocal': []*/
        localizedVideos['videoId']?.add(videos["videoId"]![i]);
        localizedVideos['videoHeadline']?.add(videos["videoHeadline"]![i]);
        localizedVideos['videoDescription']?.add(
          videos["videoDescription"]![i],
        );
        localizedVideos['videoLocale']?.add(videos["videoLocale"]![i]);
      }
    }

    return localizedVideos;
  }

  Widget _buildHomeScreen() {
    return Home(
      phonePageData: widget.phonePageData,
      changeCurrentIndex: changeCurrentIndex,
      changeLocale: widget.changeLocale,
      openMainMenu: _showMainMenu,
    );
  }

  void _showWellnessTools(AppInformation appInfoProvider) {
    setState(() {
      currentScreen = WellnessTools(
        isFullScreen: isFullScreen,
        videoData: _filterVideoByLocal(appInfoProvider.wellnessVideos),
        setBool: setFullScreen,
      );
      current = PagesCode.WellnessToolsPage;
    });
  }

  void _showMainMenu(BuildContext anchorContext) {
    final userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    showMainMenuDialog(
      context: context,
      anchorContext: anchorContext,
      appLocale: appLocale,
      userInformation: userInformation,
      phonePageData: widget.phonePageData,
      changeLocale: widget.changeLocale,
      isWeb: kIsWeb,
      onAboutPressed: () {
        setState(() {
          currentScreen = About(version: version);
          current = PagesCode.About;
        });
      },
      onNotificationsPressed: () {
        if (!NotificationsService.supportsReminderSettings()) {
          return;
        }
        setState(() {
          currentScreen = NotificationPage();
          current = PagesCode.NotificationPage;
        });
      },
    );
  }

  Widget _bottomNavigationButton({
    required Key key,
    required VoidCallback onPressed,
    required bool selected,
    required IconData icon,
    required String label,
  }) {
    // Semantics(selected:) lets TalkBack/VoiceOver announce the active tab
    // ("<label>, selected"). The visible text label is already inside
    // `bottomNavigationItem`, so we only add the role here.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox.expand(
        key: key,
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onPressed,
          child: ExcludeSemantics(
            child: bottomNavigationItem(
              selected,
              icon,
              label,
              textGroup: _bottomNavigationLabelGroup,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    loadFirstTime();
    getVersion();
    super.initState();
    //this is the initial page
    currentScreen = _buildHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    final userInformation = Provider.of<UserInformation>(context);
    final appInfoProvider = Provider.of<AppInformation>(context);
    final gender = userInformation.gender;
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
          currentScreen = _buildHomeScreen();
        }
      },
      child: Scaffold(
        backgroundColor: appWhite,
        resizeToAvoidBottomInset: false,
        body: currentScreen,
        // SOS FAB is always visible — ADR-005 §A.2: emergency access must be
        // reachable in every app state, including fullscreen video playback.
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: isFullScreen
              ? const Color.fromARGB(
                  200,
                  33,
                  1,
                  101,
                ) // ~78% opaque in fullscreen
              : const Color.fromARGB(255, 33, 1, 101),
          foregroundColor: appWhite,
          // The SOS FAB stays at the default 56dp in every mode — even
          // fullscreen video — because shrinking the emergency affordance
          // below the 48dp Material tap target conflicts with UX_GAPS §1.6
          // and §2.1 (crisis affordance must remain reachable).
          // Localized so TalkBack/VoiceOver announce the SOS action in the
          // user's language (Hebrew / Arabic / English) — UX_GAPS §1.3.
          tooltip: appLocale.sosTooltip,
          child: isFullScreen
              ? const Icon(Icons.phone)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.phone),
                    // FittedBox keeps the label inside the FAB's 56dp circle
                    // even when system text-scale is large; without it `.sp`
                    // overflows the column on smaller layouts.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: myAutoSizedText(
                        'SOS',
                        TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
                        null,
                        20,
                      ),
                    ),
                  ],
                ),
          onPressed: () {
            setState(() {
              currentScreen = PhonePage(phonePageData: widget.phonePageData);
              current = PagesCode.EmergencyPhones;
              // Exit fullscreen so emergency page renders with full chrome
              isFullScreen = false;
            });
          },
        ),
        floatingActionButtonLocation: isFullScreen
            ? FloatingActionButtonLocation.endFloat
            : FloatingActionButtonLocation.centerDocked,
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
                    children: [
                      Expanded(
                        child: _bottomNavigationButton(
                          key: const Key('bottomNavHome'),
                          onPressed: () {
                            setState(() {
                              currentScreen = _buildHomeScreen();
                              current = PagesCode.Home;
                            });
                          },
                          selected: current == PagesCode.Home,
                          icon: Icons.home,
                          label: appLocale.home(gender),
                        ),
                      ),
                      Expanded(
                        child: _bottomNavigationButton(
                          key: const Key('bottomNavMyPlan'),
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
                          selected: current == PagesCode.FullPlan,
                          icon: Icons.assignment,
                          label: appLocale.personalPlanPageMyPlan(gender),
                        ),
                      ),
                      const SizedBox(width: _bottomNavigationCenterGap),
                      Expanded(
                        child: _bottomNavigationButton(
                          key: const Key('bottomNavFeelGood'),
                          onPressed: () {
                            setState(() {
                              mixPanelService.trackEvent(
                                "Viewed Feel Good Page",
                              );
                              currentScreen = FeelGood();
                              current = PagesCode.FeelGoodPage;
                            });
                          },
                          selected: current == PagesCode.FeelGoodPage,
                          icon: Icons.emoji_emotions_outlined,
                          label: AppLocalizations.of(
                            context,
                          )!.homePageFeelGood(gender),
                        ),
                      ),
                      Expanded(
                        child: _bottomNavigationButton(
                          key: const Key('bottomNavSupportTools'),
                          onPressed: () {
                            _showWellnessTools(appInfoProvider);
                          },
                          selected: current == PagesCode.WellnessToolsPage,
                          icon: Icons.local_florist_outlined,
                          label: appLocale.homePageWellnessTools(gender),
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
