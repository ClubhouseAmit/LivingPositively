import 'package:flutter/material.dart';
import 'package:mazilon/features/speech_dictation/ui/suffix_action.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

class AddFormAnswer extends StatefulWidget {
  final int index; // The index of the item being edited
  final Function edit; // The callback function to handle the edit action
  final String text; // The current text of the item being edited

  final VoidCallback? onDelete;

  // Constructor for AddFormAnswer, initializing index, edit function, and text.
  const AddFormAnswer({
    super.key,
    required this.index,
    required this.edit,
    required this.text,
    this.onDelete,
  });

  @override
  State<AddFormAnswer> createState() => _AddFormAnswerState();
}

class _AddFormAnswerState extends LPExtendedState<AddFormAnswer> {
  final _formKey = GlobalKey<FormState>(); // Global key for the form state
  final TextEditingController _controller =
      TextEditingController(); // Controller for the text input

  @override
  void initState() {
    super.initState();
    _controller.text = widget.text; // Set initial text in the controller
  }

  Widget _formField(String gender) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TextFormField(
            maxLines: null,
            controller: _controller,
            autofocus: true,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: appLocale.addFormEdit(gender),
              suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
                  ? SpeechDictationSuffixAction(
                      controller: _controller,
                      maxLength: 100,
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return appLocale.validateEmpty;
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _actionLabel(String label, [Color? color]) {
    return myAutoSizedText(
      label,
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp, color: color),
      null,
      30,
    );
  }

  Widget _actions(String gender) {
    return Row(
      children: <Widget>[
        if (widget.onDelete != null)
          TextButton(
            onPressed: widget.onDelete,
            child: _actionLabel(
              appLocale.deleteButton(gender),
              Theme.of(context).colorScheme.error,
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: _actionLabel(appLocale.closeButton(gender)),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.edit(widget.index, _controller.text);
              Navigator.of(context).pop();
            }
          },
          child: _actionLabel(appLocale.saveButton(gender)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    ); // Access the UserInformation provider
    final gender = userInfoProvider.gender;
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 1000
            ? 800
            : MediaQuery.of(
                context,
              ).size.width, // Adjust width based on screen size
        height: MediaQuery.of(context).size.width > 400
            ? MediaQuery.of(context).size.height * 25 / 100
            : MediaQuery.of(context).size.height *
                  30 /
                  100, // Adjust height based on screen size
        child: Column(
          children: [
            SizedBox(height: AppSpacing.xl.h),
            Expanded(
              child: _formField(gender),
            ),
            _actions(gender),
          ],
        ),
      ),
    );
  }
}
