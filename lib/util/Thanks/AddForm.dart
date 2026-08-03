import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart'; //
import 'package:provider/provider.dart'; //
//

// the add form widget, it shows a form to add or edit an item to the list
class AddForm extends StatefulWidget { // the title of the form
  const AddForm({
    required this.add, required this.index, required this.edit, required this.text, required this.formTitle, super.key,
  });
  final Function add; // the function to add item to the list
  final int index; // the index of the item in the list
  final Function edit; // the function to edit the item in the list
  final String text; // the text of the item
  final String formTitle;
  @override
  State<AddForm> createState() => _AddFormState();
}

class _AddFormState extends LPExtendedState<AddForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  void _onSubmitForm(UserInformation userInfoProvider) {
    if (_formKey.currentState!.validate()) {
      if (widget.text != '') {
        widget.edit(_controller.text, widget.index, userInfoProvider);
      } else {
        widget.add(_controller.text, userInfoProvider);
      }
      Navigator.of(context).pop();
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

  // build the add form widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation and userInformation providers

    final userInfoProvider = Provider.of<UserInformation>(
      context,
    ); //
    final gender = userInfoProvider.gender;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
          // Wrap Column with SingleChildScrollView
          child: Column(
            children: [
              const SizedBox(height: Spacing.sm),
              // text on the top of the form
              Semantics(
                header: true,
                child: AutoSizeText(
                  appLocale.newTraitOrThanks(widget.formTitle),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            // the text field
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextFormField(
                                onFieldSubmitted: (_) =>
                                    _onSubmitForm(userInfoProvider),
                                maxLength:
                                    100, // set the max length of the text field
                                controller: _controller,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: widget.formTitle,
                                  contentPadding: const EdgeInsets.only(right: 1),
                                  labelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(height: 0),
                                ),
                                validator: (value) {
                                  // validate the text field
                                  if (value == null || value.isEmpty) {
                                    return appLocale.validateEmpty;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  // the close button
                  TextButton(
                    child: AutoSizeText(
                      appLocale.closeButton(gender),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  // the save button
                  TextButton(
                    child: AutoSizeText(
                      appLocale.saveButton(gender),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    onPressed: () => {_onSubmitForm(userInfoProvider)},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
