// ignore_for_file: prefer_const_constructors
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/disclaimerLanguageSelect.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// the disclaimer page widget,
// it shows the disclaimer text and a button to confirm the disclaimer
class DisclaimerPage extends StatefulWidget {
  const DisclaimerPage({required this.changeLocale, super.key});
  final Function changeLocale;
  @override
  State<DisclaimerPage> createState() => _DisclaimerPageState();
}

// a function to update the disclaimer signed in the shared preferences
Future<void> updateDisclaimers(userInfo) async {
  // get the shared preferences
  final service =
      GetIt.instance<
        PersistentMemoryService
      >(); // Get the persistent memory service instance

  await service.setItem('disclaimerConfirmed', PersistentMemoryType.Bool, true);

  userInfo.updateDisclaimerSigned(
    true,
  ); //update the disclaimer signed in the user information provider
}

class _DisclaimerPageState extends LPExtendedState<DisclaimerPage> {
  Widget _section({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: AutoSizeText(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.start,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  // build the disclaimer page widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation and userInformation providers
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    final gender = userInfoProvider.gender;

    // show the disclaimer text and a button to confirm the disaclaimer

    return PopScope(
      canPop: false, //can't go back from this page
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    LanguageDropDown(changeLocale: widget.changeLocale),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: AutoSizeText(
                        appLocale.disclaimerSummary,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.start,
                        maxLines: 3,
                      ),
                    ),
                    _section(
                      title: appLocale.disclaimerPurposeTitle,
                      body: appLocale.disclaimerText,
                    ),
                    _section(
                      title: appLocale.disclaimerInformationTitle,
                      body: appLocale.informationCollectionDisclaimer,
                    ),
                    _section(
                      title: appLocale.disclaimerConsentTitle,
                      body: appLocale.disclaimerConsentMessage,
                    ),
                    // the confirm disclaimer button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          updateDisclaimers(
                            userInfoProvider,
                          ); //if button is clicked,
                          //update the disclaimer signed in the shared preferences (call the updateDisclaimers function)
                        });
                      },
                      child: Text(appLocale.confirmButton(gender)),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
