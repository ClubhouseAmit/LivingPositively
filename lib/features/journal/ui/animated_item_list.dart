import 'package:flutter/material.dart';
import 'package:mazilon/features/journal/ui/thank_you.dart';

// the list of the user's items on the journal page (thank yous, newest first)
// and the positive traits page (traits, oldest first).
// when an item is added, the new row fades and slides in, like the home page
// does for a promoted suggestion (DashedListWidget).
class AnimatedItemList extends StatefulWidget {
  final List<String> items;
  // one date per item; null shows no dates
  final List<String>? dates;
  // true: the last item is shown first, so the new row is the top one.
  // false: items show in order, so the new row is the bottom one.
  final bool newestFirst;
  final void Function(String text, int index) edit;
  final void Function(int index) remove;
  final Color color;

  const AnimatedItemList({
    super.key,
    required this.items,
    this.dates,
    required this.newestFirst,
    required this.edit,
    required this.remove,
    required this.color,
  });

  @override
  State<AnimatedItemList> createState() => _AnimatedItemListState();
}

class _AnimatedItemListState extends State<AnimatedItemList>
    with SingleTickerProviderStateMixin {
  static const Duration _kFadeInDuration = Duration(milliseconds: 480);
  // fraction of the row height the new row slides down from
  static const double _kSlideFrom = -0.12;

  late final AnimationController _fadeInController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slide;

  // the item count last shown; a bigger count means an item was added
  late int _shownCount;

  @override
  void initState() {
    super.initState();
    // starts settled so nothing animates on first load
    _fadeInController = AnimationController(
      vsync: this,
      duration: _kFadeInDuration,
      value: 1.0,
    );
    _fadeIn = CurvedAnimation(parent: _fadeInController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, _kSlideFrom),
      end: Offset.zero,
    ).animate(_fadeIn);
    _shownCount = widget.items.length;
  }

  @override
  void didUpdateWidget(AnimatedItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // compare with the stored count: the positive page grows its list in
    // place, so oldWidget.items can be the same (already grown) list
    if (widget.items.length > _shownCount) {
      _fadeInController.forward(from: 0.0);
    }
    _shownCount = widget.items.length;
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  Widget _buildItem(BuildContext context, int index) {
    final count = widget.items.length;
    final itemIndex = widget.newestFirst ? count - 1 - index : index;
    final row = ThankYou(
      text: widget.items[itemIndex],
      number: widget.newestFirst ? count - index : index + 1,
      edit: widget.edit,
      remove: widget.remove,
      date: widget.dates?[itemIndex] ?? '',
      color: widget.color,
    );
    final newRowIndex = widget.newestFirst ? 0 : count - 1;
    if (index != newRowIndex) {
      return row;
    }
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(position: _slide, child: row),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: _buildItem,
    );
  }
}
