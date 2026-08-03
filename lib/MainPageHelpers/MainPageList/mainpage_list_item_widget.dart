import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazilon/util/theme/spacing.dart';

class MainpageListItemWidget extends StatelessWidget {
  const MainpageListItemWidget({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final String item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.xs,
          horizontal: Spacing.sm,
        ),
        child: Row(
          children: [
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // 3-dot popover menu
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.ellipsisVertical,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: Spacing.sm),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Delete',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
