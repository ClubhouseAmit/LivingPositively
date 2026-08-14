import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/FormAnswer/addFormAnswer.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

/// Row geometry from the shared Figma onboarding template (`Frame 215`):
/// a fixed index column on the reading-start edge, then the answer text.
const double _indexColumnWidth = 16;
const double _gapIndexToText = 8;

const double _gapTextToEditHint = 8;
const double _editHintSize = 16;

//the template for the answers in the personal plan questionnaire
//this is used in the formpagetemplate to display(remove/edit) the selected/inserted user promptss
class FormAnswer extends StatefulWidget {
  final String text;
  final Function edit;
  final Function remove;
  final int num;

  const FormAnswer({
    super.key,
    required this.text,
    required this.edit,
    required this.remove,
    required this.num,
  });

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
        builder: (BuildContext dialogContext) {
          return AddFormAnswer(
            index: index,
            edit: widget.edit,
            text: text,
            onDelete: () {
              Navigator.of(dialogContext).pop();
              widget.remove(index);
            },
          );
        },
      );
    }

    return Dismissible(
      key: ValueKey('form-answer-${widget.text}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.remove(widget.num - 1),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      //Width is the parent's concern — the row fills whatever it is given.
      child: InkWell(
        onTap: () => editAnswer(widget.text, widget.num - 1),
        //Figma frame 15: the index sits on the reading-start edge and the
        //divider underlines only the text column — it stops short of the
        //index rather than running the full row width.
        child: Row(
          spacing: _gapIndexToText,
          children: [
            SizedBox(
              width: _indexColumnWidth,
              child: Text(
                '${widget.num}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: AppFontWeight.medium,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                //each row group is 30 tall with the divider at its bottom.
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  spacing: _gapTextToEditHint,
                  children: [
                    Expanded(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: _editHintSize,
                      color: Theme.of(context).colorScheme.outline,
                      semanticLabel: appLocale.addFormEdit(gender),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
