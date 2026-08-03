import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/personalPlanItem.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// the personal plan widget, thats related to the personal plan section in home page
class PersonalPlanWidget extends StatefulWidget { // the function to change the current index
  const PersonalPlanWidget({
    required this.text, required this.changeCurrentIndex, super.key,
  });
  final Map<String, dynamic> text; // the text of the personal plan
  final Function(BuildContext, PagesCode)
  changeCurrentIndex;

  @override
  State<PersonalPlanWidget> createState() => _PersonalPlanWidgetState();
}

class _PersonalPlanWidgetState extends LPExtendedState<PersonalPlanWidget> {
  late FileService fileService;
  final Random _random = Random();
  List<int> _selectedIndexes = <int>[];
  List<String> randomItems = <String>[];
  List<String> feelBetter = [];

  void loadFeelBetter({bool avoidCurrentSelection = false}) {
    final items = List<String>.from((widget.text['list'] as List<dynamic>?) ?? const <String>[]);
    final previousIndexes = _selectedIndexes;

    if (items.length < 2) {
      _selectedIndexes = List<int>.generate(items.length, (index) => index);
    } else if (items.length == 2 &&
        avoidCurrentSelection &&
        previousIndexes.length == 2) {
      _selectedIndexes = previousIndexes.reversed.toList();
    } else {
      _selectedIndexes = _selectPreviewIndexes(
        items,
        previousIndexes,
        avoidCurrentSelection: avoidCurrentSelection,
      );
    }

    randomItems = _selectedIndexes.map((index) => items[index]).toList();
  }

  List<List<int>> _previewCandidates(List<String> items) {
    return <List<int>>[
      for (var firstIndex = 0; firstIndex < items.length - 1; firstIndex++)
        for (
          var secondIndex = firstIndex + 1;
          secondIndex < items.length;
          secondIndex++
        )
          <int>[firstIndex, secondIndex],
    ];
  }

  List<int> _selectPreviewIndexes(
    List<String> items,
    List<int> previousIndexes, {
    required bool avoidCurrentSelection,
  }) {
    final candidates = _previewCandidates(items);
    var availableCandidates = candidates;

    if (avoidCurrentSelection && previousIndexes.length == 2) {
      final visiblyDifferentCandidates = candidates
          .where(
            (candidate) =>
                !_hasSameVisibleItems(candidate, previousIndexes, items),
          )
          .toList();
      availableCandidates = visiblyDifferentCandidates.isNotEmpty
          ? visiblyDifferentCandidates
          : candidates
                .where(
                  (candidate) =>
                      !_hasSameSelectedIndexes(candidate, previousIndexes),
                )
                .toList();
    }

    final selectedIndexes = List<int>.from(
      availableCandidates[_random.nextInt(availableCandidates.length)],
    )..shuffle(_random);
    return selectedIndexes;
  }

  bool _hasSameSelectedIndexes(List<int> indexes, List<int> previousIndexes) {
    return indexes.length == previousIndexes.length &&
        indexes.every(previousIndexes.contains);
  }

  bool _hasSameVisibleItems(
    List<int> indexes,
    List<int> previousIndexes,
    List<String> items,
  ) {
    if (indexes.length != previousIndexes.length) {
      return false;
    }

    final visibleItems = indexes.map((index) => items[index]).toList()..sort();
    final previousItems = previousIndexes.map((index) => items[index]).toList()
      ..sort();
    for (var index = 0; index < visibleItems.length; index++) {
      if (visibleItems[index] != previousItems[index]) {
        return false;
      }
    }
    return true;
  }

  bool _hasAlternativeVisiblePreview(List<String> items) {
    if (items.length <= 2 || _selectedIndexes.length != 2) {
      return false;
    }

    return _previewCandidates(items).any(
      (candidate) => !_hasSameVisibleItems(candidate, _selectedIndexes, items),
    );
  }

  void _refreshPersonalPlanPreview() {
    setState(() {
      loadFeelBetter(avoidCurrentSelection: true);
    });
  }

  @override
  void initState() {
    super.initState();
    fileService = GetIt.instance<FileService>();
    loadFeelBetter();
  }

  @override
  void didUpdateWidget(PersonalPlanWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      loadFeelBetter();
    }
  }

  Widget _buildPersonalPlanHeader(
    BuildContext context,
    AppInformation appInfoProvider,
    String gender,
  ) {
    const controlSlotSize = 36.0;
    final textDirection = Directionality.of(context);
    final theme = Theme.of(context);
    final controlColor = theme.colorScheme.onSurface;
    final iconColor = theme.colorScheme.primary;
    final items = List<String>.from((widget.text['list'] as List<dynamic>?) ?? const <String>[]);
    final canRefresh = _hasAlternativeVisiblePreview(items);
    final subHeader = widget.text['SubTitle'] as String? ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleMaxWidth = max(
          0,
          constraints.maxWidth - controlSlotSize * 4,
        );

        return Column(
          key: const Key('personalPlanHeader'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: textDirection,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: titleMaxWidth.toDouble()),
                  child: TextButton(
                    key: const Key('personalPlanHeaderTitle'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      widget.changeCurrentIndex(context, PagesCode.FullPlan);
                    },
                    child: AutoSizeText(
                      appLocale.personalPlanPageMyPlan(gender),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: controlColor,
                          ),
                    ),
                  ),
                ),

                Expanded(
                  child: Row(
                    key: const Key('personalPlanHeaderActions'),
                    textDirection: textDirection,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        key: const Key('personalPlanHeaderActionsButton'),
                        icon: Icon(LucideIcons.moreVertical, color: iconColor),
                        tooltip: 'Actions',
                        onSelected: (String result) async {
                          if (result == 'refresh' && canRefresh) {
                            _refreshPersonalPlanPreview();
                          } else if (result == 'download') {
                            final res = await fileService.download(
                              [
                                appLocale.difficultEventsHeader(gender),
                                appLocale.makeSaferHeader(gender),
                                appLocale.feelBetterHeader(gender),
                                appLocale.distractionsHeader(gender),
                                appLocale.phonesPageHeader(gender),
                              ],
                              [
                                appLocale.difficultEventsSubTitle(gender),
                                appLocale.makeSaferSubTitle(gender),
                                appLocale.feelBetterSubTitle(gender),
                                appLocale.distractionsSubTitle(gender),
                                appLocale.phonesPageSubTitle(gender),
                              ],
                              appInfoProvider.sharePDFtexts,
                              ShareFileType.PDF,
                              appLocale.textDirection,
                            );
                            if (res == null) {
                              showToast(
                                message: appLocale.downloadFailed(gender),
                              );
                              return;
                            }
                            showToast(
                              message: appLocale.finishedDownloading(gender),
                            );
                          } else if (result == 'share') {
                            showShareDialog(context);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            key: const Key('personalPlanHeaderRefresh'),
                            value: 'refresh',
                            enabled: canRefresh,
                            child: Row(
                              children: [
                                Icon(LucideIcons.rotateCw, color: iconColor, size: 20),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    appLocale.refreshPersonalPlanTooltip,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            key: const Key('personalPlanHeaderDownload'),
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(LucideIcons.download, color: iconColor, size: 20),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    appLocale.downloadPlanTooltip,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            key: const Key('personalPlanHeaderShare'),
                            value: 'share',
                            child: Row(
                              children: [
                                Transform.scale(
                                  scaleX: textDirection == TextDirection.rtl ? -1 : 1,
                                  child: Icon(LucideIcons.share2, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    appLocale.sharePlanTooltip,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subHeader.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: Spacing.sm, end: Spacing.md),
                child: AutoSizeText(
                  subHeader,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  textAlign: textDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                ),
              ),
          ],
        );
      },
    );
  }

  // the build function of the personal plan widget
  @override
  Widget build(BuildContext context) {
    // the providers of the app information and the user information
    final appInfoProvider = Provider.of<AppInformation>(context);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    final gender = userInfoProvider.gender;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Column(
          children: [
            _buildPersonalPlanHeader(context, appInfoProvider, gender),
            const SizedBox(height: Spacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumn = constraints.maxWidth >= 520;
                final itemWidth = twoColumn
                    ? (constraints.maxWidth - 8) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: randomItems
                      .map(
                        (pPlan) => SizedBox(
                          width: itemWidth,
                          child: PersonalPlanItem(text: pPlan),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            // the button to take the user to the personal plan page.
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md),
              child: ElevatedButton(
                key: const Key('personalPlanViewAllButton'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(Spacing.xxl),
                ),
                onPressed: () {
                  widget.changeCurrentIndex(context, PagesCode.FullPlan);
                },
                child: Text(
                  appLocale.personalPlanPageAllPlan(gender),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
