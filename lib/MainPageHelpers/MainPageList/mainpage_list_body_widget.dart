import 'package:flutter/material.dart';

import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_item_number_widget.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_item_widget.dart';

class ListBodyWidget extends StatefulWidget {

  const ListBodyWidget({
    required this.listItems, required this.editItems, required this.removeItems, super.key,
  });
  final List<String> listItems;
  final void Function(int index) editItems;
  final void Function(int index) removeItems;

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
          spacing: 8,
          runSpacing: 4,
          children: widget.listItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Row(
                children: [
                  ListItemNumberWidget(index: index),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MainpageListItemWidget(
                      item: item,
                      onEdit: () => widget.editItems(index),
                      onDelete: () => widget.removeItems(index),
                    ),
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
