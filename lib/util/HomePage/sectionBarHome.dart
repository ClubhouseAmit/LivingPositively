import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/spacing.dart';


//Template for the "title" of sections in the home page
//i.e "התוכנית שלי", "רשימת מעלות", "תודו ליסט"
//specifically, the titles in the home page
class SectionBarHome extends StatefulWidget { //what's the subtitle
  const SectionBarHome({
    required this.textWidget, required this.icons, required this.subHeader, super.key,
  });
  final Widget textWidget; // what's the title
  final List<Widget>
  icons; //icons to interact with on the left side of the section
  final String subHeader;

  @override
  State<SectionBarHome> createState() => SectionBarHomeState();
}

class SectionBarHomeState extends LPExtendedState<SectionBarHome> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Row(
                  children: [
                    Flexible(child: widget.textWidget),
                  ],
                ),
              ),
            ),
            Row(children: widget.icons),
          ],
        ),
        if (widget.subHeader.isNotEmpty) Padding(
                padding: const EdgeInsetsDirectional.only(start: 0, end: 18),
                child: AutoSizeText(
                  widget.subHeader,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                  
                ),
              ) else Container(),
      ],
    );
  }
}
