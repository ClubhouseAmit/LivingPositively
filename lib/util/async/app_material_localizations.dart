import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

/// Keeps Hebrew translations while allowing the platform to select 12-hour time.
class AppMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const AppMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'he';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate
          .load(locale)
          .then<MaterialLocalizations>(
            (_) => _HebrewAppLocalizations(),
          );

  @override
  bool shouldReload(AppMaterialLocalizationsDelegate old) => false;
}

class _HebrewAppLocalizations extends MaterialLocalizationHe {
  _HebrewAppLocalizations()
    : super(
        fullYearFormat: DateFormat.y('he'),
        compactDateFormat: DateFormat.yMd('he'),
        shortDateFormat: DateFormat.yMMMd('he'),
        mediumDateFormat: DateFormat.MMMEd('he'),
        longDateFormat: DateFormat.yMMMMEEEEd('he'),
        yearMonthFormat: DateFormat.yMMMM('he'),
        shortMonthDayFormat: DateFormat.MMMd('he'),
        decimalFormat: NumberFormat.decimalPattern('he'),
        twoDigitZeroPaddedFormat: NumberFormat('00', 'he'),
      );

  // The inherited formatter converts this to 24-hour when MediaQuery requests it.
  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a;
}
