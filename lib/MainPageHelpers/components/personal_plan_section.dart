import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class PersonalPlanSectionWidget extends StatelessWidget {
  final List<String> items;
  final VoidCallback onSeeAll;

  const PersonalPlanSectionWidget({
    required this.items,
    required this.onSeeAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final userInfo = Provider.of<UserInformation>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: appLocale.myPlan,
          leadingIcon: Icons.assignment_outlined,
          subtitle: appLocale.myPlanSubTitle,
        ),
        if (items.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.lg,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: CardContainer(
                    hasShadow: false,
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      items[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: const Color(0xFF1A1A1A),
                          ),
                      textAlign: TextAlign.start,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: AppSpacing.md, top: AppSpacing.xs),
            child: TextButton.icon(
              onPressed: onSeeAll,
              label: Text(
                appLocale.personalPlanPageAllPlan(userInfo.gender),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              icon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
