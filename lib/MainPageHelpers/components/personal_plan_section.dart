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
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          _buildItemsList(context)
        else
          _buildEmptyState(context, appLocale, userInfo.gender),
        _buildSeeAllButton(context, appLocale, userInfo.gender),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: CardContainer(
              hasShadow: false,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 14,
              ),
              child: Text(
                items[index],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations appLocale,
    String gender,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        height: 45,
        child: CardContainer(
          hasShadow: false,
          onTap: onSeeAll,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  appLocale.personalPlanPageHasFilled(gender),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeeAllButton(
    BuildContext context,
    AppLocalizations appLocale,
    String gender,
  ) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          end: AppSpacing.md,
          top: AppSpacing.lg,
        ),
        child: TextButton.icon(
          onPressed: onSeeAll,
          label: Text(
            appLocale.personalPlanPageAllPlan(gender),
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
    );
  }
}
