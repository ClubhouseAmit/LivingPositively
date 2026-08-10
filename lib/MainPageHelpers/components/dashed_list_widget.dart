import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

/// Reusable section widget for home page list sections (e.g., Gratitude and Virtues).
class DashedListWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String iconAsset;
  final List<String> items;
  final List<String> suggestions;
  final VoidCallback onAddItem;
  final VoidCallback? onAddNew;
  final void Function(int index)? onEditItem;
  final void Function(int index)? onRemoveItem;
  final void Function(String suggestion)? onAddSuggestion;

  const DashedListWidget({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.items,
    required this.suggestions,
    required this.onAddItem,
    this.onAddNew,
    this.onEditItem,
    this.onRemoveItem,
    this.onAddSuggestion,
    super.key,
  });

  @override
  State<DashedListWidget> createState() => _DashedListWidgetState();
}

class _DashedListWidgetState extends State<DashedListWidget> {
  int _suggestionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final userInfo = Provider.of<UserInformation>(context);

    final availableSuggestions =
        widget.suggestions.where((s) => !widget.items.contains(s)).toList();

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
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
                    widget.iconAsset,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.title,
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
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 22,
                ),
                onPressed: widget.onAddNew ?? widget.onAddItem,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 14,
                ),
          ),
          SizedBox(height: AppSpacing.sm + 4),
          if (widget.items.isEmpty) ...[
            // Empty state: up to 3 suggestions, cycling from _suggestionIndex
            ...List.generate(
              min(3, availableSuggestions.length),
              (i) {
                final suggestion = availableSuggestions.isEmpty
                    ? ''
                    : availableSuggestions[
                        (_suggestionIndex + i) % availableSuggestions.length];
                return DashedPillAddSlot(
                  placeholder: suggestion,
                  onTap: widget.onAddSuggestion != null
                      ? () => widget.onAddSuggestion!(suggestion)
                      : widget.onAddNew ?? widget.onAddItem,
                  onRefresh: availableSuggestions.length > 3
                      ? () => setState(() => _suggestionIndex++)
                      : null,
                );
              },
            ),
          ] else ...[
            // Populated items as pill rows
            ...List.generate(
              widget.items.length,
              (index) => PillItemRow(
                index: index,
                text: widget.items[index],
                onEdit: widget.onEditItem != null
                    ? () => widget.onEditItem!(index)
                    : widget.onAddNew ?? widget.onAddItem,
                onRemove: widget.onRemoveItem != null
                    ? () => widget.onRemoveItem!(index)
                    : null,
              ),
            ),
            // Suggestion slot with cycling
            if (availableSuggestions.isNotEmpty) ...[
              Builder(builder: (context) {
                final suggestion = availableSuggestions[
                    _suggestionIndex % availableSuggestions.length];
                return DashedPillAddSlot(
                  placeholder: suggestion,
                  onTap: widget.onAddSuggestion != null
                      ? () => widget.onAddSuggestion!(suggestion)
                      : widget.onAddNew ?? widget.onAddItem,
                  onRefresh: availableSuggestions.length > 1
                      ? () => setState(() => _suggestionIndex++)
                      : null,
                );
              }),
            ] else ...[
              DashedPillAddSlot(
                placeholder: appLocale.addItemTooltip,
                onTap: widget.onAddNew ?? widget.onAddItem,
              ),
            ],
          ],
          SizedBox(height: AppSpacing.sm + 4),
          // See all link
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: widget.onAddItem,
              label: Text(
                appLocale.showAll(userInfo.gender),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.primary),
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
