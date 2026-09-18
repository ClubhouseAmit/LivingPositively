import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:provider/provider.dart';

/// Journal page, where the user can write thank you notes (add, edit, remove
/// notes).
///
/// The user can also see suggested thank you notes and refresh them. (The
/// code here is not related to the todo list in the home page; it's the
/// thank you notes page.)
class Journal extends StatefulWidget {
  final List<String> fullSuggestionList;
  const Journal({required this.fullSuggestionList, super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends LPExtendedState<Journal> {
  /// Suggested thank you notes.
  List<String> suggestions = [];

  /// Recomputes the three suggested notes not already present in
  /// [thankYous].
  void _refreshSuggestions(List<String> thankYous) {
    final thanksSuggestionList = List<String>.from(widget.fullSuggestionList);

    for (final suggestion in widget.fullSuggestionList) {
      if (thanksSuggestionList.length > 3 && thankYous.contains(suggestion)) {
        thanksSuggestionList.remove(suggestion);
      }
    }

    if (thanksSuggestionList.isEmpty) {
      suggestions = [];
      return;
    }

    final indices = List<int>.generate(thanksSuggestionList.length, (i) => i);
    indices.shuffle();
    suggestions = [
      thanksSuggestionList[indices[0]],
      thanksSuggestionList[indices[thanksSuggestionList.length > 1 ? 1 : 0]],
      thanksSuggestionList[indices[thanksSuggestionList.length > 2 ? 2 : 0]],
    ];
  }

  /// Changes the thank you note text at [index] to [text].
  void editThankYou(String text, int index, UserInformation userInfoProvider) {
    final thankYous = List<String>.from(
      userInfoProvider.thanks['thanks'] ?? const <String>[],
    );
    thankYous[index] = text;
    userInfoProvider.updateThanks({
      'thanks': thankYous,
      'dates': userInfoProvider.thanks['dates'] ?? [],
    });
  }

  /// Removes the thank you note at [removeIndex].
  void removeThankYou(int removeIndex, UserInformation userInfoProvider) {
    final thankYousTemp = List<String>.from(
      userInfoProvider.thanks['thanks'] ?? const <String>[],
    );
    final datesTemp = List<String>.from(
      userInfoProvider.thanks['dates'] ?? const <String>[],
    );
    thankYousTemp.removeAt(removeIndex);
    datesTemp.removeAt(removeIndex);
    userInfoProvider.updateThanks({'thanks': thankYousTemp, 'dates': datesTemp});
  }

  /// Adds [thankYou] to the list of thank you notes.
  void addThankYou(String thankYou, UserInformation userInfoProvider) {
    final thankYousTemp = List<String>.from(
      userInfoProvider.thanks['thanks'] ?? const <String>[],
    );
    final datesTemp = List<String>.from(
      userInfoProvider.thanks['dates'] ?? const <String>[],
    );
    thankYousTemp.add(thankYou);
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    datesTemp.add(formattedDate);
    userInfoProvider.updateThanks({'thanks': thankYousTemp, 'dates': datesTemp});

    // Show the popup after adding the first thank you note (every time you
    // enter the journal page).
    final today = DateFormat('yyyy-MM-dd').format(now);
    if (datesTemp.where((date) => date.startsWith(today)).length == 1) {
      showThankYouPopup(userInfoProvider);
    }
    GetIt.instance<AnalyticsService>().trackEvent(
      "Item added to Gratitude Journal",
    );
  }

  /// Shows the popup with the text from the shared preferences.
  void showThankYouPopup(UserInformation userInfoProvider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final gender = userInfoProvider.gender;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(''),
            content: Text(
              appLocale.homePageThankyouPopup(gender),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  appLocale.confirmButton(gender),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  /// Opens the popup with the text field used to add/edit a thank you note
  /// (the AddForm widget).
  void editThanks(String title, [String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: addThankYou,
          index: index,
          edit: editThankYou,
          text: text,
          formTitle: title,
        );
      },
    );
  }

  /// Builds the journal page.
  @override
  Widget build(BuildContext context) {
    final userInfoProvider = context.watch<UserInformation>();
    final gender = userInfoProvider.gender;
    final thankYous = List<String>.from(
      userInfoProvider.thanks['thanks'] ?? const <String>[],
    );
    final dates = List<String>.from(
      userInfoProvider.thanks['dates'] ?? const <String>[],
    );
    _refreshSuggestions(thankYous);
    final colorScheme = Theme.of(context).colorScheme;
    final fullSuggestionList = retrieveThanksList(
      appLocale,
      gender == "" ? "other" : gender,
    );
    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateAnyDirection],
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                40,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Text(
                            appLocale.homePageThanksMainTitle(gender),
                            style: Theme.of(context).textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      //the add button to add a new thank you note
                      IconButton(
                        //when the button is pressed, open the popup with empty text field to write a new thank you note
                        onPressed: () {
                          editThanks(appLocale.thanks);
                        },
                        tooltip: appLocale.addItemTooltip,
                        icon: Icon(
                          Icons.add,
                          size: 50.0,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      //the subtitle of the journal page
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Text(
                            appLocale.homePageThanksSecondaryTitle(gender),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: colorScheme.outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //the list of thank you notes, newest first
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final reversedIndex = thankYous.length - 1 - index;
                return ThankYou(
                  text: thankYous[reversedIndex],
                  number: thankYous.length - index,
                  edit: (String text, int index) {
                    editThanks(appLocale.thanks, text, index);
                  },
                  remove: (int index) => removeThankYou(index, userInfoProvider),
                  date: dates[reversedIndex],
                  color: colorScheme.onSurface,
                );
              },
              itemCount: thankYous.length,
            ),
            thankYous.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.sm,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                    ),
                    child: Text(
                      appLocale.journalEmptyGuidance,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Divider(
                    color: colorScheme.outline,
                    indent: 30,
                    endIndent: 30,
                  ),
            //the suggested thank you notes
            for (var i = 0; i < suggestions.length; i++)
              if (suggestions[i].isNotEmpty)
                ThanksItemSuggested(
                  stopShowing: 3 - i,
                  add: addThankYou,
                  inputText: suggestions[i],
                  fullSuggestionList: fullSuggestionList,
                ),
            //the button to refresh the suggested thank you notes and get 3 new suggestions
            TextButton(
              onPressed: () {
                setState(() {
                  _refreshSuggestions(thankYous);
                });
              },
              //the text of the refresh button
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      appLocale.otherSuggestions(gender),
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: colorScheme.tertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 1.0),
                  Icon(Icons.refresh, color: colorScheme.tertiary),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
