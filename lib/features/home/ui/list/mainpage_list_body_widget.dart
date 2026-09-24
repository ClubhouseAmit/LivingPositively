import 'package:flutter/material.dart';

import 'package:mazilon/features/home/ui/list/mainpage_list_item_number_widget.dart';
import 'package:mazilon/features/home/ui/list/mainpage_list_item_widget.dart';

class ListBodyWidget extends StatefulWidget {
  final List<String> listItems;
  final Function(int index) editItems;
  final Function(int index) removeItems;

  const ListBodyWidget({
    super.key,
    required this.listItems,
    required this.editItems,
    required this.removeItems,
  });

  @override
  State<ListBodyWidget> createState() => _ListBodyWidgetState();
}

class _ListBodyWidgetState extends State<ListBodyWidget> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 315),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: widget.listItems.asMap().entries.map((entry) {
            int index = entry.key;
            String item = entry.value;
            return Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListItemNumberWidget(index: index),
                  const SizedBox(width: 10),
                  MainpageListItemWidget(
                    item: item,
                    onEdit: () => widget.editItems(index),
                    onDelete: () => widget.removeItems(index),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
