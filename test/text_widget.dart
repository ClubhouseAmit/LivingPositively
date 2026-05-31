// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';

class TextWidget extends StatefulWidget {
  const TextWidget({super.key});
  @override
  State<TextWidget> createState() => _TextWidgetState();
}

class _TextWidgetState extends State<TextWidget> {
  String? dropdownValueAge = '18-30';
  String? dropdownValueGender = '';
  String? name = '';
  List<String> ages = ['18-', '18-30', '30-40', '40-55', '55+'];
  List<String> genders = ['אתה', 'את', 'לשון מעורבת', 'לא מעוניין להגיד'];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              Container(
                width: 300,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    height: 35,
                    child: TextField(
                      key: Key('TextFieldName'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 6.0),
                      ),
                      onChanged: (text) {
                        // Do something with the text
                        name = text;
                      },
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                ),
              ),
              Container(
                width: 300,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: DropdownMenu<String>(
                    key: Key('dropdownAge'),
                    width: 300,
                    initialSelection: "18-30",
                    dropdownMenuEntries: [
                      ...ages.map(
                        (age) => DropdownMenuEntry(value: age, label: age),
                      ),
                    ],
                    onSelected: (String? newValue) {
                      setState(() {
                        if (newValue != null) {
                          dropdownValueAge = newValue;
                        }
                      });
                      // Do something with the selected value
                    },
                  ),
                ),
              ),
              Container(
                width: 300,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: DropdownMenu<String>(
                    key: Key('dropdownGender'),
                    width: 300,
                    initialSelection: 'אתה',
                    dropdownMenuEntries: [
                      ...genders.map(
                        (gender) =>
                            DropdownMenuEntry(value: gender, label: gender),
                      ),
                    ],
                    onSelected: (String? newValue) {
                      setState(() {
                        if (newValue != null) {
                          dropdownValueGender = newValue;
                        }
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
