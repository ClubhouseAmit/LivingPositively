import 'package:flutter/material.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class PhonePageList extends StatefulWidget {
  const PhonePageList({required this.phonePageData, super.key});
  final PhonePageData phonePageData;
  @override
  _PhonePageListState createState() => _PhonePageListState();
}

class _PhonePageListState extends LPExtendedState<PhonePageList> {
  int editingIndex = -1;
  final Map<int, GlobalKey<FormState>> _formKeys = {};
  final GlobalKey<FormState> _draftFormKey = GlobalKey<FormState>();
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> numberControllers = [];
  TextEditingController? _draftNameController;
  TextEditingController? _draftNumberController;

  @override
  void initState() {
    super.initState();
    final phonePageData = Provider.of<PhonePageData>(context, listen: false);
    _syncControllers(phonePageData);
  }

  @override
  void dispose() {
    for (final controller in nameControllers) {
      controller.dispose();
    }
    for (final controller in numberControllers) {
      controller.dispose();
    }
    _draftNameController?.dispose();
    _draftNumberController?.dispose();
    super.dispose();
  }

  int _contactCount(PhonePageData phonePageData) {
    return phonePageData.savedPhoneNames.length <
            phonePageData.savedPhoneNumbers.length
        ? phonePageData.savedPhoneNames.length
        : phonePageData.savedPhoneNumbers.length;
  }

  void _syncControllers(PhonePageData phonePageData) {
    final count = _contactCount(phonePageData);
    while (nameControllers.length < count) {
      final index = nameControllers.length;
      nameControllers.add(
        TextEditingController(text: phonePageData.savedPhoneNames[index]),
      );
      numberControllers.add(
        TextEditingController(text: phonePageData.savedPhoneNumbers[index]),
      );
    }
    for (var index = 0; index < count; index++) {
      if (index == editingIndex) {
        continue;
      }
      if (nameControllers[index].text != phonePageData.savedPhoneNames[index]) {
        nameControllers[index].text = phonePageData.savedPhoneNames[index];
      }
      if (numberControllers[index].text !=
          phonePageData.savedPhoneNumbers[index]) {
        numberControllers[index].text = phonePageData.savedPhoneNumbers[index];
      }
    }
    while (nameControllers.length > count) {
      nameControllers.removeLast().dispose();
      numberControllers.removeLast().dispose();
    }
    _formKeys.removeWhere((index, _) => index >= count);
    if (editingIndex >= count) {
      editingIndex = -1;
    }
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return appLocale.contactNameRequiredError;
    }
    return null;
  }

  String? _validateNumber(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return appLocale.contactPhoneRequiredError;
    }
    final normalized = trimmed.replaceAll(RegExp(r'[\s().-]'), '');
    if (!RegExp(r'^\+?\d{2,}$').hasMatch(normalized)) {
      return appLocale.contactPhoneInvalidError;
    }
    return null;
  }

  void _startDraft() {
    if (_draftNameController != null || _draftNumberController != null) {
      return;
    }
    setState(() {
      editingIndex = -1;
      _draftNameController = TextEditingController();
      _draftNumberController = TextEditingController();
    });
  }

  void _cancelDraft() {
    setState(() {
      _draftNameController?.dispose();
      _draftNumberController?.dispose();
      _draftNameController = null;
      _draftNumberController = null;
    });
  }

  void _cancelExistingEdit(PhonePageData phonePageData, int index) {
    setState(() {
      if (index < _contactCount(phonePageData)) {
        nameControllers[index].text = phonePageData.savedPhoneNames[index];
        numberControllers[index].text = phonePageData.savedPhoneNumbers[index];
      }
      editingIndex = -1;
    });
  }

  void _saveDraft(PhonePageData phonePageData) {
    if (!_draftFormKey.currentState!.validate()) {
      return;
    }
    phonePageData.addItem(
      _draftNameController!.text,
      _draftNumberController!.text,
    );
    _cancelDraft();
  }

  void _saveExisting(PhonePageData phonePageData, int index) {
    if (!_formKeys[index]!.currentState!.validate()) {
      return;
    }
    phonePageData.replaceItem(
      index,
      nameControllers[index].text,
      numberControllers[index].text,
    );
    setState(() {
      editingIndex = -1;
    });
  }

  Future<void> _confirmDelete(PhonePageData phonePageData, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appLocale.confirmDeleteContactTitle),
        content: Text(appLocale.confirmDeleteContactMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              appLocale.closeButton(
                Provider.of<UserInformation>(context, listen: false).gender,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              appLocale.deleteButton(
                Provider.of<UserInformation>(context, listen: false).gender,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    if (!mounted) {
      return;
    }
    phonePageData.removeItemAt(index);
    setState(() {
      editingIndex = -1;
      _formKeys.clear();
      if (index < nameControllers.length) {
        nameControllers.removeAt(index).dispose();
        numberControllers.removeAt(index).dispose();
      }
    });
  }

  Widget _displayRow(PhonePageData phonePageData, int index, String gender) {
    final name = phonePageData.savedPhoneNames[index];
    final number = phonePageData.savedPhoneNumbers[index];
    return Padding(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Row(
        children: [
          circularActionButton(
            context,
            tooltip: appLocale.callContactTooltip(name),
            icon: Icons.phone,
            diameter: Spacing.xl * 2,
            iconSize: Spacing.xl,
            onTap: () {
              launchWithFeedback(
                context,
                number,
                isCallFailure: true,
                launch: () => dialPhone(number),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: appLocale.contactEditTooltip,
            icon: const Icon(Icons.edit, size: 32),
            onPressed: () {
              setState(() {
                editingIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _editingRow({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController numberController,
    required String gender,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocale.phonesPageName(gender),
                    ),
                    validator: _validateName,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: numberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocale.phonesPagePhone(gender),
                    ),
                    validator: _validateNumber,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: appLocale.contactSaveTooltip,
                  icon: const Icon(Icons.check, size: 32),
                  onPressed: onSave,
                ),
                IconButton(
                  tooltip: appLocale.contactCancelTooltip,
                  icon: const Icon(Icons.close, size: 32),
                  onPressed: onCancel,
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: appLocale.contactDeleteTooltip,
                    icon: const Icon(Icons.delete, size: 32),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    final phonePageData = Provider.of<PhonePageData>(context);
    final gender = userInfoProvider.gender;
    _syncControllers(phonePageData);
    final contactCount = _contactCount(phonePageData);
    return Column(
      children: [
        ...List.generate(contactCount, (index) {
          if (index == editingIndex) {
            return _editingRow(
              formKey: _formKeys.putIfAbsent(
                index,
                GlobalKey<FormState>.new,
              ),
              nameController: nameControllers[index],
              numberController: numberControllers[index],
              gender: gender,
              onSave: () => _saveExisting(phonePageData, index),
              onCancel: () => _cancelExistingEdit(phonePageData, index),
              onDelete: () => _confirmDelete(phonePageData, index),
            );
          }
          return _displayRow(phonePageData, index, gender);
        }),
        if (_draftNameController != null && _draftNumberController != null)
          _editingRow(
            formKey: _draftFormKey,
            nameController: _draftNameController!,
            numberController: _draftNumberController!,
            gender: gender,
            onSave: () => _saveDraft(phonePageData),
            onCancel: _cancelDraft,
          ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: _startDraft,
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
            appLocale.phonesPageManualTitle(gender),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
