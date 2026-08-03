import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/list_utils.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_body_widget.dart';
import 'package:mazilon/MainPageHelpers/show_all_button.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/HomePage/sectionBarHome.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// the trait list widget, it shows the list of the traits
// this code is related to "מעלות" section in homepage.
// this code is similar to thanksListWidget.dart .
class ListWidget extends StatefulWidget { // the title of the widget
  const ListWidget({
    required this.onTabTapped, required this.pageCode, super.key,
  });
  final Function(BuildContext, PagesCode)
  onTabTapped; // the function to navigate to another page
  final PagesCode pageCode;
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
    Future.delayed(const Duration(), () {
      if (!mounted) {
        return;
      }
      final gender = userInfoProvider.gender;
      showDialog(
        context: context,
        builder: (context) {
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
                  style: const TextStyle(fontWeight: FontWeight.normal),
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
    UserInformation userInfoProvider,
  ) {
    setState(() {
      userInfoProvider.updateThanks({
        'thanks': thankyousTemp,
        'dates': datesTemp,
      });
      _refreshHomeSuggestions(userInfoProvider);
    });
  }

  void editTraitsState(List<String> positivetraitsTemp, UserInformation userInfoProvider) {
    setState(() {
      userInfoProvider.updatePositiveTraits(positivetraitsTemp);
      _refreshHomeSuggestions(userInfoProvider);
    });
  }

  void editTrait(String title, [String text = '', int index = 0]) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AddForm(
          add: (String positiveTrait, UserInformation userInfoProvider) => addPositiveTrait(
            positiveTrait,
            userInfoProvider,
            editTraitsState,
          ),
          index: index,
          edit: (String text, int index, UserInformation userInfoProvider) =>
              editPositiveTrait(text, index, userInfoProvider, editTraitsState),
          text: text,
          formTitle: title,
        );
      },
    );
  }

  void editThanks(String title, [String text = '', int index = 0]) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AddForm(
          add: (String thankYou, UserInformation userInfoProvider) => addThankYou(
            thankYou,
            userInfoProvider,
            editThanksState,
            showThankYouPopup,
          ),
          index: index,
          edit: (String text, int index, UserInformation userInfoProvider) =>
              editThankYou(text, index, userInfoProvider, editThanksState),
          text: text,
          formTitle: title,
        );
      },
    );
  }

  void Function(int index) editItemFunction(
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

  void Function(int index) removeItemFunction(
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
      add: (String thankYou, UserInformation userInfoProvider) {
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
      add: (String trait, UserInformation userInfoProvider) {
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.pageCode == PagesCode.GratitudeJournal
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  width: 6,
                ),
              ),
            ),
            child: Directionality(
              textDirection: Directionality.of(context),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Spacing.md,
                  bottom: Spacing.md,
                  right: Spacing.md,
                  left: Spacing.md - 6,
                ),
                child: Column(
                  children: [
                    SectionBarHome(
                      textWidget: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () {
                          widget.onTabTapped(context, widget.pageCode);
                        },
                        child: AutoSizeText(
                          pageData['mainTitle'] as String,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      icons: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.plus,
                            color: Theme.of(context).colorScheme.primary,
                            size: Spacing.lg,
                          ),
                          tooltip: appLocale.addItemTooltip,
                          onPressed: addItemFunction,
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.chevronRight,
                            color: Theme.of(context).colorScheme.primary,
                            size: Spacing.lg,
                          ),
                          tooltip: appLocale.showAll(gender),
                          onPressed: () {
                            widget.onTabTapped(context, widget.pageCode);
                          },
                        ),
                      ],
                      subHeader: pageData['secondaryTitle'] as String? ?? '',
                    ),
                    const SizedBox(height: Spacing.sm),
                    ListBodyWidget(
                      listItems: listItems,
                      editItems: editItemFunction(userInfoProvider, sourceIndexes),
                      removeItems: removeItemFunction(userInfoProvider, sourceIndexes),
                    ),
                    if (listItems.isNotEmpty && _homeSuggestions.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                      Divider(
                        color: Theme.of(context).colorScheme.outline,
                        indent: 30,
                        endIndent: 30,
                      ),
                      const SizedBox(height: Spacing.sm),
                    ] else if (_homeSuggestions.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                    ],
                    for (final suggestion in _homeSuggestions)
                      buildSuggestion(suggestion, gender),
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: TextButton(
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
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 1),
                            Icon(
                              LucideIcons.wand2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
