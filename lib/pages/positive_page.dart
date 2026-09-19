import 'package:flutter/material.dart';
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/features/personal_plan/ui/retrieveInformation.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/features/journal/ui/thank_you.dart';
import 'package:mazilon/features/positive/ui/positiveTraitItemSug.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/features/journal/ui/AddForm.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

// positive traits page, where the user can add/edit/remove positive traits
// the user can also see suggestions for positive traits and refresh them
// the code here is not related to the "מעלות" section in homepage , its the positive triats page.
//the code here is similar to journal.dart page code

class Positive extends StatefulWidget {
  const Positive({super.key});

  @override
  State<Positive> createState() => _PositiveState();
}

class _PositiveState extends LPExtendedState<Positive> {
  List<String> positiveTraits = []; //list of positive traits
  String positiveTraitsMainTitle = ''; //main title
  String positiveTraitsSubTitle = ''; //sub title
  String sug1 = ''; //suggestion 1
  String sug2 = ''; //suggestion 2
  String sug3 = ''; //suggestion 3
  List<String> positiveSuggestionList = []; //list of suggestions

  void _refreshSuggestions(List<String> sourceSuggestions) {
    final tempPositiveSuggestionList = List<String>.from(sourceSuggestions);
    positiveSuggestionList = List<String>.from(tempPositiveSuggestionList);

    for (String suggestion in tempPositiveSuggestionList) {
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
      listen: true,
    );
    positiveTraits = List<String>.from(userInfoProvider.positiveTraits);
    String gender = userInfoProvider.gender;
    _refreshSuggestions(
      retrieveTraitsList(appLocale, gender == "" ? "other" : gender),
    );
  }

  //change the positive trait at the given index to the given text
  void editPositiveTrait(
    String text,
    int index,
    UserInformation userInfoProvider,
  ) async {
    List<String> positiveTraits = userInfoProvider.positiveTraits;
    setState(() {
      positiveTraits[index] = text;
      userInfoProvider.updatePositiveTraits(positiveTraits);
    });
  }

  //remove the positive trait at the given index
  Future<void> removePositiveTrait(
    int removeIndex,
    UserInformation userInfo,
  ) async {
    try {
      PersistentMemoryService service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      List<String> positiveTraitsTemp = TypeUtils.castToStringList(
        await service.getItem(
          "positiveTraits",
          PersistentMemoryType.StringList,
        ),
      );

      positiveTraitsTemp.removeAt(removeIndex);
      await service.setItem(
        "positiveTraits",
        PersistentMemoryType.StringList,
        positiveTraitsTemp,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        positiveTraits = positiveTraitsTemp;
        userInfo.updatePositiveTraits(positiveTraits);
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to remove positive trait: $error\n$stackTrace');
    }
  }

  //add the given positive trait to the list
  void addPositiveTrait(
    String positiveTrait,
    UserInformation userInfoProvider,
  ) async {
    List<String> positivetraitsTemp = userInfoProvider.positiveTraits;
    positivetraitsTemp.add(positiveTrait);

    setState(() {
      userInfoProvider.updatePositiveTraits(positivetraitsTemp);
      positiveTraits = positivetraitsTemp;
    });
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Item added to Qualities List");
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

  //the function we call when we want to add/edit a positive trait,(it opens a popup with a text field and a save button)
  void editNotification(
    String text,
    int index,
    String trait,
    UserInformation userInfoProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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

  Widget _header(
    AppLocalizations appLocale,
    String gender,
    UserInformation userInfo,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: myAutoSizedText(
                appLocale.homePageTraitsMainTitle(gender),
                TextStyle(fontWeight: FontWeight.bold, fontSize: 30.sp),
                null,
                60,
              ),
            ),
            IconButton(
              onPressed: () => editNotification(
                '',
                0,
                appLocale.trait,
                userInfo,
              ),
              icon: Icon(Icons.add, size: 50, color: colorScheme.primary),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: myAutoSizedText(
            appLocale.homePageTraitsSecondaryTitle(gender),
            TextStyle(
              color: colorScheme.outline,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            TextAlign.start,
            30,
            3,
          ),
        ),
      ],
    );
  }

  Widget _traitList(
    AppLocalizations appLocale,
    UserInformation userInfo,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: positiveTraits.length,
      itemBuilder: (context, index) => ThankYou(
        text: positiveTraits[index],
        number: index + 1,
        edit: (String text, int index) {
          editNotification(text, index, appLocale.trait, userInfo);
        },
        remove: (int index) {
          unawaited(removePositiveTrait(index, userInfo));
        },
        date: '',
        color: colorScheme.primary,
      ),
    );
  }

  List<Widget> _suggestions(AppLocalizations appLocale, String gender) {
    final fullList = retrieveTraitsList(
      appLocale,
      gender.isEmpty ? 'other' : gender,
    );
    return [
      if (sug1.isNotEmpty)
        PositiveTraitItemSug(
          stopShowing: 0,
          add: addPositiveTrait,
          inputText: sug1,
          fullSuggestionList: fullList,
        ),
      if (sug2.isNotEmpty && sug1 != sug2)
        PositiveTraitItemSug(
          stopShowing: 2,
          add: addPositiveTrait,
          inputText: sug2,
          fullSuggestionList: fullList,
        ),
      if (sug3.isNotEmpty && sug1 != sug3)
        PositiveTraitItemSug(
          stopShowing: 3,
          add: addPositiveTrait,
          inputText: sug3,
          fullSuggestionList: fullList,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final gender = userInfoProvider.gender;
    final appLocale = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateAnyDirection],
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: ListView(
          children: [
            _header(appLocale, gender, userInfoProvider, colorScheme),
            _traitList(appLocale, userInfoProvider, colorScheme),
            positiveTraits.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.sm,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                    ),
                    child: myAutoSizedText(
                      appLocale.positiveEmptyGuidance,
                      TextStyle(
                        color: colorScheme.outline,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.normal,
                      ),
                      TextAlign.center,
                      40,
                    ),
                  )
                : Divider(
                    color: colorScheme.outline,
                    indent: AppSpacing.xxxl,
                    endIndent: AppSpacing.xxxl,
                  ),
            ..._suggestions(appLocale, gender),
            TextButton(
              onPressed: () {
                final currentGender = userInfoProvider.gender;
                setState(() {
                  _refreshSuggestions(
                    retrieveTraitsList(
                      appLocale,
                      currentGender.isEmpty ? 'other' : currentGender,
                    ),
                  );
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    appLocale.otherSuggestions(gender),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.refresh, //refresh icon
                    color: colorScheme.tertiary, //refresh icon color
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
