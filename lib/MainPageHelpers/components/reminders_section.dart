import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/spacing.dart';

class ReminderItemData {
  final String? emoji;
  final String? iconAsset;
  final String title;
  final String? subtitle;

  ReminderItemData({
    this.emoji,
    this.iconAsset,
    required this.title,
    this.subtitle,
  });
}

class RemindersSectionWidget extends StatelessWidget {
  final List<ReminderItemData> reminders;
  final VoidCallback onSeeAll;

  const RemindersSectionWidget({
    required this.reminders,
    required this.onSeeAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: appLocale.reminders,
          leadingIcon: Icons.notifications_none,
          actionIcon: Icons.add,
          onActionTap: onSeeAll,
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: reminders
                .map((reminder) => Padding(
                      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                      child: CardContainer(
                        padding: EdgeInsets.zero,
                        borderRadius: 20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              if (reminder.iconAsset != null)
                                SizedBox(
                                  width: 68,
                                  height: 65,
                                  child: SvgPicture.asset(
                                    reminder.iconAsset!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 52,
                                  height: 52,
                                  margin: const EdgeInsetsDirectional.only(start: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE566),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      reminder.emoji ?? '',
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder.title,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      if (reminder.subtitle != null) ...[
                                        SizedBox(height: AppSpacing.xs),
                                        Text(
                                          reminder.subtitle!,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.outline,
                                              ),
                                          textAlign: TextAlign.start,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 16.0),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
