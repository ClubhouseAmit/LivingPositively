import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/shadows.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';

import 'package:provider/provider.dart';

class CountrySelectorWidget extends StatefulWidget {
  final String text;
  final String disclaimerText;

  const CountrySelectorWidget({
    super.key,
    required this.text,
    required this.disclaimerText,
  });

  @override
  _CountrySelectorWidgetState createState() => _CountrySelectorWidgetState();
}

class _CountrySelectorWidgetState
    extends LPExtendedState<CountrySelectorWidget> {
  bool isVisible = false;
  bool _didInitLocation = false;
  String resolveCountryCode(String? currentLocation, BuildContext context) {
    final normalizedLocation = (currentLocation ?? '').trim().toUpperCase();
    if (normalizedLocation.isNotEmpty) {
      return normalizedLocation;
    }

    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final platformCode = (platformLocale.countryCode ?? '')
        .trim()
        .toUpperCase();
    if (platformCode.isNotEmpty && countryPickerCodes.contains(platformCode)) {
      return platformCode;
    }

    final localeCode = Localizations.localeOf(context).countryCode ?? '';
    final normalizedLocale = localeCode.trim().toUpperCase();
    if (normalizedLocale.isNotEmpty &&
        countryPickerCodes.contains(normalizedLocale)) {
      return normalizedLocale;
    }

    return defaultPickerCountry.countryCodes.first;
  }

  void saveLocation(String location, UserInformation userInfo) async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance
    final normalizedLocation = location.trim().toUpperCase();
    await service.setItem(
      "location",
      PersistentMemoryType.String,
      normalizedLocation,
    );
    userInfo.updateLocation(normalizedLocation);
  }

  void changeVisible() {
    setState(() {
      isVisible = !isVisible;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitLocation) {
      return;
    }

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (userInfoProvider.location.isEmpty) {
      saveLocation(resolveCountryCode('', context), userInfoProvider);
    }
    _didInitLocation = true;
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    final initialCountryCode = resolveCountryCode(
      userInfoProvider.location,
      context,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dialogTextStyle =
        theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface) ??
        TextStyle(color: colorScheme.onSurface);
    return Column(
      // Stretch so this field is the same width as the ones above it; the
      // enclosing block sets the width.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      // Same label-to-field gap as the other field groups on this screen; the
      // separation from the next group belongs to the enclosing block.
      spacing: OnboardingGaps.labelToField,
      children: [
        SizedBox(
          child: Row(
            children: [
              Expanded(
                // Matches _formLabel on the get-to-know-you screen: the country
                // field has no Figma counterpart, but it sits in that screen's
                // label/field rhythm and must read as one of its fields.
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: kFormFieldLabelSize.sp,
                    height: kFormFieldLabelHeight,
                    fontWeight: AppFontWeight.semiBold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Rubix',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: TextButton(
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    iconColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.onSurface,
                    ),
                    overlayColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  onPressed: changeVisible,
                  child: const Icon(Icons.question_mark, size: 12),
                ),
              ),
            ],
          ),
        ),
        // Same container spec as the name/age/gender fields above it — the
        // design gives every field on this screen one treatment (radius 16,
        // 1px grey outline, no fill, card shadow). This used to be a one-off:
        // radius 8, a grey fill, and a hand-rolled shadow.
        Container(
          height: kFormFieldHeight,
          padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 8),
          decoration: formFieldDecoration(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CountryCodePicker(
                  showDropDownButton: false, // Remove the default button
                  showFlag: true,
                  showFlagDialog: true,
                  showFlagMain: true,
                  onChanged: (country) {
                    setState(() {
                      saveLocation(country.code!, userInfoProvider);
                    });
                  },
                  initialSelection: initialCountryCode,
                  showCountryOnly: true,
                  showOnlyCountryWhenClosed: true,
                  dialogBackgroundColor: colorScheme.surface,
                  dialogTextStyle: dialogTextStyle,
                  alignLeft: true, // Changed to true for left alignment
                  countryFilter: countryPickerCodes,
                  padding: EdgeInsets.zero, // Remove internal padding
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.outline,
                size: 24,
              ),
            ],
          ),
        ),
        Visibility(
          visible: isVisible,
          child: GestureDetector(
            onTap: () {
              changeVisible();
            },
            child: Container(
              alignment: appLocale.textDirection == "rtl"
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              // DESIGN.md forbids one-off drop shadows; this popup has no
              // design counterpart, so it borrows the card token.
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(kFormFieldRadius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
                boxShadow: AppShadows.card,
              ),
              constraints: BoxConstraints(minHeight: 50.h),
              child: Text(widget.disclaimerText),
            ),
          ),
        ),
      ],
    );
  }
}
