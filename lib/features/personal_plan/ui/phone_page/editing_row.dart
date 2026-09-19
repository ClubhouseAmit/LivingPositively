part of 'list.dart';

final class _PhoneEditingRow extends StatelessWidget {
  const _PhoneEditingRow({
    required this.formKey,
    required this.nameController,
    required this.numberController,
    required this.countryCode,
    required this.countryPickerKey,
    required this.nameLabel,
    required this.phoneLabel,
    required this.countryCodeHint,
    required this.saveTooltip,
    required this.cancelTooltip,
    required this.deleteTooltip,
    required this.validateName,
    required this.validateNumber,
    required this.dialCode,
    required this.onSave,
    required this.onCancel,
    required this.onCountryChanged,
    this.onDelete,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController numberController;
  final String countryCode;
  final String countryPickerKey;
  final String nameLabel;
  final String phoneLabel;
  final String countryCodeHint;
  final String saveTooltip;
  final String cancelTooltip;
  final String deleteTooltip;
  final FormFieldValidator<String> validateName;
  final FormFieldValidator<String> validateNumber;
  final String? dialCode;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ValueChanged<String> onCountryChanged;
  final VoidCallback? onDelete;

  Widget _nameField() {
    return TextFormField(
      controller: nameController,
      decoration: InputDecoration(
        labelText: nameLabel,
        suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
            ? SpeechDictationSuffixAction(controller: nameController)
            : null,
      ),
      validator: validateName,
    );
  }

  Widget _numberField() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: numberController,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          labelText: phoneLabel,
          suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
              ? SpeechDictationSuffixAction(
                  controller: numberController,
                  isPhoneNumber: true,
                  transcriptTransformer: (transcript, localeId) =>
                      normalizeSpokenPhoneNumber(
                        transcript,
                        localeId: localeId,
                      ),
                  replacementValidator: (transcript) =>
                      PhonePageData.canonicalizePhoneNumber(
                        transcript,
                        dialCode,
                      ) !=
                      null,
                )
              : null,
        ),
        validator: validateNumber,
      ),
    );
  }

  Widget _phoneField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: countryCodeHint,
          child: SizedBox(
            width: _countryPickerWidth,
            child: CountryCodePicker(
              key: ValueKey(countryPickerKey),
              initialSelection: countryCode,
              countryFilter: countryPickerCodes,
              showFlag: false,
              showDropDownButton: true,
              padding: EdgeInsets.zero,
              onChanged: (selectedCountry) {
                final selectedCode = selectedCountry.code;
                if (selectedCode != null) onCountryChanged(selectedCode);
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _numberField()),
      ],
    );
  }

  Widget _fields(BuildContext context, BoxConstraints constraints) {
    final helper = Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: Text(
        countryCodeHint,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
    if (constraints.maxWidth < 520) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _nameField(),
          const SizedBox(height: AppSpacing.sm),
          _phoneField(),
          helper,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _nameField()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 2, child: _phoneField()),
          ],
        ),
        helper,
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: saveTooltip,
          icon: Icon(Icons.check, size: returnSizedBox(context, 32)),
          onPressed: onSave,
        ),
        IconButton(
          tooltip: cancelTooltip,
          icon: Icon(Icons.close, size: returnSizedBox(context, 32)),
          onPressed: onCancel,
        ),
        if (onDelete != null)
          IconButton(
            tooltip: deleteTooltip,
            icon: Icon(Icons.delete, size: returnSizedBox(context, 32)),
            onPressed: onDelete,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(
        returnSizedBox(context, AppSpacing.sm.toInt()),
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) => _fields(context, constraints),
            ),
            _actions(context),
          ],
        ),
      ),
    );
  }
}
