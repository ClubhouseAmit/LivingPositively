//TODO: UNUSED WIDGET

import 'package:flutter/material.dart';

class ThankItem extends StatefulWidget {
  const ThankItem({required this.trait, super.key});
  final String trait;

  @override
  State<ThankItem> createState() => _ThankItemState();
}

class _ThankItemState extends State<ThankItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
          minWidth: 100,
          minHeight: 55,
          maxWidth: 800 / 2 - 15),
      child: Card(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              widget.trait,
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
