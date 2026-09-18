import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/theme/spacing.dart';

// the thank you widget, it shows the thank you text and the number of the thank you
//although its name is thank you, it can be used for any trait , we used it for the positive trait also.
class ThankYou extends StatefulWidget {
  final String text; // the text of the thank you/trait
  final int number; // the number of the thank you/trait
  final Function edit; // the function to edit the thank you/trait
  final Function remove; // the function to remove the thank you/trait
  final String date; // the date of the thank you/trait
  final Color color; // the color of the thank you/trait text
  const ThankYou({
    super.key,
    required this.text,
    required this.number,
    required this.edit,
    required this.remove,
    required this.date,
    required this.color,
  });
  @override
  State<ThankYou> createState() => _ThankYouState();
}

class _ThankYouState extends State<ThankYou> {
  bool editable = false;
  final _focusNode = FocusNode();

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
      _focusNode.requestFocus();
    }
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _numberBadge(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: ColoredBox(
        color: colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: myAutoSizedText(
            widget.number.toString(),
            TextStyle(
              color: colorScheme.onPrimary,
              fontSize: widget.number < 10 ? 14.sp : 10.sp,
              fontWeight: FontWeight.bold,
            ),
            null,
            30,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 50,
      child: Tooltip(
        message: tooltip,
        child: MaterialButton(
          onPressed: onPressed,
          splashColor: Colors.transparent,
          enableFeedback: false,
          child: Icon(icon),
        ),
      ),
    );
  }

  Widget _entryBody(
    AppLocalizations? locale,
    String gender,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(
          minHeight: 20,
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.dashedAddSlot),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AutoSizeText(
                widget.text,
                maxLines: 4,
                minFontSize: 14,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.normal,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            _actionButton(
              tooltip: locale?.editEntryTooltip ?? 'Edit entry',
              icon: Icons.edit,
              onPressed: () => widget.edit(widget.text, widget.number - 1),
            ),
            _actionButton(
              tooltip: locale?.deleteEntryTooltip ?? 'Delete entry',
              icon: Icons.delete,
              onPressed: () {
                _confirmDelete(locale, gender, widget.number - 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  // build the thank you widget
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final gender = Provider.of<UserInformation>(context, listen: false).gender;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _numberBadge(colorScheme),
          // gap between the text and the number
          const SizedBox(width: AppSpacing.md),
          _entryBody(locale, gender, colorScheme),
        ],
      ),
    );
  }
}
