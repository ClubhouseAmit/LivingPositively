import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

/// Reusable section widget for home page list sections (e.g., Gratitude and Virtues).
class DashedListWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconAsset;
  final List<String> items;
  final List<String> suggestions;
  final VoidCallback onAddItem;

  const DashedListWidget({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.items,
    required this.suggestions,
    required this.onAddItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final userInfo = Provider.of<UserInformation>(context);

    // Determine starter prompts or next suggestion
    final availableSuggestions =
        suggestions.where((s) => !items.contains(s)).toList();

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    iconAsset,
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                onPressed: onAddItem,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 14,
                ),
          ),
          SizedBox(height: AppSpacing.sm + 4),
          if (items.isEmpty) ...[
            // Empty state: suggest starter prompts (top 3 localized suggestions)
            ...availableSuggestions.take(3).map(
                  (suggestion) => DashedPillAddSlot(
                    placeholder: suggestion,
                    onTap: onAddItem,
                  ),
                ),
          ] else ...[
            // Populated items as pill rows
            ...List.generate(
              items.length,
              (index) => PillItemRow(
                index: index,
                text: items[index],
                onEdit: onAddItem,
              ),
            ),
            // Dashed pill add slot with next suggestion or default
            DashedPillAddSlot(
              placeholder: availableSuggestions.isNotEmpty
                  ? availableSuggestions.first
                  : appLocale.addItemTooltip,
              onTap: onAddItem,
            ),
          ],
          SizedBox(height: AppSpacing.sm + 4),
          // See all link
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onAddItem,
              label: Text(
                appLocale.showAll(userInfo.gender),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              icon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
