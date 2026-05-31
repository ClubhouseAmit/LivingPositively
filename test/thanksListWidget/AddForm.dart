import 'package:flutter/material.dart';
import 'package:mazilon/util/styles.dart';

class AddForm extends StatefulWidget {
  final Function add;
  final int index;
  final Function edit;
  final String text;
  final String formTitle;
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

class _AddFormState extends State<AddForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 1000
            ? 800
            : MediaQuery.of(context).size.width,
        // Remove the fixed height
        // height: MediaQuery.of(context).size.height * 20 / 100,
        child: SingleChildScrollView(
          // Wrap Column with SingleChildScrollView
          child: Column(
            children: [
              SizedBox(height: 10),
              myAutoSizedText(
                '${widget.formTitle} חדשה',
                TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                null,
                40,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: TextFormField(
                                  key: Key('addFormTextField'),
                                  maxLength: 100,
                                  controller: _controller,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    labelText: widget.formTitle,
                                    contentPadding: EdgeInsets.only(right: 1.0),
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'Rubix',
                                      height: 0,
                                      fontSize: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'ה${widget.formTitle} לא יכולה להיות ריקה';
                                    }
                                    return null;
                                  },
                                ),
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
                  TextButton(
                    key: Key('cancelButton'),
                    child: myAutoSizedText(
                      'בטל',
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      null,
                      30,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    key: Key('saveButton'),
                    child: myAutoSizedText(
                      'שמור',
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      null,
                      30,
                    ),
                    onPressed: () {
                      // Save the reminder
                      setState(() {
                        if (_formKey.currentState!.validate()) {
                          if (widget.text != '') {
                            widget.edit(_controller.text, widget.index);
                          } else {
                            widget.add(_controller.text);
                          }
                          Navigator.of(context).pop();
                        }
                      });
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
