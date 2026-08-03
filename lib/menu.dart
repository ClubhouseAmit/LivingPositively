//import 'package:mazilon/pages/schedule.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/main_menu_dialog.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/PersonalPlan/myPlanPageFull.dart';
import 'package:mazilon/pages/WellnessTools/wellnessTools.dart';
import 'package:mazilon/pages/about.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/pages/journal.dart';
import 'package:mazilon/pages/notifications/notification_page.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/pages/phone.dart';
import 'package:mazilon/pages/positive.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/HomePage/bottomNavigationItem.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/appInformation.dart';

import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class Menu extends StatefulWidget {

  const Menu({
    required this.phonePageData, required this.hasFilled, required this.changeLocale, super.key,
  });
  final PhonePageData phonePageData;
  final bool hasFilled;
  final Function changeLocale;

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends LPExtendedState<Menu> {
  static const double _bottomNavigationCenterGap = 72;

  final AutoSizeGroup _bottomNavigationLabelGroup = AutoSizeGroup();

  PagesCode current = PagesCode.Home;
  String version = '1.0.0';
  bool isFullScreen = false;
  late Widget currentScreen;

  //Function to set that the users has already opened the app before
  Future<void> loadFirstTime() async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.setItem('enteredBefore', PersistentMemoryType.Bool, true);
  }

  Future<void> testingChange() async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    await service.setItem(
      'disclaimerConfirmed',
      PersistentMemoryType.Bool,
      true,
    );
    final location = await service.getItem(
      'location',
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
    final mixPanelService = GetIt.instance<AnalyticsService>();

    if (index == PagesCode.NotificationPage &&
        !NotificationsService.supportsReminderSettings()) {
      return;
    }

    setState(() {
      current = index;
      //adding pages to menu here:

      if (index == PagesCode.FullPlan) {
        mixPanelService.trackEvent('Viewed full Personal Plan');
        currentScreen = MyPlanPageFull(
          phonePageData: widget.phonePageData,
          hasFilled: widget.hasFilled,
          changeLocale: widget.changeLocale,
        );
      } else if (index == PagesCode.QualitiesList) {
        mixPanelService.trackEvent('Viewed full Qualities List');
        currentScreen = Positive(
          onBackPressed: () => changeCurrentIndex(context, PagesCode.Home),
        );
      } else if (index == PagesCode.GratitudeJournal) {
        mixPanelService.trackEvent('Viewed full Gratitude Journal');
        currentScreen = Journal(
          fullSuggestionList: retrieveThanksList(
            appLocale,
            gender == '' ? 'other' : gender,
          ),
          onBackPressed: () => changeCurrentIndex(context, PagesCode.Home),
        );
      } else if (index == PagesCode.EmergencyPhones) {
        currentScreen = PhonePage(
          phonePageData: widget.phonePageData,
          onBackPressed: () => changeCurrentIndex(context, PagesCode.Home),
        );
      } else if (index == PagesCode.About) {
        currentScreen = About(
          version: version,
          onBackPressed: () => changeCurrentIndex(context, PagesCode.Home),
        );
      } else if (index == PagesCode.NotificationPage) {
        currentScreen = NotificationPage(
          onBackPressed: () => changeCurrentIndex(context, PagesCode.Home),
        );
      } else if (index == PagesCode.FeelGoodPage) {
        currentScreen = const FeelGood();
      } /*else if (index == 9) {
        currentScreen = syncDevicesRealTime(
            collections: widget.collections,

            gender: userInformation.gender,
            phonePageData: widget.phonePageData);
      }*/
    });
  }

  Future<void> getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
  }

  Map<String, List<String>> _filterVideoByLocal(
    Map<String, List<String>> videos,
  ) {
    final localizedVideos = {
      'videoId': <String>[],
      'videoHeadline': <String>[],
      'videoDescription': <String>[],
      'videoTranscript': <String>[],
      'videoLocale': <String>[],
    };

    for (var i = 0; i < videos['videoLocale']!.length; i++) {
      final video = videos['videoLocale']![i];
      if (video == Localizations.localeOf(context).languageCode) {
        /*    'videoId': [],
    'videoHeadline': [],
    'videoDescription': [],
    'videoLocal': []*/
        localizedVideos['videoId']?.add(videos['videoId']![i]);
        localizedVideos['videoHeadline']?.add(videos['videoHeadline']![i]);
        localizedVideos['videoDescription']?.add(
          videos['videoDescription']![i],
        );
        localizedVideos['videoTranscript']?.add(
          i < (videos['videoTranscript']?.length ?? 0)
              ? videos['videoTranscript']![i]
              : '',
        );
        localizedVideos['videoLocale']?.add(videos['videoLocale']![i]);
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
          currentScreen = const NotificationPage();
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
      child: SizedBox(
        key: key,
        width: 64,
        height: 70,
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
    final mixPanelService = GetIt.instance<AnalyticsService>();
    final userInformation = Provider.of<UserInformation>(context);
    final appInfoProvider = Provider.of<AppInformation>(context);
    final gender = userInformation.gender;
    final colorScheme = Theme.of(context).colorScheme;
    testingChange();

    return PopScope(
      //this is the popscope widget that will handle the back button
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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
        backgroundColor: colorScheme.surfaceContainerHighest,
        resizeToAvoidBottomInset: false,
        body: currentScreen,
        // SOS FAB is always visible — ADR-005 §A.2: emergency access must be
        // reachable in every app state, including fullscreen video playback.
        floatingActionButton: isFullScreen
            ? SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  backgroundColor: const Color.fromARGB(200, 33, 1, 101),
                  foregroundColor: Colors.white,
                  tooltip: appLocale.sosTooltip,
                  child: const Icon(LucideIcons.phone),
                  onPressed: () {
                    setState(() {
                      currentScreen =
                          PhonePage(phonePageData: widget.phonePageData);
                      current = PagesCode.EmergencyPhones;
                      isFullScreen = false;
                    });
                  },
                ),
              )
            : null,
        floatingActionButtonLocation: isFullScreen
            ? FloatingActionButtonLocation.endFloat
            : null,
        //when full screen don't show the bottom navigation bar
        bottomNavigationBar: isFullScreen
            ? null
            : BottomAppBar(
                elevation: 8,
                color: colorScheme.surface,
                shape: const AutomaticNotchedShape(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                child: Container(
                  height: 70, // Standard height
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _bottomNavigationButton(
                        key: const Key('bottomNavHome'),
                        onPressed: () {
                          setState(() {
                            currentScreen = _buildHomeScreen();
                            current = PagesCode.Home;
                          });
                        },
                        selected: current == PagesCode.Home,
                        icon: LucideIcons.home,
                        label: appLocale.home(gender),
                      ),
                      _bottomNavigationButton(
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
                        icon: LucideIcons.clipboardList,
                        label: appLocale.personalPlanPageMyPlan(gender),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -12), // Sticks out by 12px
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: FloatingActionButton(
                            shape: const CircleBorder(),
                            backgroundColor: const Color.fromARGB(255, 33, 1, 101),
                            foregroundColor: Colors.white,
                            tooltip: appLocale.sosTooltip,
                            elevation: 4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(LucideIcons.phone, size: 20),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'SOS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () {
                              setState(() {
                                currentScreen = PhonePage(
                                    phonePageData: widget.phonePageData);
                                current = PagesCode.EmergencyPhones;
                              });
                            },
                          ),
                        ),
                      ),
                      _bottomNavigationButton(
                        key: const Key('bottomNavFeelGood'),
                        onPressed: () {
                          setState(() {
                            mixPanelService.trackEvent(
                              'Viewed Feel Good Page',
                            );
                            currentScreen = const FeelGood();
                            current = PagesCode.FeelGoodPage;
                          });
                        },
                        selected: current == PagesCode.FeelGoodPage,
                        icon: LucideIcons.smile,
                        label: AppLocalizations.of(
                          context,
                        )!.homePageFeelGood(gender),
                      ),
                      _bottomNavigationButton(
                        key: const Key('bottomNavSupportTools'),
                        onPressed: () {
                          _showWellnessTools(appInfoProvider);
                        },
                        selected: current == PagesCode.WellnessToolsPage,
                        icon: LucideIcons.heart,
                        label: appLocale.homePageWellnessTools(gender),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
