import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/theme/spacing.dart';

//the about page , it shows the about page text and the logos of the social hub and the clubhouse
//the text is fetched from the appInformation provider, which fetches the text from the firebase database.
//the logos are in the assets/images folder
String englishText =
    '''
This application was developed by Technion Students. As part of the Computer Science Yearly Project Program.
Instructed by: Dina Alexadrovich. 
Interdisciplinary Center for Smart Computing,
CS Faculty,
Technion.''';

class About extends StatelessWidget {
  const About({
    required this.version,
    this.onBackPressed,
    super.key,
  });
  final String version;
  final VoidCallback? onBackPressed;
  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context);

    return PageLayoutWrapper(
      sliverAppBar: PremiumGlassAppBar(
        variant: AppBarVariant.detailScreen,
        onBackPressed: onBackPressed,
        titleText: appLocale!.aboutTitle1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Spacing.md),
          Text(
            appLocale.aboutTitle1,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: Spacing.lg),
          Container(
            alignment: Alignment.topCenter,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: AutoSizeText(
              appLocale.aboutPage1,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            alignment: Alignment.topCenter,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: AutoSizeText(
                englishText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            alignment: Alignment.topCenter,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Semantics(
              header: true,
              child: AutoSizeText(
                appLocale.aboutTitle2,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.topCenter,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: AutoSizeText(
              appLocale.aboutPage2,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
              textAlign: TextAlign.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: AutoSizeText(
              appLocale.informationCollectionDisclaimer,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
              textAlign: TextAlign.start,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  appLocale.aboutVersionLabel(version),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleLarge,
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
                ),
              ),
              const SizedBox(
                width: 20,
              ), // Adds space between the two images
              Flexible(
                child: Image.asset(
                  'assets/images/clubhouse-Logo.png',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
