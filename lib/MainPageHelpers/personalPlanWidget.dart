import 'package:fluttericon/elusive_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';

import 'package:mazilon/util/personalPlanItem.dart';
import 'package:mazilon/util/styles.dart';

import 'dart:math';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// the personal plan widget, thats related to the personal plan section in home page
class PersonalPlanWidget extends StatefulWidget {
  final Map<String, dynamic> text; // the text of the personal plan
  final Function(BuildContext, PagesCode)
  changeCurrentIndex; // the function to change the current index
  const PersonalPlanWidget({
    super.key,
    required this.text,
    required this.changeCurrentIndex,
  });

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
    final items = List<String>.from(widget.text['list'] ?? const <String>[]);
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
    UserInformation userInfoProvider,
    String gender,
    String username,
  ) {
    const controlSlotSize = 48.0;
    final textDirection = Directionality.of(context);
    final theme = Theme.of(context);
    final controlColor = theme.colorScheme.onSurface;
    final refreshColor = theme.colorScheme.outline;
    final items = List<String>.from(widget.text['list'] ?? const <String>[]);
    final canRefresh = _hasAlternativeVisiblePreview(items);
    final subHeader = widget.text['SubTitle'] as String? ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleMaxWidth = max(
          0.0,
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
                  constraints: BoxConstraints(maxWidth: titleMaxWidth),
                  child: TextButton(
                    key: const Key('personalPlanHeaderTitle'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      widget.changeCurrentIndex(context, PagesCode.FullPlan);
                    },
                    child: myAutoSizedText(
                      appLocale.personalPlanPageMyPlan(gender),
                      TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: controlColor,
                      ),
                      null,
                      40,
                    ),
                  ),
                ),
                SizedBox(
                  key: const Key('personalPlanHeaderDocument'),
                  width: controlSlotSize,
                  height: controlSlotSize,
                  child: Center(
                    child: Icon(Icons.note_add, color: controlColor, size: 30),
                  ),
                ),
                Expanded(
                  child: Row(
                    key: const Key('personalPlanHeaderActions'),
                    textDirection: textDirection,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: appLocale.refreshPersonalPlanTooltip,
                        child: IconButton(
                          key: const Key('personalPlanHeaderRefresh'),
                          constraints: const BoxConstraints.tightFor(
                            width: controlSlotSize,
                            height: controlSlotSize,
                          ),
                          padding: EdgeInsets.zero,
                          color: refreshColor,
                          disabledColor: theme.disabledColor,
                          onPressed: canRefresh
                              ? _refreshPersonalPlanPreview
                              : null,
                          icon: Icon(Icons.refresh, size: min(35.sp, 40)),
                        ),
                      ),
                      Tooltip(
                        message: appLocale.downloadPlanTooltip,
                        child: IconButton(
                          key: const Key('personalPlanHeaderDownload'),
                          constraints: const BoxConstraints.tightFor(
                            width: controlSlotSize,
                            height: controlSlotSize,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            await preparePersonalPlanExport(userInfoProvider);
                            final exportMetadata =
                                buildPersonalPlanExportMetadata(
                                  appLocale,
                                  gender,
                                  username,
                                );
                            final result = await fileService.download(
                              exportMetadata.titles,
                              exportMetadata.subTitles,
                              appInfoProvider.sharePDFtexts,
                              ShareFileType.PDF,
                              mainTitle: exportMetadata.mainTitle,
                              textDirection: appLocale.textDirection,
                            );
                            if (result == null) {
                              showToast(
                                message: appLocale.downloadFailed(gender),
                              );
                              return;
                            }
                            showToast(
                              message: appLocale.finishedDownloading(gender),
                            );
                          },
                          icon: Icon(
                            Icons.download,
                            color: controlColor,
                            size: 30,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: appLocale.sharePlanTooltip,
                        child: IconButton(
                          key: const Key('personalPlanHeaderShare'),
                          constraints: const BoxConstraints.tightFor(
                            width: controlSlotSize,
                            height: controlSlotSize,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            showShareDialog(context);
                          },
                          icon: Transform.scale(
                            key: const Key('personalPlanHeaderShareTransform'),
                            alignment: Alignment.center,
                            scaleX: textDirection == TextDirection.rtl ? -1 : 1,
                            child: Icon(
                              Elusive.share,
                              color: controlColor,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subHeader.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 5, end: 18.0),
                child: myAutoSizedText(
                  subHeader,
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  30,
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
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          children: [
            _buildPersonalPlanHeader(
              context,
              appInfoProvider,
              userInfoProvider,
              gender,
              userInfoProvider.name,
            ),
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
            LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: TextButton(
                      key: const Key('personalPlanViewAllButton'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        widget.changeCurrentIndex(context, PagesCode.FullPlan);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: myAutoSizedText(
                              appLocale.personalPlanPageAllPlan(gender),
                              TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp, // the font size of the text
                              ),
                              TextAlign.start,
                              20,
                              2,
                            ),
                          ),
                          const Icon(Icons.arrow_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
