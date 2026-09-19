import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/util/theme/spacing.dart';

/// Consistent summary card for a custom category.
class CustomCategoryCard extends StatelessWidget {
  const CustomCategoryCard({
    super.key,
    required this.category,
    required this.index,
    this.onEdit,
    this.onDelete,
  });

  /// Title and description rendered by the card.
  final MapEntry<String, String> category;

  /// Stable position used for widget keys and callback routing.
  final int index;

  /// Optional edit action for the category.
  final VoidCallback? onEdit;

  /// Optional asynchronous deletion boundary supplied by the parent.
  final VoidCallback? onDelete;

  TextDirection _directionFor(String value) {
    return getDirectionOfText(value) == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final direction = _directionFor(category.key);
    final alignment = direction == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
    return Card(
      key: ValueKey('custom-category-card-$index'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Directionality(
          textDirection: direction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.key,
                      textAlign: alignment,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      key: Key('custom-category-edit-button-$index'),
                      tooltip: localizations.addFormEdit('other'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                    ),
                  if (onDelete != null)
                    IconButton(
                      key: Key('custom-category-delete-button-$index'),
                      tooltip: localizations.deleteButton('other'),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Directionality(
                textDirection: _directionFor(category.value),
                child: Text(
                  category.value,
                  textAlign: _directionFor(category.value) == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
