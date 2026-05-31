// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//The first page of the initial form
//all text is in the CMS and is fetched from there
class InitialFormPage1 extends StatefulWidget {
  final Function next;
  final Function skip;
  final Function prev;
  final Function updateName;

  const InitialFormPage1({
    super.key,
    required this.next,
    required this.skip,
    required this.prev,
    required this.updateName,
  });
  @override
  State<InitialFormPage1> createState() => _InitialFormPage1State();
}

class _InitialFormPage1State extends LPExtendedState<InitialFormPage1> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              myAutoSizedText(
                appLocale.introductionFormFirstPageMainTitle(gender),
                TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold),
                TextAlign.center,
                60.0,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width / 5,
                  0,
                  MediaQuery.of(context).size.width / 5,
                  0,
                ),
                child: myAutoSizedText(
                  appLocale.introductionFormFirstPageSubTitle1(gender),
                  TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                  TextAlign.center,
                  35,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width / 6,
                  0,
                  MediaQuery.of(context).size.width / 6,
                  0,
                ),
                child: myAutoSizedText(
                  appLocale.introductionFormFirstPageSubTitle2(gender),
                  TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: appGreen,
                  ),
                  TextAlign.center,
                  35,
                ),
              ),
              Image.asset(
                'assets/images/initialFormPage1.png',
                width: MediaQuery.sizeOf(context).width * 0.8 > 1000
                    ? 400
                    : MediaQuery.sizeOf(context).width *
                          0.6, // Adjust as needed
                height:
                    MediaQuery.sizeOf(context).height * 0.3, // Adjust as needed
              ),
              ConfirmationButton(
                context,
                () {
                  widget.next();
                },
                appLocale.nextButton(gender),
                myTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
              SizedBox(height: returnSizedBox(context, 20)),
              ConfirmationButton(
                context,
                () {
                  widget.skip();
                },
                appLocale.skipButton(gender),
                myTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
