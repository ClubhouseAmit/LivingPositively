import 'package:flutter/material.dart';

import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';

Map<String, dynamic> getLocalizedTextForLists(locale, gender, type) {
  try {
    switch (type) {
      case PagesCode.GratitudeJournal:
        return {
          'mainTitle': locale!.homePageThanksMainTitle(gender),
          'secondaryTitle': locale!.homePageThanksSecondaryTitle(gender),
          "icon": FontAwesome5.praying_hands,
        };

      case PagesCode.QualitiesList:
        return {
          'mainTitle': locale!.homePageTraitsMainTitle(gender),
          'secondaryTitle': locale!.homePageTraitsSecondaryTitle(gender),
          "icon": Icons.diamond,
        };
      default:
        throw Exception(
          "Invalid type for getLocalizedTextForLists: $type. Expected GratitudeJournal or QualitiesList.",
        );
    }
  } catch (error, stackTrace) {
    IncidentLoggerService loggerService =
        GetIt.instance<IncidentLoggerService>();
    loggerService.captureLog(error, stackTrace: stackTrace);

    return {'mainTitle': '', 'secondaryTitle': '', "icon": Icons.diamond};
  }
}

List<String> todayThankYousFunc(List<String> thankYous, List<String> dates) {
  List<String> todayThankYous = [];
  DateTime now = DateTime.now();
  String formattedDate = intl.DateFormat('yyyy-MM-dd – kk:mm').format(now);

  for (int i = 0; i < dates.length; i++) {
    if (dates[i].substring(0, 10) == formattedDate.substring(0, 10)) {
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
  stateFunction,
  popupFunction,
) {
  List<String> thankyousTemp = userInfoProvider.thanks['thanks'] ?? [];
  List<String> datesTemp = userInfoProvider.thanks['dates'] ?? [];

  thankyousTemp.add(thankYou);

  DateTime now = DateTime.now();
  String formattedDate = intl.DateFormat('yyyy-MM-dd – kk:mm').format(now);
  datesTemp.add(formattedDate);
  stateFunction(thankyousTemp, datesTemp, userInfoProvider);

  if (todayThankYousFunc(
        userInfoProvider.thanks["thanks"] ?? [],
        userInfoProvider.thanks["dates"] ?? [],
      ).length ==
      1) {
    popupFunction(userInfoProvider);
  }
  AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
  mixPanelService.trackEvent("Item added to Gratitude Journal");
}

void addPositiveTrait(
  String positiveTrait,
  UserInformation userInfoProvider,
  stateFunction,
) {
  List<String> positivetraitsTemp = userInfoProvider.positiveTraits;
  positivetraitsTemp.add(positiveTrait);
  stateFunction(positivetraitsTemp, userInfoProvider);

  AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
  mixPanelService.trackEvent("Item added to Qualities List");
}

void editPositiveTrait(
  String text,
  int index,
  UserInformation userInfoProvider,
  stateFunction,
) {
  List<String> positiveTraits = userInfoProvider.positiveTraits;
  positiveTraits[index] = text;
  stateFunction(positiveTraits, userInfoProvider);
}

void editThankYou(
  String text,
  int index,
  UserInformation userinfoProvider,
  stateFunction,
) {
  var thankyousTemp = userinfoProvider.thanks['thanks'] ?? [];
  thankyousTemp[index] = text;
  var thankYouDates = userinfoProvider.thanks['dates'] ?? [];
  stateFunction(thankyousTemp, thankYouDates, userinfoProvider);
}

void removeThankYou(
  int removeIndex,
  UserInformation userInfoProvider,
  stateFunction,
) {
  List<String> thankyousTemp = userInfoProvider.thanks['thanks'] ?? [];
  List<String> datesTemp = userInfoProvider.thanks['dates'] ?? [];

  thankyousTemp.removeAt(removeIndex);
  datesTemp.removeAt(removeIndex);
  stateFunction(thankyousTemp, datesTemp, userInfoProvider);
}

void removePositiveTrait(
  int removeIndex,
  UserInformation userInfoProvider,
  stateFunction,
) {
  List<String> positivetraitsTemp = userInfoProvider.positiveTraits;
  positivetraitsTemp.removeAt(removeIndex);
  stateFunction(positivetraitsTemp, userInfoProvider);
}
