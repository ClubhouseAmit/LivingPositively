import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/styles.dart';

//Widget for the name of the user in the home page
class NameBar extends StatefulWidget {
  final List<Widget> icons;

  final String greetingString;
  const NameBar({super.key, required this.icons, required this.greetingString});

  @override
  State<NameBar> createState() => NameBarState();
}

class NameBarState extends LPExtendedState<NameBar> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width > 1000
          ? 800
          : MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Expanded(
                    child: AutoSizeText(
                      appLocale.greetings(userInfoProvider.name),
                      overflow: TextOverflow.ellipsis,
                      minFontSize: 12,
                      maxFontSize: 30,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Rubix',
                      ),
                    ),
                  ),
                  /* myAutoSizedText(
                        appLocale!.greetings(userInfoProvider.name),
                        TextStyle(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        null,
                        40),*/
                ),
                Row(children: widget.icons),
              ],
            ),
            myAutoSizedText(
              widget.greetingString,
              TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
              null,
              30,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
