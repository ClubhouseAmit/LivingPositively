import 'package:flutter/material.dart';

class SectionBarHome extends StatefulWidget {
  const SectionBarHome({
    required this.text, required this.textWidget, required this.icon, required this.icons, required this.subHeader, super.key,
  });
  final String text;
  final Widget textWidget;
  final IconData icon;
  final List<Widget> icons;
  final String subHeader;

  @override
  State<SectionBarHome> createState() => SectionBarHomeState();
}

class SectionBarHomeState extends State<SectionBarHome> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: widget.icons),
            Row(
              children: [
                if (widget.text.isEmpty) widget.textWidget else Text(
                        widget.text,
                      ),
                Icon(
                  widget.icon,
                  color: Colors.black,
                  size: 30,
                ),
              ],
            ),
          ],
        ),
        if (widget.subHeader.isNotEmpty) Padding(
                padding: const EdgeInsets.only(right: 18, left: 5),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    widget.subHeader,
                  ),
                ),
              ) else Container(),
      ],
    );
  }
}
