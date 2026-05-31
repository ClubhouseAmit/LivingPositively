import 'package:flutter/material.dart';

import 'package:mazilon/disclaimerPage.dart';
import 'package:mazilon/initialForm/form.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/menu.dart';

// FirstPage widget determines the correct page
// to navigate to based on the user's status (e.g., disclaimer signed, logged in, first time using the app).
class FirstPage extends StatefulWidget {
  final PhonePageData phonePageData; // Data related to phone page
  final bool
  firsttime; // Flag indicating if this is the first time the user is using the app
  final bool
  hasFilled; // Flag indicating if the user has filled out required forms
  final Function changeLocale;
  const FirstPage({
    super.key,
    required this.firsttime,
    required this.hasFilled,
    required this.changeLocale,
    required this.phonePageData,
  });

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final Widget renderedWidget;

    // If the user has not signed the disclaimer, show the DisclaimerPage.
    if (!userInfoProvider.disclaimerSigned) {
      renderedWidget = DisclaimerPage(changeLocale: widget.changeLocale);
    } else
    // If the user is not logged in, navigate to the LoginPage.
    // If this is the user's first time using the app, show the initial form progress indicator.
    if (widget.firsttime) {
      renderedWidget = InitialFormProgressIndicator(
        phonePageData: widget.phonePageData,
        changeLocale: widget.changeLocale,
      );
    } else {
      renderedWidget = Menu(
        phonePageData: widget.phonePageData,
        hasFilled: widget.hasFilled,
        changeLocale: widget.changeLocale,
      );
    }

    return (renderedWidget);

    // If none of the above, show the main menu of the app.
  }
}
