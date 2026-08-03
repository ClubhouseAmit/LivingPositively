import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/async/async_state_view.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// Introduction widget serves as an initial loading screen or introduction page.
class Introduction extends StatefulWidget { // Optional child widget that can be passed to this screen
  const Introduction({super.key, this.child});
  final Widget?
  child;

  @override
  State<Introduction> createState() => _IntroductionState();
}

class _IntroductionState extends LPExtendedState<Introduction> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Displaying a welcome message in Hebrew with custom styling
            Semantics(
              header: true,
              child: AutoSizeText(
                appLocale.introductionRestartGreeting(
                  userInfoProvider.gender,
                ), // Welcome message in Hebrew
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            // Displaying a large circular progress indicator (spinner).
            // Phase E (ADR-005 §Decision step 5): the spinner carried no
            // screen-reader label (UX_GAPS.md §1.5). Announce it via the
            // shared async loading indicator so TalkBack/VoiceOver users know
            // the restart is in progress.
            SizedBox(
              height: 300,
              width: 300,
              child: AsyncLoadingIndicator(
                semanticLabel: appLocale.asyncLoadingLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
