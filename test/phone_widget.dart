import 'package:flutter/material.dart';

class PhoneWidget extends StatefulWidget {
  const PhoneWidget({super.key});

  @override
  State<PhoneWidget> createState() => _PhoneWidgetState();
}

class _PhoneWidgetState extends State<PhoneWidget> {
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> numberControllers = [];
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  bool isEditingNew = false;
  int editingIndex = -1;
  var phones = [];

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in numberControllers) {
      controller.dispose();
    }
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  void addPhone(name, number) {
    {
      setState(() {
        phones.add({"name": name, "number": number});
      });
    }
  }

  void removeItemAtIndex(int index) {
    setState(() {
      if (index >= 0 && index < phones.length) {
        phones.removeAt(index);
      }
    });
  }

  void updateItemAt(int index, String newName, String newNumber) {
    setState(() {
      if (index >= 0 && index < phones.length) {
        phones[index] = {"name": newName, "number": newNumber};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                children: [
                  Column(
                    children: [
                      ...phones.asMap().entries.map((entry) {
                        int index = entry.key;
                        bool isEditing = index == editingIndex;
                        return Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              if (isEditing)
                                IconButton(
                                  key: Key('deletePhoneButton'),
                                  icon: Icon(Icons.delete, size: 40),
                                  onPressed: () {
                                    // Remove the item from phonePageData
                                    removeItemAtIndex(index);

                                    // Remove the corresponding TextEditingController from the lists
                                    nameControllers.removeAt(index);
                                    numberControllers.removeAt(index);

                                    if (editingIndex == index) {
                                      editingIndex = -1;
                                    }
                                  },
                                ),
                              Offstage(
                                key: Key('addPhoneButtonInEdit'),
                                offstage: !isEditing,
                                child: IconButton(
                                  icon: Icon(Icons.check, size: 40),
                                  onPressed: () {
                                    // Update the item with the new data from the text fields
                                    String newPhoneName =
                                        nameControllers[index].text;
                                    String newPhoneNumber =
                                        numberControllers[index].text;
                                    updateItemAt(
                                      index,
                                      newPhoneName,
                                      newPhoneNumber,
                                    );
                                    editingIndex = -1;
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: isEditing
                                    ? TextField(
                                        key: Key("numberField"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                        controller: numberControllers[index],
                                      )
                                    : InkWell(
                                        key: Key("enterEditingMode"),
                                        onTap: () {
                                          // Enter editing mode
                                          setState(() {
                                            editingIndex = index;
                                          });
                                        },
                                        child: Card(
                                          child: Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: Text(
                                                key: Key('phoneNameAfterAdd'),
                                                phones[index]["name"],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              if (isEditing) Text("טלפון"),
                              if (!isEditing)
                                InkWell(
                                  child: CircleAvatar(
                                    radius: 20,
                                    foregroundColor: Colors.white,
                                    child: Icon(Icons.phone, size: 30),
                                  ),
                                ),
                              if (isEditing)
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: TextField(
                                      key: Key("nameField"),
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      controller: nameControllers[index],
                                    ),
                                  ),
                                ),
                              if (isEditing) Text("שם"),
                            ],
                          ),
                        );
                      }),

                      SizedBox(width: 10), // Add some space between the buttons
                      TextButton(
                        key: Key('addPhoneButton'),
                        onPressed: () {
                          setState(() {
                            // Create new controllers with empty text
                            var nameController = TextEditingController(
                              text: '',
                            );
                            var numberController = TextEditingController(
                              text: '',
                            );

                            // Add the controllers to the lists
                            nameControllers.add(nameController);
                            numberControllers.add(numberController);

                            // Add a new item to phonePageData
                            addPhone('', '');

                            editingIndex = phones.length - 1;
                          });
                        },
                        child: Text('manual'),
                      ),
                    ],
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
