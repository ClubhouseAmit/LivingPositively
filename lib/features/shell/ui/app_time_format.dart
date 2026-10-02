import 'package:flutter/widgets.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/async/app_material_localizations.dart';
import 'package:mazilon/util/async/browser_time_format.dart';

/// Localization delegates shared by the app and its widget-test scaffold.
const appLocalizationsDelegates = [
  AppMaterialLocalizationsDelegate(),
  ...AppLocalizations.localizationsDelegates,
];

/// Applies browser time preferences above the navigator and all its dialogs.
Widget appTimeFormatBuilder(BuildContext context, Widget? child) =>
    AppTimeFormat(child: child ?? const SizedBox.shrink());

/// Uses the browser's hour cycle while native apps retain their OS preference.
class AppTimeFormat extends StatelessWidget {
  const AppTimeFormat({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final browserPreference = browserUses24HourFormat();
    if (browserPreference == null) return child;
    return MediaQuery(
      data: mediaQuery.copyWith(alwaysUse24HourFormat: browserPreference),
      child: child,
    );
  }
}
