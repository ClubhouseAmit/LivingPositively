import 'package:flutter/material.dart';

/// Plain numbered label — no circle, no background, no wrapper.
class ListItemNumberWidget extends StatelessWidget {

  const ListItemNumberWidget({required this.index, super.key});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${index + 1}',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
