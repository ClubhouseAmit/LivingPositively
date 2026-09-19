import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/features/speech_dictation/ui/suffix_action.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/userInformation.dart'; //
import 'package:provider/provider.dart'; //
import 'package:mazilon/design_system/tokens/spacing.dart';

//

// the add form widget, it shows a form to add or edit an item to the list
class AddForm extends StatefulWidget {
  final Function add; // the function to add item to the list
  final int index; // the index of the item in the list
  final Function edit; // the function to edit the item in the list
  final String text; // the text of the item
  final String formTitle; // the title of the form
  const AddForm({
    super.key,
    required this.add,
    required this.index,
    required this.edit,
    required this.text,
    required this.formTitle,
  });
  @override
  State<AddForm> createState() => _AddFormState();
}

class _AddFormState extends LPExtendedState<AddForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  Future<void> _onSubmitForm(UserInformation userInfoProvider) async {
    if (_formKey.currentState!.validate()) {
      try {
        final result = widget.text != ''
            ? widget.edit(_controller.text, widget.index, userInfoProvider)
            : widget.add(_controller.text, userInfoProvider);
        if (result is Future) {
          await result;
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (error, stackTrace) {
        debugPrint('Unable to save add-form item: $error\n$stackTrace');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.text;
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Widget _form(UserInformation userInfo) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TextFormField(
            onFieldSubmitted: (_) => unawaited(_onSubmitForm(userInfo)),
            maxLength: 100,
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.formTitle,
              suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
                  ? SpeechDictationSuffixAction(
                      controller: _controller,
                      maxLength: 100,
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return appLocale.validateEmpty;
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _actionLabel(String label) {
    return myAutoSizedText(
      label,
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
      null,
      30,
    );
  }

  Widget _actions(UserInformation userInfo, String gender) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: _actionLabel(appLocale.closeButton(gender)),
        ),
        TextButton(
          onPressed: () => unawaited(_onSubmitForm(userInfo)),
          child: _actionLabel(appLocale.saveButton(gender)),
        ),
      ],
    );
  }

  // build the add form widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation and userInformation providers

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    ); //
    final gender = userInfoProvider.gender;

    return Dialog(
      child: SizedBox(
        // set the width of the dialog to 800 if the screen width is more than 1000, else set it to the screen width
        width: MediaQuery.of(context).size.width > 1000
            ? 800
            : MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          // Wrap Column with SingleChildScrollView
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              // text on the top of the form
              myAutoSizedText(
                appLocale.newTraitOrThanks(widget.formTitle),
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp, // text size
                ),
                null,
                40,
              ),
              _form(userInfoProvider),
              _actions(userInfoProvider, gender),
            ],
          ),
        ),
      ),
    );
  }
}
