import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mazilon/MainPageHelpers/MainPageList/list_utils.dart';
import 'package:mazilon/MainPageHelpers/components/dashed_list_widget.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class GratitudeSectionWidget extends StatefulWidget {
  final VoidCallback onOpenSection;

  const GratitudeSectionWidget({required this.onOpenSection, super.key});

  @override
  State<GratitudeSectionWidget> createState() => _GratitudeSectionWidgetState();
}

class _GratitudeSectionWidgetState
    extends LPExtendedState<GratitudeSectionWidget> {
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

  List<int> _todayIndexes(List<String> thanks, List<String> dates) {
    final today = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = thanks.length < dates.length ? thanks.length : dates.length;
    final indexes = <int>[];
    for (var i = 0; i < count; i++) {
      if (dates[i].startsWith(today)) indexes.add(i);
    }
    return indexes;
  }

  List<String> _eligibleSuggestions(UserInformation userInfo) {
    final gender = userInfo.gender.isEmpty ? 'other' : userInfo.gender;
    final thanks = userInfo.thanks['thanks'] ?? <String>[];
    final dates = userInfo.thanks['dates'] ?? <String>[];
    final todayThanks = _todayIndexes(
      thanks,
      dates,
    ).map((i) => thanks[i]).toList();
    final all = retrieveThanksList(appLocale, gender);
    final eligible = <String>[];
    for (final s in all) {
      if (!todayThanks.contains(s) && !eligible.contains(s)) eligible.add(s);
    }
    return eligible;
  }

  List<String> _pickSuggestions(List<String> candidates) {
    return List<String>.from(candidates)..shuffle();
  }

  void _refreshHomeSuggestions(UserInformation userInfo, {bool force = false}) {
    final candidates = _eligibleSuggestions(userInfo);
    final key = candidates.join('\u0000');
    if (!force && _suggestionsInitialized && key == _suggestionCandidateKey) {
      return;
    }
    _homeSuggestions = _pickSuggestions(candidates);
    _suggestionCandidateKey = key;
    _suggestionsInitialized = true;
  }

  void _updateThanksState(
    dynamic thanksTemp,
    dynamic datesTemp,
    dynamic userInfo,
  ) {
    setState(() {
      userInfo.updateThanks(<String, List<String>>{
        'thanks': thanksTemp as List<String>,
        'dates': datesTemp as List<String>,
      });
      _refreshHomeSuggestions(userInfo);
    });
  }

  void _showThankYouPopup(UserInformation userInfo) {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(''),
          content: Text(
            appLocale.homePageThankyouPopup(userInfo.gender),
            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(
                appLocale.confirmButton(userInfo.gender),
                style: const TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openThankDialog(
    UserInformation userInfo, [
    String text = '',
    int index = 0,
  ]) {
    final sourceThanks = List<String>.from(
      userInfo.thanks['thanks'] ?? <String>[],
    );
    final sourceDates = List<String>.from(
      userInfo.thanks['dates'] ?? <String>[],
    );
    showDialog(
      context: context,
      builder: (_) => AddForm(
        add: (thankYou, ui) =>
            addThankYou(thankYou, ui, _updateThanksState, _showThankYouPopup),
        index: index,
        edit: (text, index, userInfo) {
          final currentThanks = userInfo.thanks['thanks'] ?? <String>[];
          final currentDates = userInfo.thanks['dates'] ?? <String>[];
          if (!listEquals(currentThanks, sourceThanks) ||
              !listEquals(currentDates, sourceDates) ||
              index < 0 ||
              index >= currentThanks.length ||
              index >= currentDates.length) {
            return;
          }
          editThankYou(text, index, userInfo, _updateThanksState);
        },
        text: text,
        formTitle: appLocale.thanks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserInformation>(context);
    final thanks = List<String>.from(userInfo.thanks['thanks'] ?? <String>[]);
    final dates = List<String>.from(userInfo.thanks['dates'] ?? <String>[]);
    final sourceIndexes = _todayIndexes(thanks, dates).reversed.toList();
    final todayItems = sourceIndexes.map((i) => thanks[i]).toList();
    _refreshHomeSuggestions(userInfo);

    return DashedListWidget(
      title: appLocale.gratitudeListTitle,
      subtitle: appLocale.gratitudeSubTitle(userInfo.gender),
      iconAsset: 'assets/images/thanks_icon.svg',
      items: todayItems,
      suggestions: _homeSuggestions,
      totalCount: todayItems.length,
      showAllItems: true,
      onOpenSection: widget.onOpenSection,
      onAddNew: () => _openThankDialog(userInfo),
      onEditItem: (displayIndex) {
        if (displayIndex < 0 || displayIndex >= sourceIndexes.length) return;
        final sourceIndex = sourceIndexes[displayIndex];
        final currentThanks = userInfo.thanks['thanks'] ?? <String>[];
        final currentDates = userInfo.thanks['dates'] ?? <String>[];
        if (!listEquals(currentThanks, thanks) ||
            !listEquals(currentDates, dates) ||
            sourceIndex < 0 ||
            sourceIndex >= thanks.length ||
            sourceIndex >= dates.length) {
          return;
        }
        _openThankDialog(userInfo, thanks[sourceIndex], sourceIndex);
      },
      onRemoveItem: (displayIndex) {
        if (displayIndex < 0 || displayIndex >= sourceIndexes.length) return;
        final sourceIndex = sourceIndexes[displayIndex];
        final currentThanks = userInfo.thanks['thanks'] ?? <String>[];
        final currentDates = userInfo.thanks['dates'] ?? <String>[];
        if (!listEquals(currentThanks, thanks) ||
            !listEquals(currentDates, dates) ||
            sourceIndex < 0 ||
            sourceIndex >= thanks.length ||
            sourceIndex >= dates.length) {
          return;
        }
        removeThankYou(sourceIndex, userInfo, _updateThanksState);
      },
      onAddSuggestion: (suggestion) => addThankYou(
        suggestion,
        userInfo,
        _updateThanksState,
        _showThankYouPopup,
      ),
    );
  }
}
