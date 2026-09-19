import 'package:flutter/material.dart';

import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/shell/ui/directional_widgets.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

// About page: project credits, partner logos. Copy is local today; CMS wiring
// for partner blurbs is still elsewhere in the app.
const String _englishCredits = '''This application was developed by Technion Students. As part of the Computer Science Yearly Project Program.
Instructed by: Dina Alexadrovich. 
Interdisciplinary Center for Smart Computing,
CS Faculty,
Technion.''';

class About extends StatelessWidget {
  final String version;
  const About({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final logoWidth = MediaQuery.of(context).size.width * 0.4 > 1000
        ? 500.0
        : MediaQuery.of(context).size.width * 0.2;

    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              children: [
                LivingPositivelyLogo(width: logoWidth),
                _AboutHeading(appLocale.aboutTitle1),
                _AboutBody(
                  appLocale.aboutPage1,
                  align: appLocale.textDirection == 'rtl'
                      ? TextAlign.right
                      : TextAlign.left,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _AboutBody(
                  _englishCredits,
                  align: TextAlign.left,
                  forceLtr: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                _AboutHeading(appLocale.aboutTitle2),
                _AboutBody(
                  appLocale.aboutPage2,
                  align: appLocale.textDirection == 'rtl'
                      ? TextAlign.right
                      : TextAlign.left,
                ),
                _AboutBody(
                  appLocale.informationCollectionDisclaimer,
                  align: appLocale.textDirection == 'rtl'
                      ? TextAlign.right
                      : TextAlign.left,
                ),
                _AboutVersion(label: appLocale.aboutVersionLabel(version)),
                const _AboutPartnerLogos(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutHeading extends StatelessWidget {
  const _AboutHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: myAutoSizedText(
        text,
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        TextAlign.center,
        60,
      ),
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody(this.text, {required this.align, this.forceLtr = false});
  final String text;
  final TextAlign align;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    final child = myAutoSizedText(
      text,
      const TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
      align,
      35,
    );
    return Container(
      alignment: Alignment.topCenter,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: forceLtr
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: AppSpacing.sm),
      child: forceLtr
          ? Directionality(textDirection: TextDirection.ltr, child: child)
          : child,
    );
  }
}

class _AboutVersion extends StatelessWidget {
  const _AboutVersion({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class _AboutPartnerLogos extends StatelessWidget {
  const _AboutPartnerLogos();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.4;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Image.asset('assets/images/SocialHub-Logo.png', width: width),
        ),
        const SizedBox(width: AppSpacing.xl),
        Flexible(
          child: Image.asset('assets/images/clubhouse-Logo.png', width: width),
        ),
      ],
    );
  }
}
