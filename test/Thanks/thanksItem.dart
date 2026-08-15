//TODO: UNUSED WIDGET

import 'package:flutter/material.dart';

class ThankItem extends StatefulWidget {
  final String trait;
  const ThankItem({super.key, required this.trait});

  @override
  State<ThankItem> createState() => _ThankItemState();
}

class _ThankItemState extends State<ThankItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 100,
        minHeight: 55,
        maxWidth: MediaQuery.of(context).size.width / 2 - 15,
      ),
      child: Card(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              widget.trait,
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
              style: TextStyle(
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
