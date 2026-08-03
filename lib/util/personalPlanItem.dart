import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazilon/util/theme/spacing.dart';

//This is to display the showcased Items in the home page under the "Personal Plan" section
class PersonalPlanItem extends StatefulWidget {
  const PersonalPlanItem({required this.text, super.key});
  final String text;

  @override
  State<PersonalPlanItem> createState() => _PersonalPlanItemState();
}

class _PersonalPlanItemState extends State<PersonalPlanItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.sm),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          leading: Icon(
            LucideIcons.checkCircle,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: AutoSizeText(
            widget.text,
            maxLines: 4,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
