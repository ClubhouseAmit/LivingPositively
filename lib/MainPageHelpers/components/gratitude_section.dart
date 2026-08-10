import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/MainPageHelpers/components/dashed_list_widget.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class GratitudeSectionWidget extends StatelessWidget {
  final List<String> items;
  final VoidCallback onAddItem;

  const GratitudeSectionWidget({
    required this.items,
    required this.onAddItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final userInfo = Provider.of<UserInformation>(context);
    final gender = userInfo.gender.isEmpty ? 'other' : userInfo.gender;

    return DashedListWidget(
      title: appLocale.gratitudeListTitle,
      subtitle: appLocale.gratitudeSubTitle,
      iconAsset: 'assets/images/thanks_icon.svg',
      items: items,
      suggestions: retrieveThanksList(appLocale, gender),
      onAddItem: onAddItem,
    );
  }
}
