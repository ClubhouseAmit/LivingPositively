// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/disclaimerLanguageSelect.dart';

// the disclaimer page widget,
// it shows the disclaimer text and a button to confirm the disclaimer
class DisclaimerPage extends StatefulWidget {
  final Function changeLocale;
  const DisclaimerPage({required this.changeLocale, super.key});
  @override
  State<DisclaimerPage> createState() => _DisclaimerPageState();
}

// a function to update the disclaimer signed in the shared preferences
void updateDisclaimers(userInfo) async {
  // get the shared preferences
  PersistentMemoryService service =
      GetIt.instance<
        PersistentMemoryService
      >(); // Get the persistent memory service instance

  await service.setItem("disclaimerConfirmed", PersistentMemoryType.Bool, true);

  userInfo.updateDisclaimerSigned(
    true,
  ); //update the disclaimer signed in the user information provider
}

String _formatDisclaimerText(AppLocalizations appLocale) {
  return '${appLocale.disclaimerText}\n\n${appLocale.informationCollectionDisclaimer}';
}

class _DisclaimerPageState extends LPExtendedState<DisclaimerPage> {
  // build the disclaimer page widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation and userInformation providers
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    // show the disclaimer text and a button to confirm the disaclaimer

    return PopScope(
      canPop: false, //can't go back from this page
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  LanguageDropDown(changeLocale: widget.changeLocale),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: myAutoSizedText(
                      _formatDisclaimerText(appLocale),
                      TextStyle(
                        fontSize: 16.sp, //text size
                        fontWeight: FontWeight.normal,
                      ),
                      appLocale.textDirection == 'rtl'
                          ? TextAlign.right
                          : TextAlign.left,
                      40,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: myAutoSizedText(
                      appLocale
                          .informationCollectionDisclaimer, //disclaimer text from CMS(Saved in appinfo)
                      TextStyle(
                        fontSize: 16.sp, //text size
                        fontWeight: FontWeight.normal,
                      ),
                      appLocale.textDirection == 'rtl'
                          ? TextAlign.right
                          : TextAlign.left,
                      40,
                    ),
                  ),
                  // the confirm disclaimer button
                  ConfirmationButton(
                    context,
                    () {
                      setState(() {
                        updateDisclaimers(
                          userInfoProvider,
                        ); //if button is clicked,
                        //update the disclaimer signed in the shared preferences (call the updateDisclaimers function)
                      });
                    },
                    //disclaimer next button text from CMS(Saved in appinfo)
                    appLocale.confirmButton(gender),
                    myTextStyle.copyWith(fontSize: 20.sp),
                  ),
                  SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
