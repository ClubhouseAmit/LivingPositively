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
    final key = candidates.join('');
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
    showDialog(
      context: context,
      builder: (_) => AddForm(
        add: (thankYou, ui) =>
            addThankYou(thankYou, ui, _updateThanksState, _showThankYouPopup),
        index: index,
        edit: (t, i, ui) => editThankYou(t, i, ui, _updateThanksState),
        text: text,
        formTitle: appLocale.thanks,
      ),
    );
  }

  void _removeItem(int displayIndex, UserInformation userInfo) {
    final thanks = userInfo.thanks['thanks'] ?? <String>[];
    final dates = userInfo.thanks['dates'] ?? <String>[];
    final sourceIndexes = _todayIndexes(thanks, dates).reversed.toList();
    if (displayIndex < 0 || displayIndex >= sourceIndexes.length) return;
    removeThankYou(sourceIndexes[displayIndex], userInfo, _updateThanksState);
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserInformation>(context);
    final thanks = userInfo.thanks['thanks'] ?? <String>[];
    final dates = userInfo.thanks['dates'] ?? <String>[];
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
      onOpenSection: widget.onOpenSection,
      onAddNew: () => _openThankDialog(userInfo),
      onEditItem: (displayIndex) {
        if (displayIndex < 0 || displayIndex >= sourceIndexes.length) return;
        final sourceIndex = sourceIndexes[displayIndex];
        if (sourceIndex < 0 || sourceIndex >= thanks.length) return;
        _openThankDialog(userInfo, thanks[sourceIndex], sourceIndex);
      },
      onRemoveItem: (displayIndex) => _removeItem(displayIndex, userInfo),
      onAddSuggestion: (suggestion) => addThankYou(
        suggestion,
        userInfo,
        _updateThanksState,
        _showThankYouPopup,
      ),
    );
  }
}
