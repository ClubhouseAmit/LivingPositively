import 'package:flutter/material.dart';

import 'package:mazilon/disclaimerPage.dart';
import 'package:mazilon/initialForm/form.dart';
import 'package:mazilon/pages/auth/auth_page.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/menu.dart';

// FirstPage widget determines the correct page to show based on user state.
// Routing order:
//   1. !disclaimerSigned  → DisclaimerPage
//   2. !authDecisionMade  → AuthPage  (login / sign up / skip)
//   3. firsttime          → InitialFormProgressIndicator
//   4. else               → Menu
class FirstPage extends StatefulWidget {
  PhonePageData phonePageData;
  bool firsttime;
  bool hasFilled;
  final Function changeLocale;
  FirstPage(
      {super.key,
      required this.firsttime,
      required this.hasFilled,
      required this.changeLocale,
      required this.phonePageData});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: true);

    if (!userInfoProvider.disclaimerSigned) {
      return DisclaimerPage(changeLocale: widget.changeLocale);
    }

    if (!userInfoProvider.authDecisionMade) {
      return const AuthPage();
    }

    if (widget.firsttime) {
      return InitialFormProgressIndicator(
          phonePageData: widget.phonePageData,
          changeLocale: widget.changeLocale);
    }

    return Menu(
        phonePageData: widget.phonePageData,
        hasFilled: widget.hasFilled,
        changeLocale: widget.changeLocale);
  }
}
