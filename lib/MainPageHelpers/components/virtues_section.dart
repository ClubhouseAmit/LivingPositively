import 'package:flutter/material.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/list_utils.dart';
import 'package:mazilon/MainPageHelpers/components/dashed_list_widget.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class VirtuesSectionWidget extends StatefulWidget {
  final List<String> virtues;
  final VoidCallback onOpenSection;

  const VirtuesSectionWidget({
    required this.virtues,
    required this.onOpenSection,
    super.key,
  });

  @override
  State<VirtuesSectionWidget> createState() => _VirtuesSectionWidgetState();
}

class _VirtuesSectionWidgetState extends LPExtendedState<VirtuesSectionWidget> {
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

  List<String> _eligibleSuggestions(UserInformation userInfo) {
    final gender = userInfo.gender.isEmpty ? 'other' : userInfo.gender;
    final all = retrieveTraitsList(appLocale, gender);
    final eligible = <String>[];
    for (final s in all) {
      if (!userInfo.positiveTraits.contains(s) && !eligible.contains(s)) {
        eligible.add(s);
      }
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

  void _updateTraitsState(dynamic newTraits, dynamic userInfo) {
    setState(() {
      userInfo.updatePositiveTraits(newTraits);
      _refreshHomeSuggestions(userInfo);
    });
  }

  void _openTraitDialog([String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AddForm(
          add: (trait, userInfo) =>
              addPositiveTrait(trait, userInfo, _updateTraitsState),
          index: index,
          edit: (t, i, userInfo) =>
              editPositiveTrait(t, i, userInfo, _updateTraitsState),
          text: text,
          formTitle: appLocale.trait,
        );
      },
    );
  }

  void _removeItem(int index, UserInformation userInfo) {
    final traits = userInfo.positiveTraits;
    if (index < 0 || index >= traits.length) return;
    removePositiveTrait(index, userInfo, _updateTraitsState);
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserInformation>(context);
    _refreshHomeSuggestions(userInfo);

    // Pass virtues newest-first so the promoted item appears at #1
    final reversedVirtues = widget.virtues.reversed.toList();

    return DashedListWidget(
      title: appLocale.traitsListTitle,
      subtitle: appLocale.traitsSubTitle(userInfo.gender),
      iconAsset: 'assets/images/diamond_icon.svg',
      items: reversedVirtues,
      suggestions: _homeSuggestions,
      totalCount: userInfo.positiveTraits.length,
      onOpenSection: widget.onOpenSection,
      onAddNew: _openTraitDialog,
      onEditItem: (displayIndex) {
        // Map reversed display index → original positiveTraits index
        final originalIndex = widget.virtues.length - 1 - displayIndex;
        final traits = userInfo.positiveTraits;
        if (originalIndex < 0 || originalIndex >= traits.length) return;
        _openTraitDialog(traits[originalIndex], originalIndex);
      },
      onRemoveItem: (displayIndex) {
        final originalIndex = widget.virtues.length - 1 - displayIndex;
        _removeItem(originalIndex, userInfo);
      },
      onAddSuggestion: (suggestion) =>
          addPositiveTrait(suggestion, userInfo, _updateTraitsState),
    );
  }
}
