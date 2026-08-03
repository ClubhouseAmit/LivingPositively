import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';

Map<String, dynamic> getLocalizedTextForLists(
  AppLocalizations? locale,
  String gender,
  PagesCode type,
) {
  try {
    switch (type) {
      case PagesCode.GratitudeJournal:
        return {
          'mainTitle': locale!.homePageThanksMainTitle(gender),
          'secondaryTitle': locale!.homePageThanksSecondaryTitle(gender),
          'icon': LucideIcons.heart,
        };

      case PagesCode.QualitiesList:
        return {
          'mainTitle': locale!.homePageTraitsMainTitle(gender),
          'secondaryTitle': locale!.homePageTraitsSecondaryTitle(gender),
          'icon': LucideIcons.gem,
        };
      default:
        throw Exception(
          'Invalid type for getLocalizedTextForLists: $type. Expected GratitudeJournal or QualitiesList.',
        );
    }
  } catch (error, stackTrace) {
    final loggerService =
        GetIt.instance<IncidentLoggerService>();
    loggerService.captureLog(error, stackTrace: stackTrace);

    return {'mainTitle': '', 'secondaryTitle': '', 'icon': Icons.diamond};
  }
}

List<String> todayThankYousFunc(List<String> thankYous, List<String> dates) {
  final todayThankYous = <String>[];
  final todayDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
  final itemCount = thankYous.length < dates.length
      ? thankYous.length
      : dates.length;

  for (var i = 0; i < itemCount; i++) {
    if (dates[i].startsWith(todayDate)) {
      todayThankYous.add(thankYous[i]);
    }
  }
  return todayThankYous;
}

List<String> getListItems(
  PagesCode pageCode,
  UserInformation userInfoProvider,
  List<String> todayThankYous,
) {
  if (pageCode == PagesCode.GratitudeJournal) {
    return todayThankYous;
  } else {
    return userInfoProvider.positiveTraits;
  }
}

void addThankYou(
  String thankYou,
  UserInformation userInfoProvider,
  void Function(List<String>, List<String>, UserInformation) stateFunction,
  void Function(UserInformation) popupFunction,
) {
  final thankyousTemp = List<String>.from(userInfoProvider.thanks['thanks'] ?? <String>[]);
  final datesTemp = List<String>.from(userInfoProvider.thanks['dates'] ?? <String>[]);

  thankyousTemp.add(thankYou);

  final now = DateTime.now();
  final formattedDate = intl.DateFormat('yyyy-MM-dd – kk:mm').format(now);
  datesTemp.add(formattedDate);
  stateFunction(thankyousTemp, datesTemp, userInfoProvider);

  if (todayThankYousFunc(
        List<String>.from(userInfoProvider.thanks['thanks'] ?? <String>[]),
        List<String>.from(userInfoProvider.thanks['dates'] ?? <String>[]),
      ).length ==
      1) {
    popupFunction(userInfoProvider);
  }
  final mixPanelService = GetIt.instance<AnalyticsService>();
  mixPanelService.trackEvent('Item added to Gratitude Journal');
}

void addPositiveTrait(
  String positiveTrait,
  UserInformation userInfoProvider,
  void Function(List<String>, UserInformation) stateFunction,
) {
  final positivetraitsTemp = List<String>.from(userInfoProvider.positiveTraits);
  positivetraitsTemp.add(positiveTrait);
  stateFunction(positivetraitsTemp, userInfoProvider);

  final mixPanelService = GetIt.instance<AnalyticsService>();
  mixPanelService.trackEvent('Item added to Qualities List');
}

void editPositiveTrait(
  String text,
  int index,
  UserInformation userInfoProvider,
  void Function(List<String>, UserInformation) stateFunction,
) {
  final positiveTraits = List<String>.from(userInfoProvider.positiveTraits);
  positiveTraits[index] = text;
  stateFunction(positiveTraits, userInfoProvider);
}

void editThankYou(
  String text,
  int index,
  UserInformation userinfoProvider,
  void Function(List<String>, List<String>, UserInformation) stateFunction,
) {
  final thankyousTemp = List<String>.from(userinfoProvider.thanks['thanks'] ?? <String>[]);
  thankyousTemp[index] = text;
  final thankYouDates = List<String>.from(userinfoProvider.thanks['dates'] ?? <String>[]);
  stateFunction(thankyousTemp, thankYouDates, userinfoProvider);
}

void removeThankYou(
  int removeIndex,
  UserInformation userInfoProvider,
  void Function(List<String>, List<String>, UserInformation) stateFunction,
) {
  final thankyousTemp = List<String>.from(userInfoProvider.thanks['thanks'] ?? <String>[]);
  final datesTemp = List<String>.from(userInfoProvider.thanks['dates'] ?? <String>[]);

  thankyousTemp.removeAt(removeIndex);
  datesTemp.removeAt(removeIndex);
  stateFunction(thankyousTemp, datesTemp, userInfoProvider);
}

void removePositiveTrait(
  int removeIndex,
  UserInformation userInfoProvider,
  void Function(List<String>, UserInformation) stateFunction,
) {
  final positivetraitsTemp = List<String>.from(userInfoProvider.positiveTraits);
  positivetraitsTemp.removeAt(removeIndex);
  stateFunction(positivetraitsTemp, userInfoProvider);
}
