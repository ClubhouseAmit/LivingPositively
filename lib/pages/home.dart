import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/main_menu_dialog.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/util/HomePage/header_widget.dart';
import 'package:mazilon/util/HomePage/quote_card_widget.dart';
import 'package:mazilon/MainPageHelpers/components/reminders_section.dart';
import 'package:mazilon/MainPageHelpers/components/personal_plan_section.dart';
import 'package:mazilon/MainPageHelpers/components/virtues_section.dart';
import 'package:mazilon/MainPageHelpers/components/gratitude_section.dart';
import 'package:mazilon/MainPageHelpers/components/warning_signs_section.dart';

// Warm cream background used throughout this page
const Color _kPageBackground = Color(0xFFF4F0EB);

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
  bool hasFilled = false;
  Map<String, dynamic> homeTitles = {};
  int? _selectedPersonalPlanIndex;

  bool _showQuote = true;
  int _quoteIndex = 0;

  void loadData() async {
    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();
    final hasFilledValue = await service.getItem(
      'hasFilled',
      PersistentMemoryType.Bool,
    );
    if (!mounted) return;
    setState(() {
      hasFilled = hasFilledValue;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void setRandomPersonalWidgetText(
    UserInformation userInfo,
    AppLocalizations appLocale,
  ) {
    _selectedPersonalPlanIndex ??= Random().nextInt(4);
    switch (_selectedPersonalPlanIndex) {
      case 0:
        homeTitles = {'list': userInfo.makeSafer};
        break;
      case 1:
        homeTitles = {'list': userInfo.difficultEvents};
        break;
      case 2:
        homeTitles = {'list': userInfo.feelBetter};
        break;
      case 3:
        homeTitles = {'list': userInfo.distractions};
        break;
      default:
        homeTitles = {'list': []};
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    setRandomPersonalWidgetText(userInfoProvider, appLocale);
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    final quotes = retrieveInspirationalQuotes(
      appLocale,
      gender.isEmpty ? 'other' : gender,
    );
    final quote = quotes.isEmpty
        ? 'You are capable of amazing things'
        : quotes[_quoteIndex % quotes.length];

    return Scaffold(
      backgroundColor: _kPageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 27),
              // Header
              HeaderWidget(
                userName: userInfoProvider.name,
                greetingMessage: appLocale.homePageGreetings(gender),
                menuWidget: MainMenuAnchor(
                  userInformation: userInfoProvider,
                  phonePageData: widget.phonePageData,
                  changeLocale: widget.changeLocale,
                  onAboutPressed: () {
                    widget.changeCurrentIndex(context, PagesCode.About);
                  },
                  onNotificationsPressed: () {
                    if (!NotificationsService.supportsReminderSettings()) {
                      return;
                    }
                    widget.changeCurrentIndex(
                      context,
                      PagesCode.NotificationPage,
                    );
                  },
                ),
                onMenuTap: () => widget.openMainMenu(context),
              ),

              SizedBox(height: AppSpacing.lg),

              // Reminders — single card
              RemindersSectionWidget(
                reminders: [
                  ReminderItemData(
                    iconAsset: 'assets/images/sun_draw.svg',
                    title: 'Go for a short walk out',
                    subtitle: 'Our suggestion',
                  ),
                ],
                onSeeAll: () => widget.changeCurrentIndex(
                  context,
                  PagesCode.NotificationPage,
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              // My Plan
              PersonalPlanSectionWidget(
                items: (homeTitles['list'] as List<String>? ?? []).toList(),
                onSeeAll: () =>
                    widget.changeCurrentIndex(context, PagesCode.FullPlan),
              ),

              SizedBox(height: AppSpacing.xl),

              // Quote banner
              if (_showQuote)
                QuoteCardWidget(
                  quote: quote,
                  onClose: () => setState(() => _showQuote = false),
                  onRefresh: () => setState(() => _quoteIndex++),
                ),

              SizedBox(height: 48),

              // Positive Virtues
              VirtuesSectionWidget(
                virtues: userInfoProvider.positiveTraits,
                onAddItem: () =>
                    widget.changeCurrentIndex(context, PagesCode.QualitiesList),
              ),

              SizedBox(height: AppSpacing.xl),

              // Gratitude
              GratitudeSectionWidget(
                items: userInfoProvider.thanks.values
                    .expand((list) => list)
                    .toList(),
                onAddItem: () => widget.changeCurrentIndex(
                  context,
                  PagesCode.GratitudeJournal,
                ),
              ),

              SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
