import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/suggestion_add_button.dart';

// a suggestion row: an add button next to the suggested text in a dotted
// border. tapping either shrinks the row away (same shrink as the home page,
// DashedListWidget), then calls onAdd, then shows the row again with
// whatever text the parent passes next.
// the parent owns what gets added and which suggestion comes next
// (ThanksItemSuggested, PositiveTraitItemSug); this owns the look and feel.
class SuggestedListItem extends StatefulWidget {
  final String text;
  final Future<void> Function() onAdd;

  const SuggestedListItem({super.key, required this.text, required this.onAdd});

  @override
  State<SuggestedListItem> createState() => _SuggestedListItemState();
}

class _SuggestedListItemState extends LPExtendedState<SuggestedListItem>
    with SingleTickerProviderStateMixin {
  static const Duration _kCollapseDuration = Duration(milliseconds: 400);
  late final AnimationController _collapse;
  late final Animation<double> _collapseOpacity;
  late final Animation<double> _collapseSize;

  @override
  void initState() {
    super.initState();
    _collapse = AnimationController(vsync: this, duration: _kCollapseDuration);
    _collapseOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapse,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );
    _collapseSize = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapse,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _collapse.dispose();
    super.dispose();
  }

  // Shrink away, add, then show again. Shared by the add button and the
  // text. Not dismissed means a shrink or an add is in flight: one add each.
  Future<void> _add() async {
    if (_collapse.status != AnimationStatus.dismissed) return;
    await _collapse.forward();
    if (!mounted) return;
    await widget.onAdd();
    if (!mounted) return;
    _collapse.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _collapseSize,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(opacity: _collapseOpacity, child: _row()),
    );
  }

  Widget _row() {
    return Container(
      padding: const EdgeInsets.all(SuggestionGaps.rowInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SuggestionAddButton(onPressed: _add),
          const SizedBox(width: SuggestionGaps.rowInset),
          // tapping the text adds it too, like the home page
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _add,
              child: _dottedText(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dottedText() {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(AppRadii.button),
        dashPattern: const [5, 5],
        color: Theme.of(context).colorScheme.tertiary,
        strokeWidth: 2,
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SuggestionGaps.textInset),
          child: Align(
            alignment: appLocale.textDirection == "rtl"
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: AutoSizeText(
              widget.text,
              maxLines: 3,
              minFontSize: 14,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: "Rubix",
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
