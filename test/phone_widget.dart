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
  List<dynamic> phones = [];

  @override
  void dispose() {
    for (final controller in nameControllers) {
      controller.dispose();
    }
    for (final controller in numberControllers) {
      controller.dispose();
    }
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  void addPhone(name, number) {
    {
      setState(() {
        phones.add({'name': name, 'number': number});
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
        phones[index] = {'name': newName, 'number': newNumber};
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
                        final index = entry.key;
                        final isEditing = index == editingIndex;
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              if (isEditing)
                                IconButton(
                                  key: const Key('deletePhoneButton'),
                                  icon: const Icon(Icons.delete, size: 40),
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
                                key: const Key('addPhoneButtonInEdit'),
                                offstage: !isEditing,
                                child: IconButton(
                                  icon: const Icon(Icons.check, size: 40),
                                  onPressed: () {
                                    // Update the item with the new data from the text fields
                                    final newPhoneName =
                                        nameControllers[index].text;
                                    final newPhoneNumber =
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: isEditing
                                    ? TextField(
                                        key: const Key('numberField'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                        controller: numberControllers[index],
                                      )
                                    : InkWell(
                                        key: const Key('enterEditingMode'),
                                        onTap: () {
                                          // Enter editing mode
                                          setState(() {
                                            editingIndex = index;
                                          });
                                        },
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: Text(
                                                key: const Key('phoneNameAfterAdd'),
                                                phones[index]['name'],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              if (isEditing) const Text('טלפון'),
                              if (!isEditing)
                                const InkWell(
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
                                      key: const Key('nameField'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      controller: nameControllers[index],
                                    ),
                                  ),
                                ),
                              if (isEditing) const Text('שם'),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(width: 10), // Add some space between the buttons
                      TextButton(
                        key: const Key('addPhoneButton'),
                        onPressed: () {
                          setState(() {
                            // Create new controllers with empty text
                            final nameController = TextEditingController(
                              text: '',
                            );
                            final numberController = TextEditingController(
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
                        child: const Text('manual'),
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
