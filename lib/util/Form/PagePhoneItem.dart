import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class PagePhoneItem extends StatefulWidget {
  const PagePhoneItem({
    required this.phoneNumber, required this.phoneName, required this.phoneDescription, required this.icon, super.key,
  });
  final String phoneNumber;
  final String phoneName;
  final String phoneDescription;
  final IconData icon;

  @override
  _PagePhoneItemState createState() => _PagePhoneItemState();
}

class _PagePhoneItemState extends State<PagePhoneItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    //item in the phone page form(icon + data)
    return Container(
      child: Row(
        children: [
          Icon(widget.icon),
          const SizedBox(width: 5),
          AutoSizeText(
            widget.phoneName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
          ),
          const SizedBox(width: 3),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 8,
            ), // Add horizontal spacing
            child: AutoSizeText(
              widget.phoneDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
