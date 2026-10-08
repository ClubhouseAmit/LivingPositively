import 'package:flutter/material.dart';
import 'package:mazilon/features/journal/ui/thank_you.dart';

// the list of positive traits on the positive traits page, oldest first.
// when a trait is added, the new (last) row fades and slides in, like the
// home page does for a promoted suggestion (DashedListWidget).
class PositiveTraitList extends StatefulWidget {
  final List<String> traits;
  final void Function(String text, int index) edit;
  final void Function(int index) remove;
  final Color color;

  const PositiveTraitList({
    super.key,
    required this.traits,
    required this.edit,
    required this.remove,
    required this.color,
  });

  @override
  State<PositiveTraitList> createState() => _PositiveTraitListState();
}

class _PositiveTraitListState extends State<PositiveTraitList>
    with SingleTickerProviderStateMixin {
  static const Duration _kFadeInDuration = Duration(milliseconds: 480);
  // fraction of the row height the new row slides down from
  static const double _kSlideFrom = -0.12;

  late final AnimationController _fadeInController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slide;

  // the trait count last shown; a bigger count means a trait was added
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
    _shownCount = widget.traits.length;
  }

  @override
  void didUpdateWidget(PositiveTraitList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // compare with the stored count: the page grows the list in place, so
    // oldWidget.traits can be the same (already grown) list
    if (widget.traits.length > _shownCount) {
      _fadeInController.forward(from: 0.0);
    }
    _shownCount = widget.traits.length;
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  Widget _buildItem(BuildContext context, int index) {
    final row = ThankYou(
      text: widget.traits[index],
      number: index + 1,
      edit: widget.edit,
      remove: widget.remove,
      date: '',
      color: widget.color,
    );
    if (index != widget.traits.length - 1) {
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
      itemCount: widget.traits.length,
      itemBuilder: _buildItem,
    );
  }
}
