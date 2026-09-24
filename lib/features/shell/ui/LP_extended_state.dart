import 'package:flutter/widgets.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// Base state class that provides easy access to localized strings.
abstract class LPExtendedState<T extends StatefulWidget> extends State<T> {
  late AppLocalizations
  appLocale; // The localized strings for the current context

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch the AppLocalizations for the current BuildContext.
    appLocale = AppLocalizations.of(context)!;
  }
}
