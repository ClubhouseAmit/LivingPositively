import 'package:flutter/material.dart';
import 'package:mazilon/form/phonePageListItem.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide PermissionStatus;

import 'package:mazilon/l10n/app_localizations.dart';

class PhonePageForm extends StatefulWidget {
  final Function next;
  final Function prev;

  PhonePageData phonePageData;
  PhonePageForm({
    Key? key,
    required this.next,
    required this.prev,
    required this.phonePageData,
  }) : super(key: key);

  @override
  State<PhonePageForm> createState() => _PhonePageFormState();
}

class _PhonePageFormState extends LPExtendedState<PhonePageForm> {
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> numberControllers = [];
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  bool isEditingNew = false;
  int editingIndex = -1;

  //add contact to the list from the contact list in the phone
  void addItem(Contact contact) {
    //  debugPrint(contact.phones);
    String? phoneName = contact.displayName;
    String? phoneNumber =
        contact.phones.isNotEmpty == true ? contact.phones[0].number : null;
    if (phoneName != null && phoneNumber != null) {
      widget.phonePageData.addItem(phoneName, phoneNumber);
      editingIndex = widget.phonePageData.savedPhoneNames.length -
          1; // Set editingIndex to the index of the new contact
      nameControllers.add(TextEditingController(text: phoneName));
      numberControllers.add(TextEditingController(text: phoneNumber));
    } else {
      debugPrint("Both fields must be filled");
    }
  }

  Future<void> pickContact() async {
    PermissionStatus status = await Permission.contacts.status;

    if (await FlutterContacts.permissions.has(PermissionType.read)) {
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone, ContactProperty.name},
      );
      if (contact != null) {
        addItem(contact);
      }
      setState(() {});
    } else {
      await FlutterContacts.permissions.request(PermissionType.read);
    }
  }

  @override
  void dispose() {
    nameControllers.forEach((controller) => controller.dispose());
    numberControllers.forEach((controller) => controller.dispose());
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.phonePageData.savedPhoneNames.length; i++) {
      nameControllers.add(
          TextEditingController(text: widget.phonePageData.savedPhoneNames[i]));
      numberControllers.add(TextEditingController(
          text: widget.phonePageData.savedPhoneNumbers[i]));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.phonePageData = Provider.of<PhonePageData>(context, listen: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: true);

    final gender = userInfoProvider.gender;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: returnSizedBox(context, 20)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    alignment: Alignment.topCenter,
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: myAutoSizedText(
                        appLocale!.phonesPageHeader(gender),
                        TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                            height: 1.5),
                        TextAlign.center,
                        40),
                  ),
                ),
                SizedBox(
                  height: 5.h,
                ),
                Consumer<PhonePageData>(
                  builder: (context, phonePageData, child) {
                    return Column(
                      children: [
                        //add contact from contact list button:
                        TextButton(
                          onPressed: pickContact,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(6),
                          ),
                          child: myText(
                              appLocale!.phonesPageContactImportTitle(gender),
                              TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryPurple,
                                  fontSize: 16.sp),
                              TextAlign.center),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: returnSizedBox(context, 10)),
            //list of phones added in form Phone Page by the user either manually or from contact list:
            Consumer<PhonePageData>(
              builder: (context, phonePageData, child) {
                return Column(
                  children: [
                    PhonePageList(phonePageData: widget.phonePageData),
                    //add contact from contact list button:
                  ],
                );
              },
            ),
            SizedBox(
              height: returnSizedBox(context, 10),
            ),
            //save all data after confirming:
            ConfirmationButton(context, () async {
              await widget.phonePageData.loadItemsFromPrefs();
              await widget.phonePageData.saveItemsToPrefs();
              widget.phonePageData.update();
              widget.next();
            },
                appLocale!.nextButton(gender),
                myTextStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 20.sp)),
            Center(
              child: Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: myAutoSizedText(
                    appLocale!.addingContactDisclaimer,
                    TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        height: 1.5),
                    TextAlign.center,
                    40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
