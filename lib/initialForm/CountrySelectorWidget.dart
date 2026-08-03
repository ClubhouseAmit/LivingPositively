import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class CountrySelectorWidget extends StatefulWidget {

  const CountrySelectorWidget({
    required this.text, required this.disclaimerText, super.key,
  });
  final String text;
  final String disclaimerText;

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

  Future<void> saveLocation(String location, UserInformation userInfo) async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance
    final normalizedLocation = location.trim().toUpperCase();
    await service.setItem(
      'location',
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
    final dialogTextStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
    ) ??
        TextStyle(color: colorScheme.onSurface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 56,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                spreadRadius: 1,
                offset: Offset(0, 1), // changes position of shadow
              ),
            ],
            borderRadius: BorderRadius.circular(8.r),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CountryCodePicker(
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
        const SizedBox(height: 12),
        Visibility(
          visible: isVisible,
          child: GestureDetector(
            onTap: changeVisible,
            child: Container(
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 50.h),
              child: Text(widget.disclaimerText),
            ),
          ),
        ),
      ],
    );
  }
}
