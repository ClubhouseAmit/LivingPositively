import 'package:flutter/material.dart';
import 'package:mazilon/features/journal/ui/thank_you.dart';

// the list of thank you notes on the journal page, newest first.
// when a note is added, the new (first) row fades and slides in, like the
// home page does for a promoted suggestion (DashedListWidget).
class ThankYouList extends StatefulWidget {
  final List<String> thankYous;
  final List<String> dates;
  final void Function(String text, int index) edit;
  final void Function(int index) remove;
  final Color color;

  const ThankYouList({
    super.key,
    required this.thankYous,
    required this.dates,
    required this.edit,
    required this.remove,
    required this.color,
  });

  @override
  State<ThankYouList> createState() => _ThankYouListState();
}

class _ThankYouListState extends State<ThankYouList>
    with SingleTickerProviderStateMixin {
  static const Duration _kFadeInDuration = Duration(milliseconds: 480);
  // fraction of the row height the new row slides down from
  static const double _kSlideFrom = -0.12;

  late final AnimationController _fadeInController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slide;

  // the note count last shown; a bigger count means a note was added
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
    _shownCount = widget.thankYous.length;
  }

  @override
  void didUpdateWidget(ThankYouList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thankYous.length > _shownCount) {
      _fadeInController.forward(from: 0.0);
    }
    _shownCount = widget.thankYous.length;
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  Widget _buildItem(BuildContext context, int index) {
    final reversedIndex = widget.thankYous.length - 1 - index;
    final row = ThankYou(
      text: widget.thankYous[reversedIndex],
      number: widget.thankYous.length - index,
      edit: widget.edit,
      remove: widget.remove,
      date: widget.dates[reversedIndex],
      color: widget.color,
    );
    if (index != 0) {
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
      itemCount: widget.thankYous.length,
      itemBuilder: _buildItem,
    );
  }
}
