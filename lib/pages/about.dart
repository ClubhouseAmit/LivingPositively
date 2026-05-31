import 'package:flutter/material.dart';

import 'package:mazilon/util/styles.dart';
import 'package:mazilon/l10n/app_localizations.dart';

//the about page , it shows the about page text and the logos of the social hub and the clubhouse
//the text is fetched from the appInformation provider, which fetches the text from the firebase database.
//the logos are in the assets/images folder
String englishText =
    '''This application was developed by Technion Students. As part of the Computer Science Yearly Project Program.
Instructed by: Dina Alexadrovich. 
Interdisciplinary Center for Smart Computing,
CS Faculty,
Technion.''';

class About extends StatelessWidget {
  final String version;
  const About({super.key, required this.version});
  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(150.0),
        child: SafeArea(
          child: SizedBox(
            height: 130.0,
            // Mazilon Logo in the app bar
            child: Image.asset(
              'assets/images/Logo.png',
              width: MediaQuery.of(context).size.width * 0.4 > 1000
                  ? 500
                  : MediaQuery.of(context).size.width * 0.2, // Adjust as needed
            ),
          ),
        ),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: myAutoSizedText(
                  appLocale!.aboutTitle1,
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  TextAlign.center,
                  60,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: myAutoSizedText(
                  appLocale.aboutPage1,
                  TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                  appLocale.textDirection == "rtl"
                      ? TextAlign.right
                      : TextAlign.left,
                  35,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: myAutoSizedText(
                    englishText,
                    TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                    TextAlign.left,
                    35,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: myAutoSizedText(
                  appLocale.aboutTitle2,
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  TextAlign.center,
                  60,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: myAutoSizedText(
                  appLocale.aboutPage2,
                  TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                  appLocale.textDirection == "rtl"
                      ? TextAlign.right
                      : TextAlign.left,
                  35,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: myAutoSizedText(
                  appLocale
                      .informationCollectionDisclaimer, //disclaimer text from CMS(Saved in appinfo)
                  TextStyle(
                    fontSize: 20, //text size
                    fontWeight: FontWeight.normal,
                  ),
                  appLocale.textDirection == 'rtl'
                      ? TextAlign.right
                      : TextAlign.left,
                  40,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      appLocale.aboutVersionLabel(version),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Adjust alignment as needed
                children: [
                  Flexible(
                    child: Image.asset(
                      'assets/images/SocialHub-Logo.png',
                      width:
                          MediaQuery.of(context).size.width *
                          0.4, // Adjust as needed
                      // Optional: if you want to specify the height
                      // height: MediaQuery.of(context).size.height * 0.2, // Adjust as needed
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ), // Adds space between the two images
                  Flexible(
                    child: Image.asset(
                      'assets/images/clubhouse-Logo.png',
                      width:
                          MediaQuery.of(context).size.width *
                          0.4, // Adjust as needed
                      // Optional: if you want to specify the height
                      // height: MediaQuery.of(context).size.height * 0.2, // Adjust as needed
                    ),
                  ),
                  // you can add more images here to show them in the same row as the above two images,
                  // just copy the Flexible widget and change the image path and width as needed.
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
