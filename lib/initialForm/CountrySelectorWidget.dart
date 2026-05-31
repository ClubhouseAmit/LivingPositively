import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/styles.dart';
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
    final rightPadding = appLocale.textDirection == "rtl" ? 10.0 : 0.0;
    final leftPadding = appLocale.textDirection == "rtl" ? 0.0 : 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300.w),
          child: Row(
            children: [
              myAutoSizedText(
                widget.text,
                TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                null,
                24,
              ),
              TextButton(
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  iconColor: WidgetStatePropertyAll(Colors.black),
                  overlayColor: WidgetStatePropertyAll(backgroundGray),
                ),
                onPressed: changeVisible,
                child: Icon(Icons.question_mark, size: 12.sp),
              ),
            ],
          ),
        ),
        Container(
          width: 300,
          height: 70,
          padding: EdgeInsets.fromLTRB(rightPadding, 12, leftPadding, 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                spreadRadius: 1,
                blurRadius: 0,
                offset: Offset(0, 1), // changes position of shadow
              ),
            ],
            borderRadius: BorderRadius.circular(8.r),
            color: backgroundGray,
          ),
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
                  alignLeft: true, // Changed to true for left alignment
                  countryFilter: countryPickerCodes,
                  padding: EdgeInsets.zero, // Remove internal padding
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              width: 300.w,
              height: 50.h,
              child: Text(widget.disclaimerText),
            ),
          ),
        ),
      ],
    );
  }
}
