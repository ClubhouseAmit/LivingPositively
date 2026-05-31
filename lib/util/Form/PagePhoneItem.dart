import 'package:flutter/material.dart';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PagePhoneItem extends StatefulWidget {
  final String phoneNumber;
  final String phoneName;
  final String phoneDescription;
  final IconData icon;
  const PagePhoneItem({
    super.key,
    required this.phoneNumber,
    required this.phoneName,
    required this.phoneDescription,
    required this.icon,
  });

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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(widget.icon),
          const SizedBox(width: 5.0),
          myAutoSizedText(
            widget.phoneName,
            TextStyle(fontSize: 16.sp, fontWeight: FontWeight.normal),
            null,
            28, // Make the text bold
          ),
          const SizedBox(width: 3.0),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 8.0,
            ), // Add horizontal spacing
            child: myAutoSizedText(
              widget.phoneDescription,
              TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12.sp,
                color: Colors.grey,
              ),
              null,
              22, // Make the text grey
            ),
          ),
        ],
      ),
    );
  }
}
