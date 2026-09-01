import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_home_insights_section.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/main_menu_dialog.dart';
import 'package:mazilon/util/HomePage/header_widget.dart';
import 'package:mazilon/util/HomePage/quote_card_widget.dart';
import 'package:mazilon/MainPageHelpers/components/reminders_section.dart';
import 'package:mazilon/MainPageHelpers/components/personal_plan_section.dart';
import 'package:mazilon/MainPageHelpers/components/virtues_section.dart';
import 'package:mazilon/MainPageHelpers/components/gratitude_section.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';

class Home extends StatefulWidget {
  final PhonePageData phonePageData;
  final Function(BuildContext, PagesCode) changeCurrentIndex;
  final Function changeLocale;
  final void Function(BuildContext) openMainMenu;
  final VoidCallback? openMoodMedicineCheckIn;
  final bool moodMedicineAvailable;

  const Home({
    super.key,
    required this.phonePageData,
    required this.changeCurrentIndex,
    required this.changeLocale,
    required this.openMainMenu,
    this.openMoodMedicineCheckIn,
    this.moodMedicineAvailable = true,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends LPExtendedState<Home> {
  bool _showQuote = true;
  int _quoteIndex = 0;
  String _quoteCandidateKey = '';
  int _reminderIndex = 0;
  String? _customReminder;

  Future<void> _loadCustomReminder() async {
    final service = GetIt.instance<PersistentMemoryService>();
    final savedReminder =
        await service.getItem('customReminder', PersistentMemoryType.String)
            as String?;
    if (!mounted) return;
    setState(() {
      _customReminder = (savedReminder != null && savedReminder.isNotEmpty)
          ? savedReminder
          : null;
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadCustomReminder());
    _reminderIndex = Random().nextInt(1000);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userInfo = Provider.of<UserInformation>(context);
    final quotes = retrieveInspirationalQuotes(appLocale, userInfo.gender);
    final candidateKey = quotes.join('\u0000');
    if (candidateKey == _quoteCandidateKey) return;
    _quoteCandidateKey = candidateKey;
    _quoteIndex = quotes.isEmpty ? 0 : Random().nextInt(quotes.length);
  }

  void _refreshQuote(List<String> quotes) {
    if (quotes.isEmpty) return;
    final previousQuote = quotes[_quoteIndex % quotes.length];
    setState(() => _quoteIndex = Random().nextInt(quotes.length));
    final nextQuote = quotes[_quoteIndex % quotes.length];
    unawaited(
      GetIt.instance<AnalyticsService>().trackEvent(
        'Inspirational Quotes Refreshed',
        {'Old Quote': previousQuote, 'New Quote': nextQuote},
      ),
    );
  }

  String _getReminder(String gender) {
    if (_customReminder != null && _customReminder!.isNotEmpty) {
      return _customReminder!;
    }
    final List<String> activeReminders = [
      appLocale.deepBreathSuggestion(gender),
      appLocale.stretchBodySuggestion(gender),
      appLocale.drinkWaterSuggestion(gender),
      appLocale.shortBreakSuggestion(gender),
      appLocale.lookForwardSuggestion(gender),
    ];
    return activeReminders[_reminderIndex % activeReminders.length];
  }

  void _editReminderDialog(BuildContext context, String currentText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: (text, provider) {},
          index: 0,
          edit: (text, idx, provider) async {
            if (text == currentText) {
              // Submitting unchanged text must not freeze the rotating
              // suggestion as a custom reminder.
            } else {
              PersistentMemoryService service =
                  GetIt.instance<PersistentMemoryService>();
              await service.setItem(
                'customReminder',
                PersistentMemoryType.String,
                text,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _customReminder = text;
              });
            }
          },
          text: _customReminder ?? currentText,
          formTitle: appLocale.reminders,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    final quotes = retrieveInspirationalQuotes(appLocale, gender);
    final quote = quotes.isEmpty
        ? appLocale.inspirationalQuotesNo0(gender)
        : quotes[_quoteIndex % quotes.length];

    final reminderText = _getReminder(gender);

    final reminderItems = [
      ReminderItemData(
        iconAsset: 'assets/images/sun_draw.svg',
        title: reminderText,
        subtitle: appLocale.ourSuggestion,
      ),
    ];

    return Scaffold(
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
                    widget.changeCurrentIndex(
                      context,
                      PagesCode.NotificationPage,
                    );
                  },
                  onMoodMedicinePressed: widget.openMoodMedicineCheckIn,
                ),
                onMenuTap: () => widget.openMainMenu(context),
              ),

              SizedBox(height: AppSpacing.lg),

              // Reminders list
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeGaps.sectionHorizontalInset,
                ),
                child: RemindersSectionWidget(
                  reminders: reminderItems,
                  onEdit: (index) => _editReminderDialog(context, reminderText),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              MoodMedicineHomeInsightsSection(
                title: appLocale.moodMedicineTitle,
                subtitle: appLocale.moodMedicineSubtitle,
                actionLabel: appLocale.moodMedicineViewInsights,
                isAvailable: widget.moodMedicineAvailable,
                onPressed: () => widget.changeCurrentIndex(
                  context,
                  PagesCode.MoodMedicinePage,
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              // My Plan
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeGaps.sectionHorizontalInset,
                ),
                child: PersonalPlanSectionWidget(
                  items: [
                    ...userInfoProvider.makeSafer,
                    ...userInfoProvider.feelBetter,
                  ],
                  onSeeAll: () =>
                      widget.changeCurrentIndex(context, PagesCode.FullPlan),
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              // Quote banner
              if (_showQuote)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HomeGaps.sectionHorizontalInset,
                  ),
                  child: QuoteCardWidget(
                    quote: quote,
                    onClose: () {
                      setState(() => _showQuote = false);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          showCloseIcon: true,
                          closeIconColor: Colors.white,
                          content: Text(
                            AppLocalizations.of(context)!.quoteDismissedMessage,
                          ),
                          // A SnackBarAction defaults `persist` to true, which
                          // would keep this message on screen forever.
                          persist: false,
                          action: SnackBarAction(
                            label: AppLocalizations.of(
                              context,
                            )!.quoteUndoAction,
                            onPressed: () {
                              if (!mounted) return;
                              setState(() => _showQuote = true);
                            },
                          ),
                        ),
                      );
                    },
                    onRefresh: () => _refreshQuote(quotes),
                  ),
                ),

              SizedBox(height: 48),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeGaps.sectionHorizontalInset,
                ),
                child: GratitudeSectionWidget(
                  onAddItem: () => widget.changeCurrentIndex(
                    context,
                    PagesCode.GratitudeJournal,
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              // Gratitude
              SizedBox(height: AppSpacing.xxxl),
              // Positive Virtues
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeGaps.sectionHorizontalInset,
                ),
                child: VirtuesSectionWidget(
                  virtues: userInfoProvider.positiveTraits,
                  onAddItem: () => widget.changeCurrentIndex(
                    context,
                    PagesCode.QualitiesList,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
