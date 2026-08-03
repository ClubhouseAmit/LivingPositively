import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class AddFormAnswer extends StatefulWidget { // The current text of the item being edited

  // Constructor for AddFormAnswer, initializing index, edit function, and text.
  const AddFormAnswer({
    required this.index, required this.edit, required this.text, super.key,
  });
  final int index; // The index of the item being edited
  final Function edit; // The callback function to handle the edit action
  final String text;

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

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    ); // Access the UserInformation provider
    final gender = userInfoProvider.gender;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Spacing.md),
              Form(
                key: _formKey, // Associate the form with the key
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextFormField(
                      maxLines: null, // Allow multiple lines in the text field
                      controller:
                          _controller, // Associate the controller with the text field
                      autofocus:
                          true, // Automatically focus on the text field when the dialog is opened
                      maxLength: 100, // Set maximum length of text
                      decoration: InputDecoration(
                        labelText: appLocale.addFormEdit(
                          gender,
                        ), // Set label text dynamically based on user gender
                        contentPadding: const EdgeInsetsDirectional.only(
                          end: 8.0,
                        ),
                        labelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(height: 0),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocale
                              .validateEmpty; // Validate that the field is not empty
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Align buttons to the end
              children: <Widget>[
                TextButton(
                  child: AutoSizeText(
                    appLocale.closeButton(
                      gender,
                    ), // Set cancel button text dynamically based on user gender
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog on cancel
                  },
                ),
                TextButton(
                  child: AutoSizeText(
                    appLocale.saveButton(
                      gender,
                    ), // Set save button text dynamically based on user gender
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.edit(
                        widget.index,
                        _controller
                            .text, // Call the edit function with the new text
                      );
                      Navigator.of(
                        context,
                      ).pop(); // Close the dialog after saving
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
