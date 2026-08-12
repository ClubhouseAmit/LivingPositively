import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;

import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_body_widget.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/list_utils.dart';
import 'package:mazilon/MainPageHelpers/show_all_button.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/HomePage/sectionBarHome.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';

// the trait list widget, it shows the list of the traits
// this code is related to "מעלות" section in homepage.
// this code is similar to thanksListWidget.dart .
class ListWidget extends StatefulWidget {
  final Function(BuildContext, PagesCode)
  onTabTapped; // the function to navigate to another page
  final PagesCode pageCode; // the title of the widget
  const ListWidget({
    super.key,
    required this.onTabTapped,
    required this.pageCode,
  });
  @override
  State<ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends LPExtendedState<ListWidget> {
  List<String> _homeSuggestions = [];
  String _suggestionCandidateKey = '';
  bool _suggestionsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshHomeSuggestions(
      Provider.of<UserInformation>(context, listen: false),
    );
  }

  List<String> _eligibleSuggestions(UserInformation userInfoProvider) {
    final gender = userInfoProvider.gender.isEmpty
        ? 'other'
        : userInfoProvider.gender;
    final thanks = userInfoProvider.thanks['thanks'] ?? <String>[];
    final dates = userInfoProvider.thanks['dates'] ?? <String>[];
    final suggestions = widget.pageCode == PagesCode.QualitiesList
        ? retrieveTraitsList(appLocale, gender)
        : retrieveThanksList(appLocale, gender);
    final existingItems = widget.pageCode == PagesCode.QualitiesList
        ? userInfoProvider.positiveTraits
        : _todayThankYouIndexes(
            thanks,
            dates,
          ).map((index) => thanks[index]).toList();
    final eligibleSuggestions = <String>[];

    for (final suggestion in suggestions) {
      if (!existingItems.contains(suggestion) &&
          !eligibleSuggestions.contains(suggestion)) {
        eligibleSuggestions.add(suggestion);
      }
    }

    return eligibleSuggestions;
  }

  bool _sameOrder(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }

  List<String> _selectHomeSuggestions(List<String> candidates) {
    final shuffledCandidates = List<String>.from(candidates)..shuffle();
    final selectedSuggestions = shuffledCandidates.take(3).toList();

    if (_sameOrder(selectedSuggestions, _homeSuggestions) &&
        selectedSuggestions.length > 1) {
      selectedSuggestions.add(selectedSuggestions.removeAt(0));
    }

    return selectedSuggestions;
  }

  void _refreshHomeSuggestions(
    UserInformation userInfoProvider, {
    bool force = false,
  }) {
    final candidates = _eligibleSuggestions(userInfoProvider);
    final candidateKey = candidates.join('\u0000');
    if (!force &&
        _suggestionsInitialized &&
        candidateKey == _suggestionCandidateKey) {
      return;
    }

    _homeSuggestions = _selectHomeSuggestions(candidates);
    _suggestionCandidateKey = candidateKey;
    _suggestionsInitialized = true;
  }

  List<int> _todayThankYouIndexes(List<String> thankYous, List<String> dates) {
    final todayDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    final itemCount = thankYous.length < dates.length
        ? thankYous.length
        : dates.length;
    final indexes = <int>[];

    for (var index = 0; index < itemCount; index++) {
      if (dates[index].startsWith(todayDate)) {
        indexes.add(index);
      }
    }

    return indexes;
  }

  void showThankYouPopup(UserInformation userInfoProvider) {
    Future.delayed(const Duration(seconds: 0), () {
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
              // Plain `.sp` so the popup respects the user's text-scale.
              // The previous `min(24, 14.sp)` capped upward on large devices,
              // shrinking the message exactly when the user asked for larger
              // text — see UX_GAPS §1.7.
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(
                  appLocale.confirmButton(gender),
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  void editThanksState(
    List<String> thankyousTemp,
    List<String> datesTemp,
    userInfoProvider,
  ) {
    setState(() {
      userInfoProvider.updateThanks({
        'thanks': thankyousTemp,
        'dates': datesTemp,
      });
      _refreshHomeSuggestions(userInfoProvider);
    });
  }

  void editTraitsState(positivetraitsTemp, userInfoProvider) {
    setState(() {
      userInfoProvider.updatePositiveTraits(positivetraitsTemp);
      _refreshHomeSuggestions(userInfoProvider);
    });
  }

  void editTrait(String title, [String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: (positiveTrait, userInfoProvider) => addPositiveTrait(
            positiveTrait,
            userInfoProvider,
            editTraitsState,
          ),
          index: index,
          edit: (text, index, userInfoProvider) =>
              editPositiveTrait(text, index, userInfoProvider, editTraitsState),
          text: text,
          formTitle: title,
        );
      },
    );
  }

  void editThanks(String title, [String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: (thankYou, userInfoProvider) => addThankYou(
            thankYou,
            userInfoProvider,
            editThanksState,
            showThankYouPopup,
          ),
          index: index,
          edit: (text, index, userInfoProvider) =>
              editThankYou(text, index, userInfoProvider, editThanksState),
          text: text,
          formTitle: title,
        );
      },
    );
  }

  Function(int index) editItemFunction(
    UserInformation userInfoProvider,
    List<int> sourceIndexes,
  ) {
    if (widget.pageCode == PagesCode.GratitudeJournal) {
      final sourceThanks = List<String>.from(
        userInfoProvider.thanks['thanks'] ?? <String>[],
      );
      final sourceDates = List<String>.from(
        userInfoProvider.thanks['dates'] ?? <String>[],
      );
      return (index) {
        if (index < 0 || index >= sourceIndexes.length) {
          return;
        }
        final sourceIndex = sourceIndexes[index];
        final thanks = userInfoProvider.thanks['thanks'] ?? <String>[];
        final dates = userInfoProvider.thanks['dates'] ?? <String>[];
        if (!listEquals(thanks, sourceThanks) ||
            !listEquals(dates, sourceDates) ||
            sourceIndex < 0 ||
            sourceIndex >= sourceThanks.length ||
            sourceIndex >= sourceDates.length ||
            sourceIndex >= thanks.length ||
            sourceIndex >= dates.length) {
          return;
        }
        return editThanks(appLocale.thanks, thanks[sourceIndex], sourceIndex);
      };
    } else {
      final sourceTraits = List<String>.from(userInfoProvider.positiveTraits);
      return (index) {
        if (index < 0 || index >= sourceIndexes.length) {
          return;
        }
        final sourceIndex = sourceIndexes[index];
        final traits = userInfoProvider.positiveTraits;
        if (!listEquals(traits, sourceTraits) ||
            sourceIndex < 0 ||
            sourceIndex >= sourceTraits.length ||
            sourceIndex >= traits.length) {
          return;
        }
        return editTrait(appLocale.trait, traits[sourceIndex], sourceIndex);
      };
    }
  }

  Function(int index) removeItemFunction(
    UserInformation userInfoProvider,
    List<int> sourceIndexes,
  ) {
    if (widget.pageCode == PagesCode.GratitudeJournal) {
      final sourceThanks = List<String>.from(
        userInfoProvider.thanks['thanks'] ?? <String>[],
      );
      final sourceDates = List<String>.from(
        userInfoProvider.thanks['dates'] ?? <String>[],
      );
      return (index) {
        if (index < 0 || index >= sourceIndexes.length) {
          return;
        }
        final sourceIndex = sourceIndexes[index];
        final thanks = userInfoProvider.thanks['thanks'] ?? <String>[];
        final dates = userInfoProvider.thanks['dates'] ?? <String>[];
        if (!listEquals(thanks, sourceThanks) ||
            !listEquals(dates, sourceDates) ||
            sourceIndex < 0 ||
            sourceIndex >= sourceThanks.length ||
            sourceIndex >= sourceDates.length ||
            sourceIndex >= thanks.length ||
            sourceIndex >= dates.length) {
          return;
        }
        return removeThankYou(sourceIndex, userInfoProvider, editThanksState);
      };
    } else {
      final sourceTraits = List<String>.from(userInfoProvider.positiveTraits);
      return (index) {
        if (index < 0 || index >= sourceIndexes.length) {
          return;
        }
        final sourceIndex = sourceIndexes[index];
        final traits = userInfoProvider.positiveTraits;
        if (!listEquals(traits, sourceTraits) ||
            sourceIndex < 0 ||
            sourceIndex >= sourceTraits.length ||
            sourceIndex >= traits.length) {
          return;
        }
        return removePositiveTrait(
          sourceIndex,
          userInfoProvider,
          editTraitsState,
        );
      };
    }
  }

  Widget buildThanksItemSug(String suggestion, String gender) {
    return ThanksItemSuggested(
      stopShowing: 0,
      add: (thankYou, userInfoProvider) {
        addThankYou(
          thankYou,
          userInfoProvider,
          editThanksState,
          showThankYouPopup,
        );
      },
      inputText: suggestion,
      fullSuggestionList: retrieveThanksList(appLocale, gender),
    );
  }

  Widget buildPositiveTraitItemSug(String suggestion, String gender) {
    return PositiveTraitItemSug(
      stopShowing: 0,
      add: (trait, userInfoProvider) {
        addPositiveTrait(trait, userInfoProvider, editTraitsState);
      },
      inputText: suggestion,
      fullSuggestionList: retrieveTraitsList(appLocale, gender),
    );
  }

  Widget buildSuggestion(String suggestion, String gender) {
    if (widget.pageCode == PagesCode.QualitiesList) {
      return buildPositiveTraitItemSug(suggestion, gender);
    }

    return buildThanksItemSug(suggestion, gender);
  }

  void addItemFunction() {
    if (widget.pageCode == PagesCode.QualitiesList) {
      editTrait(appLocale.trait); // the function to add a trait
    } else {
      editThanks(appLocale.thanks); // the function to add a thanks
    }
  }

  // build the trait list widget
  @override
  Widget build(BuildContext context) {
    // get the app information provider and the user information provider

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender.isEmpty
        ? 'other'
        : userInfoProvider.gender;
    final thanks = userInfoProvider.thanks['thanks'] ?? <String>[];
    final dates = userInfoProvider.thanks['dates'] ?? <String>[];
    final sourceIndexes = widget.pageCode == PagesCode.GratitudeJournal
        ? _todayThankYouIndexes(thanks, dates).reversed.toList()
        : List<int>.generate(
            userInfoProvider.positiveTraits.length,
            (index) => userInfoProvider.positiveTraits.length - index - 1,
          );
    final listItems = sourceIndexes
        .map(
          (index) => widget.pageCode == PagesCode.GratitudeJournal
              ? thanks[index]
              : userInfoProvider.positiveTraits[index],
        )
        .toList();
    final pageData = getLocalizedTextForLists(
      appLocale,
      gender,
      widget.pageCode,
    );
    return SizedBox(
      // the width of the widget is 800 if the screen width is more than 1000, otherwise it is the screen width
      width: MediaQuery.of(context).size.width > 1000
          ? 800
          : MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          children: [
            // the section bar of the trait list ,
            // which contains the title, the icon, the subheader and the add icon,
            // when its clicked it navigates to the add trait page
            SectionBarHome(
              textWidget: Padding(
                padding: widget.pageCode == PagesCode.GratitudeJournal
                    ? const EdgeInsetsDirectional.only(end: 5)
                    : EdgeInsets.zero,
                child: TextButton(
                  onPressed: () {
                    widget.onTabTapped(context, widget.pageCode);
                  },
                  child: myAutoSizedText(
                    pageData['mainTitle'],
                    TextStyle(
                      fontSize: 24.sp, // the font size of the title
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface, // the color of the title
                    ),
                    null,
                    40,
                  ),
                ),
              ),
              icon: pageData["icon"], // the icon of the section bar
              icons: [
                // add button with the add icon
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  tooltip: appLocale.addItemTooltip,
                  onPressed: addItemFunction,
                ),
              ],

              // the subheader of the section bar
              subHeader: pageData['secondaryTitle'] ?? "",
            ),
            // gap between the section bar and the trait list
            const SizedBox(height: 10),
            ListBodyWidget(
              listItems: listItems,
              editItems: editItemFunction(userInfoProvider, sourceIndexes),
              removeItems: removeItemFunction(userInfoProvider, sourceIndexes),
            ),
            ShowAllButton(
              onTabTapped: widget.onTabTapped,
              pageCode: widget.pageCode,
              count: listItems.length,
            ),
            // Suggestions (always up to 3)
            for (final suggestion in _homeSuggestions)
              buildSuggestion(suggestion, gender),
            TextButton(
              onPressed: () {
                setState(() {
                  _refreshHomeSuggestions(userInfoProvider, force: true);
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    appLocale.otherSuggestions(gender),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 1.0),
                  Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
