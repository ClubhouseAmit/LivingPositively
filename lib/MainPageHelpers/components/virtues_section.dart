import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/MainPageHelpers/components/dashed_list_widget.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class VirtuesSectionWidget extends StatelessWidget {
  final List<String> virtues;
  final VoidCallback onAddItem;

  const VirtuesSectionWidget({
    required this.virtues,
    required this.onAddItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final userInfo = Provider.of<UserInformation>(context);
    final gender = userInfo.gender.isEmpty ? 'other' : userInfo.gender;

    return DashedListWidget(
      title: appLocale.traitsListTitle,
      subtitle: appLocale.traitsSubTitle,
      iconAsset: 'assets/images/diamond_icon.svg',
      items: virtues,
      suggestions: retrieveTraitsList(appLocale, gender),
      onAddItem: onAddItem,
    );
  }
}
