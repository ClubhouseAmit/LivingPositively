import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/menu.dart';
import 'package:mazilon/form/form.dart';

import 'package:mazilon/util/styles.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//the page before the personal plan questionnaire that allows the user to fill the questionnaire or skip it.
class ToFormPage extends StatefulWidget {
  final PhonePageData phonePageData;
  final Function changeLocale;

  const ToFormPage({
    super.key,
    required this.phonePageData,
    required this.changeLocale,
  });

  @override
  State<ToFormPage> createState() => _ToFormPageState();
}

class _ToFormPageState extends LPExtendedState<ToFormPage> {
  bool hasFilled = false;
  void getHasFilled() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    var hasFilledValue = await service.getItem(
      "hasFilled",
      PersistentMemoryType.Bool,
    );

    setState(() {
      hasFilled = hasFilledValue ?? false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getHasFilled();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    var gender = userInfoProvider.gender;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            myAutoSizedText(
              appLocale.introductionFormLastPageMainTitle(gender),
              TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              TextAlign.center,
              60,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
              child: myAutoSizedText(
                appLocale.introductionFormLastPageSubTitle1(gender),
                TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
                TextAlign.center,
                35,
              ),
            ),
            SizedBox(height: returnSizedBox(context, 20)),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
              child: myAutoSizedText(
                appLocale.introductionFormLastPageSubTitle2(gender),
                TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: appGreen,
                ),
                TextAlign.center,
                35,
              ),
            ),
            SizedBox(height: returnSizedBox(context, 20)),
            myImage('assets/images/initialFormPage3.png', context, 0.8, 0.4),
            //navigate to personal plan form button:
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FormProgressIndicator(
                          phonePageData: widget.phonePageData,
                          changeLocale: widget.changeLocale,
                        ), //place collections here
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          var begin = Offset(-1.0, 0.0);
                          var end = Offset.zero;
                          var tween = Tween(begin: begin, end: end);
                          var offsetAnimation = animation.drive(tween);

                          var fadeTween = Tween(begin: 0.0, end: 1.0);
                          var fadeAnimation = animation.drive(fadeTween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: fadeAnimation,
                              child: child,
                            ),
                          );
                        },
                  ),
                );
              },
              style: myButtonStyle,
              child: myAutoSizedText(
                appLocale.introductionFormLastPageNext(gender),
                myTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
                null,
                50,
              ),
            ),
            SizedBox(height: returnSizedBox(context, 15)),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Menu(
                      phonePageData: widget.phonePageData,
                      hasFilled: hasFilled,
                      changeLocale: widget.changeLocale,
                    ),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: myButtonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(
                    horizontal: returnSizedBox(context, 20),
                    vertical: returnSizedBox(context, 10),
                  ),
                ),
              ),
              child: myAutoSizedText(
                appLocale.skipButton(gender),
                myTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
                null,
                50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
