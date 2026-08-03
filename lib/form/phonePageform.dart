import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide PermissionStatus;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/form/phonePageListItem.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class PhonePageForm extends StatefulWidget {
  const PhonePageForm({
    required this.next, required this.prev, required this.phonePageData, super.key,
  });
  final Function next;
  final Function prev;

  final PhonePageData phonePageData;

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
    final phoneName = contact.displayName;
    final phoneNumber = contact.phones.isNotEmpty
        ? contact.phones[0].number
        : null;
    if (phoneName != null && phoneNumber != null) {
      final added = widget.phonePageData.addItem(phoneName, phoneNumber);
      if (!added) {
        final message = phoneName.trim().isEmpty
            ? appLocale.contactNameRequiredError
            : appLocale.contactPhoneInvalidError;
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      editingIndex =
          widget.phonePageData.savedPhoneNames.length -
          1; // Set editingIndex to the index of the new contact
      nameControllers.add(TextEditingController(text: phoneName));
      numberControllers.add(TextEditingController(text: phoneNumber));
    } else {
      debugPrint('Both fields must be filled');
    }
  }

  Future<void> pickContact() async {
    final hasPermission = await FlutterContacts.permissions.has(
      PermissionType.read,
    );
    if (!mounted) {
      return;
    }
    if (hasPermission) {
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone, ContactProperty.name},
      );
      if (!mounted) {
        return;
      }
      if (contact != null) {
        addItem(contact);
      }
      if (!mounted) {
        return;
      }
      setState(() {});
    } else {
      await FlutterContacts.permissions.request(PermissionType.read);
    }
  }

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

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.phonePageData.savedPhoneNames.length; i++) {
      nameControllers.add(
        TextEditingController(text: widget.phonePageData.savedPhoneNames[i]),
      );
      numberControllers.add(
        TextEditingController(text: widget.phonePageData.savedPhoneNumbers[i]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );

    final gender = userInfoProvider.gender;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
            const SizedBox(height: Spacing.xl),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    alignment: Alignment.topCenter,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: Semantics(
                      header: true,
                      child: AutoSizeText(
                        appLocale.phonesPageHeader(gender),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Consumer<PhonePageData>(
                  builder: (context, phonePageData, child) {
                    return Column(
                      children: [
                        //add contact from contact list button:
                        TextButton(
                          onPressed: pickContact,
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(6),
                          ),
                          child: Text(
                            appLocale.phonesPageContactImportTitle(gender),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
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
            const SizedBox(height: Spacing.md),
            //save all data after confirming:
            ElevatedButton(
              onPressed: () async {
                await widget.phonePageData.loadItemsFromPrefs();
                await widget.phonePageData.saveItemsToPrefs();
                widget.phonePageData.update();
                widget.next();
              },
              child: Text(appLocale.nextButton(gender)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
              child: ExpansionTile(
                leading: Tooltip(
                  message: appLocale.phoneContactDisclaimerMoreTooltip,
                  child: Icon(
                    Icons.info_outline,
                    size: 20.sp,
                    semanticLabel: appLocale.phoneContactDisclaimerMoreTooltip,
                  ),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: AutoSizeText(
                  appLocale.phoneContactDisclaimerSummary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                ),
                children: [
                  AutoSizeText(
                    appLocale.addingContactDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.5,
                        ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
