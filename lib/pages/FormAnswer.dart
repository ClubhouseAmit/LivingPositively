import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/FormAnswer/addFormAnswer.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//the template for the answers in the personal plan questionnaire
//this is used in the formpagetemplate to display(remove/edit) the selected/inserted user promptss
class FormAnswer extends StatefulWidget {

  const FormAnswer({
    required this.text, required this.edit, required this.remove, required this.num, super.key,
  });
  final String text;
  final Function edit;
  final Function remove;
  final int num;

  @override
  State<FormAnswer> createState() => _FormAnswerState();
}

class _FormAnswerState extends LPExtendedState<FormAnswer> {
  String tempMyAnswer = '';

  @override
  Widget build(BuildContext context) {
    final gender = Provider.of<UserInformation>(context, listen: false).gender;

    void editAnswer(String text, int index) {
      showDialog(
        context: context,
        builder: (context) {
          return AddFormAnswer(index: index, edit: widget.edit, text: text);
        },
      );
    }

    Future<void> confirmRemoveAnswer() async {
      final removeIndex = widget.num - 1;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(appLocale.confirmDeletePlanAnswerTitle),
          content: Text(appLocale.confirmDeletePlanAnswerMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(appLocale.closeButton(gender)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(appLocale.deleteButton(gender)),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
      if (!mounted) {
        return;
      }
      widget.remove(removeIndex);
      setState(() {});
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: ColoredBox(
        color: Colors.transparent,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Icon(
                            Icons.circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AutoSizeText(
                              widget.text,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Align(
                        child: TextButton(
                          onPressed: () {
                            editAnswer(widget.text, widget.num - 1);
                          },
                          child: Tooltip(
                            message: appLocale.editEntryTooltip,
                            child: Icon(
                              Icons.edit,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    SizedBox(
                      width: 30,
                      child: Center(
                        child: TextButton(
                          onPressed: confirmRemoveAnswer,
                          child: Tooltip(
                            message: appLocale.deleteEntryTooltip,
                            child: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
