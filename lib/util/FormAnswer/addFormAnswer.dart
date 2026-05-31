import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class AddFormAnswer extends StatefulWidget {
  final int index; // The index of the item being edited
  final Function edit; // The callback function to handle the edit action
  final String text; // The current text of the item being edited

  // Constructor for AddFormAnswer, initializing index, edit function, and text.
  const AddFormAnswer({
    super.key,
    required this.index,
    required this.edit,
    required this.text,
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
            SizedBox(height: 20.h),
            Expanded(
              child: Form(
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
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          height: 0,
                          fontSize: 30.sp > 40 ? 40 : 30.sp,
                        ), // Set label style
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 18.sp > 30 ? 30 : 18.sp,
                      ), // Set text field style
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
            ),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Align buttons to the end
              children: <Widget>[
                TextButton(
                  child: myAutoSizedText(
                    appLocale.closeButton(
                      gender,
                    ), // Set cancel button text dynamically based on user gender
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
                    null,
                    30,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog on cancel
                  },
                ),
                TextButton(
                  child: myAutoSizedText(
                    appLocale.saveButton(
                      gender,
                    ), // Set save button text dynamically based on user gender
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
                    null,
                    30,
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
    );
  }
}
