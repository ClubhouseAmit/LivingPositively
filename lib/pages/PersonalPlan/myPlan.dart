import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/languages_util_functions.dart';

/// A collapsible plan section shared by My Plan and the final Share summary.
/// Optional controls let a summary route edits or deletions back to the
/// owning flow without coupling the presentation to storage.
class MyPlanSection extends StatefulWidget {
  final String title;
  final String subTitle;
  final List<String> answers;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool initiallyExpanded;

  const MyPlanSection({
    super.key,
    required this.title,
    required this.subTitle,
    required this.answers,
    this.onEdit,
    this.onDelete,
    this.initiallyExpanded = true,
  });

  @override
  State<MyPlanSection> createState() => _MyPlanSectionState();
}

class _MyPlanSectionState extends LPExtendedState<MyPlanSection> {
  TextDirection _directionFor(String value) {
    return getDirectionOfText(value) == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    return Card(
      key: ValueKey('plan-section-${widget.title}'),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        title: Directionality(
          textDirection: _directionFor(widget.title),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ),
        subtitle: widget.subTitle.isEmpty
            ? null
            : Directionality(
                textDirection: _directionFor(widget.subTitle),
                child: Text(widget.subTitle, textAlign: TextAlign.center),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onEdit != null)
              IconButton(
                key: ValueKey('plan-section-edit-${widget.title}'),
                tooltip: localizations.addFormEdit('other'),
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit),
              ),
            if (widget.onDelete != null)
              IconButton(
                key: ValueKey('plan-section-delete-${widget.title}'),
                tooltip: localizations.deleteButton('other'),
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          for (final answer in widget.answers)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.circle, color: colors.primary, size: 8),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Directionality(
                      textDirection: _directionFor(answer),
                      child: Text(
                        answer,
                        textAlign: _directionFor(answer) == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
