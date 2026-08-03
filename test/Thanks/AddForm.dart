import 'package:flutter/material.dart';


class AddForm extends StatefulWidget {
  const AddForm({
    required this.add, required this.index, required this.edit, required this.text, required this.formTitle, super.key,
  });
  final Function add;
  final int index;
  final Function edit;
  final String text;
  final String formTitle;
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
        width: 800 > 1000
            ? 800
            : 800,
        // Remove the fixed height
        // height: 600 * 20 / 100,
        child: SingleChildScrollView(
          // Wrap Column with SingleChildScrollView
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                '${widget.formTitle} חדשה',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: TextFormField(
                                  key: const Key('addFormTextField'),
                                  maxLength: 100,
                                  controller: _controller,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    labelText: widget.formTitle,
                                    contentPadding: const EdgeInsets.only(right: 1),
                                    labelStyle: const TextStyle(
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
                    key: const Key('cancelButton'),
                    child: const Text(
                      'בטל',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    key: const Key('saveButton'),
                    child: const Text(
                      'שמור',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    onPressed: () {
                      // Save the reminder
                      if (_formKey.currentState!.validate()) {
                        if (widget.text != '') {
                          widget.edit(_controller.text, widget.index);
                        } else {
                          widget.add(_controller.text);
                        }
                        Navigator.of(context).pop();
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
