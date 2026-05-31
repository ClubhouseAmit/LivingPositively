import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';

class PhonePageList extends StatefulWidget {
  final PhonePageData phonePageData;
  @override
  _PhonePageListState createState() => _PhonePageListState();
  const PhonePageList({super.key, required this.phonePageData});
}

class _PhonePageListState extends LPExtendedState<PhonePageList> {
  int editingIndex = -1;
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> numberControllers = [];

  @override
  void initState() {
    super.initState();
    final phonePageData = Provider.of<PhonePageData>(context, listen: false);
    // Initialize the controllers with the existing phone names and numbers
    for (int i = 0; i < phonePageData.savedPhoneNames.length; i++) {
      nameControllers.add(
        TextEditingController(text: phonePageData.savedPhoneNames[i]),
      );
      numberControllers.add(
        TextEditingController(text: phonePageData.savedPhoneNumbers[i]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    final phonePageData = Provider.of<PhonePageData>(context);
    final gender = userInfoProvider.gender;
    return Column(
      children: [
        ...phonePageData.savedPhoneNames.asMap().entries.map((entry) {
          int index = entry.key;
          bool isEditing = index == editingIndex;
          return Padding(
            padding: EdgeInsets.all(returnSizedBox(context, 8)),
            child: Row(
              children: [
                if (isEditing)
                  myText(
                    appLocale.phonesPageName(gender),
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    null,
                  ),
                if (isEditing)
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14.sp,
                      ),
                      controller: nameControllers[index],
                    ),
                  ),
                if (!isEditing)
                  InkWell(
                    onTap: () async {
                      String url =
                          'tel:${phonePageData.savedPhoneNumbers[index]}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    //phone icon button:
                    child: CircleAvatar(
                      radius: returnSizedBox(context, 20),
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      child: Icon(
                        Icons.phone,
                        size: returnSizedBox(context, 30),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                if (isEditing)
                  myText(
                    appLocale.phonesPagePhone(gender),
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                    null,
                  ),
                Expanded(
                  child: isEditing
                      ? TextField(
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12.sp,
                          ),
                          controller: numberControllers[index],
                        )
                      : InkWell(
                          onTap: () {
                            // Enter editing mode
                            editingIndex = index;
                            phonePageData.update();
                          },
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(
                                returnSizedBox(context, 10),
                              ),
                              child: myText(
                                phonePageData.savedPhoneNames[index],
                                TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14.sp,
                                ),
                                null,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                //FINISH EDITING BUTTON:(second button from the left)
                Offstage(
                  offstage: !isEditing,
                  child: IconButton(
                    icon: Icon(Icons.check, size: returnSizedBox(context, 40)),
                    onPressed: () {
                      // Update the item with the new data from the text fields
                      String newPhoneName = nameControllers[index].text;
                      String newPhoneNumber = numberControllers[index].text;
                      //save it in the phones lists (for names and numbers) in phonePageData:
                      phonePageData.replaceItem(
                        index,
                        newPhoneName,
                        newPhoneNumber,
                      );
                      editingIndex = -1;
                      //call the update method to update the UI and commit changes:
                      phonePageData.update();
                    },
                  ),
                ),
                //buttons only shown if the user chose to start editing:
                if (isEditing)
                  //DELETE BUTTON:(mostleft button)
                  IconButton(
                    icon: Icon(Icons.delete, size: returnSizedBox(context, 40)),
                    onPressed: () {
                      // Remove the item from phonePageData
                      phonePageData.removeItemAt(index);

                      // Remove the corresponding TextEditingController from the lists
                      nameControllers.removeAt(index);
                      numberControllers.removeAt(index);

                      if (editingIndex == index) {
                        editingIndex = -1;
                      }
                      phonePageData.update();
                    },
                  ),
              ],
            ),
          );
        }),
        const SizedBox(width: 10), // Add some space between the buttons
        //add contact manually button:
        TextButton(
          onPressed: () {
            setState(() {
              // Create new controllers with empty text
              var nameController = TextEditingController(text: '');
              var numberController = TextEditingController(text: '');

              // Add the controllers to the lists
              nameControllers.add(nameController);
              numberControllers.add(numberController);

              // Add a new item to phonePageData
              phonePageData.savedPhoneNames.add('');
              phonePageData.savedPhoneNumbers.add('');

              editingIndex = phonePageData.savedPhoneNames.length - 1;
              phonePageData.update();
            });
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(6),
          ),
          child: myText(
            appLocale.phonesPageManualTitle(gender),
            TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryPurple,
              fontSize: 16.sp,
            ),
            TextAlign.center,
          ),
        ),
      ],
    );
  }
}
