import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Phone/EmergencyPhones.dart';

class PhonePage extends StatefulWidget {
  final PhonePageData phonePageData;
  const PhonePage({super.key, required this.phonePageData});

  @override
  _PhonePageState createState() => _PhonePageState();
}

class _PhonePageState extends LPExtendedState<PhonePage> {
  String mainTitle = '';
  String contactsTitle = '';
  String emergencyNumbersTitle = '';
  //myPhones: list of phone NUMBERS added in form Phone Page:
  List<String> myPhones = [];
  //myContacts: list of contact NAMES added in form Phone Page:
  List<String> myContacts = [];

  void loadData() async {
    setState(() {
      //numbers:
      myPhones = widget.phonePageData.savedPhoneNumbers;
      //names:
      myContacts = widget.phonePageData.savedPhoneNames;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    final gender = userInfoProvider.gender;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.05,
          left: MediaQuery.of(context).size.width * 0.05,
          right: MediaQuery.of(context).size.width * 0.05,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100.0),
            child: Center(
              // Replaced Expanded with Center
              child: Column(
                children: <Widget>[
                  myAutoSizedText(
                    appLocale.phonePageTitle(gender),
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp),
                    TextAlign.center,
                    60,
                  ),
                  const SizedBox(height: 10.0),
                  Center(
                    child: Container(
                      alignment: Alignment.topCenter,
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: myAutoSizedText(
                        appLocale.addingContactDisclaimer,
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                          height: 1.5,
                        ),
                        TextAlign.center,
                        40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  Align(
                    alignment: appLocale.textDirection == "rtl"
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 30.0,
                      ), // adjust the value as needed
                      child: myAutoSizedText(
                        appLocale.yourContacts(gender),
                        TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.normal,
                        ),
                        null,
                        30,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10.0),
                  //list of phones added in form Phone Page:
                  ...List.generate(
                    myPhones.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(
                        bottom: 10.0,
                      ), // adjust as needed
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30.0,
                        ), // adjust as needed
                        child: phoneContact(myPhones[index], myContacts[index]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Align(
                    alignment: appLocale.textDirection == "rtl"
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 30.0,
                      ), // adjust the value as needed
                      child: myAutoSizedText(
                        appLocale.emergencyNumbers(gender),
                        TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.normal,
                        ),
                        null,
                        30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  //emergency phones grid: (police/105/etc..)
                  EmergencyPhonesGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
