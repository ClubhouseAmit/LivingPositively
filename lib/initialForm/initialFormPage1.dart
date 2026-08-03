
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//The first page of the initial form
//all text is in the CMS and is fetched from there
class InitialFormPage1 extends StatefulWidget {

  const InitialFormPage1({
    required this.next, required this.skip, required this.prev, required this.updateName, super.key,
  });
  final Function next;
  final Function skip;
  final Function prev;
  final Function updateName;
  @override
  State<InitialFormPage1> createState() => _InitialFormPage1State();
}

class _InitialFormPage1State extends LPExtendedState<InitialFormPage1> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );
    final gender = userInfoProvider.gender;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
              Semantics(
                header: true,
                child: AutoSizeText(
                  appLocale.introductionFormFirstPageMainTitle(gender),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: AutoSizeText(
                  appLocale.introductionFormFirstPageSubTitle1(gender),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
                child: AutoSizeText(
                  appLocale.introductionFormFirstPageSubTitle2(gender),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
                child: Image.asset(
                  'assets/images/initialFormPage1.png',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.next();
                },
                child: Text(appLocale.nextButton(gender)),
              ),
              const SizedBox(height: Spacing.md),
              OutlinedButton(
                onPressed: () {
                  widget.skip();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(appLocale.skipButton(gender)),
              ),
            ],
          ),
        );
  }
}
