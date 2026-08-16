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

class _DisclaimerPageState extends LPExtendedState<DisclaimerPage> {
  Widget _section({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  String _getTitle(String localeCode) {
    switch (localeCode) {
      case 'he':
        return 'הצהרה';
      case 'ar':
        return 'تصريح';
      case 'en':
      default:
        return 'Disclaimer';
    }
  }

  Widget _languageButton(String locale, String label) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isSelected = currentLocale == locale;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (!isSelected) {
          widget.changeLocale(locale);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : onSurfaceColor.withOpacity(0.7),
            decoration:
                isSelected ? TextDecoration.underline : TextDecoration.none,
            decorationColor: primaryColor,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 20.0),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _languageButton('en', 'English'),
                                Text(
                                  '|',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3),
                                    fontSize: 14.sp,
                                  ),
                                ),
                                _languageButton('he', 'עברית'),
                                Text(
                                  '|',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3),
                                    fontSize: 14.sp,
                                  ),
                                ),
                                _languageButton('ar', 'العربية'),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              _getTitle(Localizations.localeOf(context).languageCode),
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                            child: Text(
                              appLocale.disclaimerSummary,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
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
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: ConfirmationButton(
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
