import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/theme/spacing.dart';

// positive traits page, where the user can add/edit/remove positive traits
// the user can also see suggestions for positive traits and refresh them
// the code here is not related to the "מעלות" section in homepage , its the positive triats page.
//the code here is similar to journal.dart page code

class Positive extends StatefulWidget {
  const Positive({this.onBackPressed, super.key});
  final VoidCallback? onBackPressed;

  @override
  State<Positive> createState() => _PositiveState();
}

class _PositiveState extends LPExtendedState<Positive> {
  List<String> positiveTraits = []; //list of positive traits
  List<FocusNode> focusNodes = []; //list of focus nodes

  FocusNode myFocusNode = FocusNode(); //focus node
  String positiveTraitsMainTitle = ''; //main title
  String positiveTraitsSubTitle = ''; //sub title
  String sug1 = ''; //suggestion 1
  String sug2 = ''; //suggestion 2
  String sug3 = ''; //suggestion 3
  List<String> positiveSuggestionList = []; //list of suggestions

  void _syncFocusNodes(int count) {
    while (focusNodes.length < count) {
      focusNodes.add(FocusNode());
    }
    while (focusNodes.length > count) {
      focusNodes.removeLast().dispose();
    }
  }

  void _refreshSuggestions(List<String> sourceSuggestions) {
    final tempPositiveSuggestionList = List<String>.from(sourceSuggestions);
    positiveSuggestionList = List<String>.from(tempPositiveSuggestionList);

    for (final suggestion in tempPositiveSuggestionList) {
      if (positiveSuggestionList.length > 1 &&
          positiveTraits.contains(suggestion)) {
        positiveSuggestionList.remove(suggestion);
      }
    }

    if (positiveSuggestionList.isEmpty) {
      sug1 = '';
      sug2 = '';
      sug3 = '';
      return;
    }

    final indices = List<int>.generate(positiveSuggestionList.length, (i) => i);
    indices.shuffle();
    sug1 = positiveSuggestionList[indices[0]];
    sug2 =
        positiveSuggestionList[indices[positiveSuggestionList.length > 1
            ? 1
            : 0]];
    sug3 =
        positiveSuggestionList[indices[positiveSuggestionList.length > 2
            ? 2
            : 0]];
  }

  //load the data from the shared preferences
  void loadData(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    positiveTraits = List<String>.from(userInfoProvider.positiveTraits);
    _syncFocusNodes(positiveTraits.length);
    final gender = userInfoProvider.gender;
    _refreshSuggestions(
      retrieveTraitsList(appLocale, gender == '' ? 'other' : gender),
    );
  }

  //change the positive trait at the given index to the given text
  Future<void> editPositiveTrait(
    String text,
    int index,
    UserInformation userInfoProvider,
  ) async {
    final positiveTraits = userInfoProvider.positiveTraits;
    setState(() {
      positiveTraits[index] = text;
      userInfoProvider.updatePositiveTraits(positiveTraits);
    });
  }

  //remove the positive trait at the given index
  Future<void> removePositiveTrait(int removeIndex, UserInformation userInfo) async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    final positiveTraitsTemp = TypeUtils.castToStringList(
      await service.getItem('positiveTraits', PersistentMemoryType.StringList),
    );

    positiveTraitsTemp.removeAt(removeIndex);
    debugPrint('got here');
    await service.setItem(
      'positiveTraits',
      PersistentMemoryType.StringList,
      positiveTraitsTemp,
    );
    setState(() {
      positiveTraits = positiveTraitsTemp;
      focusNodes.removeAt(removeIndex);
      userInfo.updatePositiveTraits(positiveTraits);
    });
  }

  //add the given positive trait to the list
  Future<void> addPositiveTrait(
    String positiveTrait,
    UserInformation userInfoProvider,
  ) async {
    final positivetraitsTemp = userInfoProvider.positiveTraits;
    positivetraitsTemp.add(positiveTrait);

    setState(() {
      userInfoProvider.updatePositiveTraits(positivetraitsTemp);
      positiveTraits = positivetraitsTemp;
      focusNodes.add(FocusNode());
    });
    final mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent('Item added to Qualities List');
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData(context);
  }

  @override
  void dispose() {
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    myFocusNode.dispose();
    super.dispose();
  }

  //the function we call when we want to add/edit a positive trait,(it opens a popup with a text field and a save button)
  void editNotification(
    String text,
    int index,
    String trait,
    UserInformation userInfoProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AddForm(
          add: addPositiveTrait,
          index: index,
          edit: editPositiveTrait,
          text: text,
          formTitle: trait,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //get the app information and user information providers

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final gender = userInfoProvider.gender;
    final appLocale = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateAnyDirection],
      child: PageLayoutWrapper(
        sliverAppBar: PremiumGlassAppBar(
          variant: AppBarVariant.detailScreen,
          onBackPressed: widget.onBackPressed,
          titleText: appLocale!.homePageTraitsMainTitle(gender),
          actions: [
            IconButton(
              onPressed: () {
                editNotification(
                  '',
                  0,
                  appLocale.trait,
                  userInfoProvider,
                );
              },
              tooltip: appLocale.addItemTooltip,
              icon: Icon(
                Icons.add,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: Spacing.sm),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Spacing.md),
            Text(
              appLocale.homePageTraitsMainTitle(gender),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: Spacing.xs),
            Text(
              appLocale.homePageTraitsSecondaryTitle(gender),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            SizedBox(height: Spacing.lg),
            //list of positive traits
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: positiveTraits.length,
              itemBuilder: (context, index) => ThankYou(
                text: positiveTraits[index],
                number: index + 1,
                edit: (String text, int index) {
                  editNotification(
                    text,
                    index,
                    appLocale.trait,
                    userInfoProvider,
                  );
                },
                remove: (int index) {
                  removePositiveTrait(index, userInfoProvider);
                },
                myFocusNode: focusNodes[index],
                date: '',
                color: colorScheme.primary,
              ),
            ),
            if (positiveTraits.isEmpty) Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: AutoSizeText(
                      appLocale.positiveEmptyGuidance,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.normal,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ) else Divider(
                    color: colorScheme.outline,
                    indent: 30,
                    endIndent: 30,
                  ),
            //suggestions
            if (sug1.isNotEmpty)
              PositiveTraitItemSug(
                stopShowing: 0,
                add: addPositiveTrait,
                inputText: sug1,
                fullSuggestionList: retrieveTraitsList(
                  appLocale,
                  gender == '' ? 'other' : gender,
                ),
              ),
            if (sug2.isNotEmpty && sug1 != sug2)
              PositiveTraitItemSug(
                stopShowing: 2,
                add: addPositiveTrait,
                inputText: sug2,
                fullSuggestionList: retrieveTraitsList(
                  appLocale,
                  gender == '' ? 'other' : gender,
                ),
              ),
            if (sug3.isNotEmpty && sug1 != sug3)
              PositiveTraitItemSug(
                stopShowing: 3,
                add: addPositiveTrait,
                inputText: sug3,
                fullSuggestionList: retrieveTraitsList(
                  appLocale,
                  gender == '' ? 'other' : gender,
                ),
              ),
            //refresh button
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: TextButton(
                onPressed: () async {
                  final gender = userInfoProvider.gender;
                  setState(() {
                    _refreshSuggestions(
                      retrieveTraitsList(
                        appLocale,
                        gender == '' ? 'other' : gender,
                      ),
                    );
                  });
                },
                //refresh button
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    //refresh button text
                    Text(
                      appLocale.otherSuggestions(gender),
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 1),
                    Icon(
                      LucideIcons.wand2, //refresh icon
                      color: colorScheme.primary, //refresh icon color
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
