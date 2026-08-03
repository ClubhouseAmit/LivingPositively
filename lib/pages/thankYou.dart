import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// the thank you widget, it shows the thank you text and the number of the thank you
//although its name is thank you, it can be used for any trait , we used it for the positive trait also.
class ThankYou extends StatefulWidget { // the color of the thank you/trait text
  const ThankYou({
    required this.text, required this.number, required this.edit, required this.remove, required this.myFocusNode, required this.date, required this.color, super.key,
  });
  final String text; // the text of the thank you/trait
  final int number; // the number of the thank you/trait
  final Function edit; // the function to edit the thank you/trait
  final Function remove; // the function to remove the thank you/trait
  final FocusNode myFocusNode; // the focus node of the thank you/trait
  final String date; // the date of the thank you/trait
  final Color color;
  @override
  State<ThankYou> createState() => _ThankYouState();
}

class _ThankYouState extends State<ThankYou> {
  bool editable = false;

  Future<void> _confirmDelete(
    AppLocalizations? locale,
    String gender,
    int removeIndex,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale?.confirmDeleteEntryTitle ?? 'Delete this entry?'),
        content: Text(
          locale?.confirmDeleteEntryMessage ?? 'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(locale?.closeButton(gender) ?? 'Close'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(locale?.deleteButton(gender) ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    widget.remove(removeIndex);
    setState(() {
      editable = false;
    });
  }

  @override
  void initState() {
    editable = widget.text.isEmpty;
    if (editable) {
      widget.myFocusNode.requestFocus();
    }
    super.initState();
  }

  // build the thank you widget
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final gender = Provider.of<UserInformation>(context, listen: false).gender;
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key('thankYou_${widget.number}_${widget.text.hashCode}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(locale?.confirmDeleteEntryTitle ?? 'Delete this entry?'),
            content: Text(
              locale?.confirmDeleteEntryMessage ?? 'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(locale?.closeButton(gender) ?? 'Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(locale?.deleteButton(gender) ?? 'Delete'),
              ),
            ],
          ),
        );
        return confirmed == true;
      },
      onDismissed: (direction) {
        widget.remove(widget.number - 1);
      },
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs, horizontal: Spacing.sm),
        child: Row(
          children: [
            Text(
              widget.number.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            // gap between the text and the number
            const SizedBox(width: 10),

            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 20,
                ),
              // height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(95),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const SizedBox(width: 15),

                    // the text of the thank you/trait
                    Expanded(
                      child: AutoSizeText(
                        widget.text,
                        maxLines: 1,
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: widget.color,
                            ),
                      ),
                    ),

                    // 3-dot popover menu replacing separate edit/delete buttons
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
                        if (value == 'edit') {
                          widget.edit(widget.text, widget.number - 1);
                        } else if (value == 'delete') {
                          _confirmDelete(locale, gender, widget.number - 1);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.pencil, size: 16, color: colorScheme.primary),
                              const SizedBox(width: Spacing.sm),
                              Text(locale?.editEntryTooltip ?? 'Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, size: 16, color: colorScheme.error),
                              const SizedBox(width: Spacing.sm),
                              Text(
                                locale?.deleteEntryTooltip ?? 'Delete',
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
            ),
            ),
          ],
        ),
      ),
    );
  }
}
