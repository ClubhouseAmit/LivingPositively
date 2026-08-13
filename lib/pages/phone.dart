import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Phone/EmergencyPhones.dart';

enum _SosDeliveryOption { app, contact, map }

enum _SosContactDeliveryOption { sms, whatsApp }

enum _SosLocationFailure { servicesDisabled, unavailable }

typedef _SosLocationLookupResult = ({
  Position? position,
  _SosLocationFailure? failure,
});

class PhonePage extends StatefulWidget {
  final PhonePageData phonePageData;
  const PhonePage({super.key, required this.phonePageData});

  @override
  _PhonePageState createState() => _PhonePageState();
}

class _PhonePageState extends LPExtendedState<PhonePage> {
  String mainTitle = '';
  String contactsTitle = '';
  String emergencyNumbersTitle = '';
  bool _isSosDeliveryInProgress = false;

  bool get _supportsLocationSharing =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _startLocationDelivery() =>
      _runSosDelivery(_runLocationDelivery);

  Future<void> _runLocationDelivery() async {
    while (mounted) {
      final locationResult = await _lookupCurrentPosition();
      if (!mounted) {
        return;
      }

      final position = locationResult.position;
      if (position != null) {
        final mapLink = _mapShareLink(position);
        await _showDeliveryOptions(
          '${appLocale.sosShareLocationMessage}\n$mapLink',
          mapAppUrl: _mapAppUrl(position),
        );
        return;
      }

      final shouldRetry = await _showLocationFailureDialog(
        locationResult.failure == _SosLocationFailure.servicesDisabled
            ? appLocale.sosShareLocationServicesDisabled
            : appLocale.sosShareLocationUnavailable,
      );
      if (!mounted || !shouldRetry) {
        return;
      }
    }
  }

  Future<void> _startMessageDelivery() => _runSosDelivery(
    () => _showDeliveryOptions(appLocale.sosShareLocationMessage),
  );

  Future<void> _runSosDelivery(Future<void> Function() delivery) async {
    if (_isSosDeliveryInProgress || !mounted) {
      return;
    }
    setState(() {
      _isSosDeliveryInProgress = true;
    });

    try {
      await delivery();
    } finally {
      if (mounted) {
        setState(() {
          _isSosDeliveryInProgress = false;
        });
      }
    }
  }

  Future<_SosLocationLookupResult> _lookupCurrentPosition() async {
    if (!_supportsLocationSharing) {
      return (position: null, failure: _SosLocationFailure.unavailable);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (position: null, failure: _SosLocationFailure.servicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return (position: null, failure: _SosLocationFailure.unavailable);
      }

      return (
        position: await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        ),
        failure: null,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not get SOS location: $error\n$stackTrace');
      return (position: null, failure: _SosLocationFailure.unavailable);
    }
  }

  String _mapShareLink(Position position) =>
      'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

  String _mapAppUrl(Position position) {
    final coordinates = '${position.latitude},${position.longitude}';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'geo:0,0?q=$coordinates';
    }
    return 'https://maps.apple.com/?ll=$coordinates';
  }

  Future<void> _showDeliveryOptions(String message, {String? mapAppUrl}) async {
    if (!mounted) {
      return;
    }

    final option = await showDialog<_SosDeliveryOption>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(appLocale.sosDeliveryOptionsTitle),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_SosDeliveryOption.app),
            child: _deliveryOption(Icons.share, appLocale.sosDeliveryChooseApp),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_SosDeliveryOption.contact),
            child: _deliveryOption(
              Icons.person,
              appLocale.sosDeliverySendToContact,
            ),
          ),
          if (mapAppUrl != null)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_SosDeliveryOption.map),
              child: _deliveryOption(
                Icons.map,
                appLocale.sosDeliveryOpenMapApp,
              ),
            ),
        ],
      ),
    );

    if (!mounted || option == null) {
      return;
    }
    switch (option) {
      case _SosDeliveryOption.app:
        await _shareText(message);
        return;
      case _SosDeliveryOption.contact:
        await _showContactPicker(message);
        return;
      case _SosDeliveryOption.map:
        if (mapAppUrl != null) {
          await launchWithFeedback(
            context,
            '',
            isCallFailure: false,
            launch: () => openSite(mapAppUrl),
          );
        }
        return;
    }
  }

  Widget _deliveryOption(IconData icon, String label) => Row(
    children: [
      Icon(icon),
      const SizedBox(width: 12),
      Expanded(child: Text(label)),
    ],
  );

  Future<void> _shareText(String message) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failedMessage = appLocale.sosShareLocationShareFailed;
    var succeeded = false;
    try {
      succeeded = await GetIt.instance<FileService>().shareTextOnly(message);
    } catch (error, stackTrace) {
      debugPrint('Could not share SOS content: $error\n$stackTrace');
    }

    if (!succeeded && mounted) {
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }

  Future<void> _showContactPicker(String message) async {
    final contacts = _savedContacts();
    if (contacts == null) {
      final shouldEdit = await _showContactsNeedAttentionDialog();
      if (shouldEdit && mounted) {
        await _openContactsEditor();
      }
      return;
    }
    if (contacts.isEmpty) {
      final shouldEdit = await _showNoContactsDialog();
      if (shouldEdit && mounted) {
        await _openContactsEditor();
      }
      return;
    }

    final contact = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(appLocale.sosDeliveryContactPickerTitle),
        children: contacts
            .map(
              (contact) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(contact),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(contact.key),
                  subtitle: Text(contact.value),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (contact == null || !mounted) {
      return;
    }
    await _showContactDeliveryOptions(contact, message);
  }

  List<MapEntry<String, String>>? _savedContacts() {
    final contacts = <MapEntry<String, String>>[];
    final names = widget.phonePageData.savedPhoneNames;
    final numbers = widget.phonePageData.savedPhoneNumbers;
    if (names.length != numbers.length) {
      return null;
    }
    for (var index = 0; index < names.length; index++) {
      final name = names[index].trim();
      final number = numbers[index].trim();
      if (name.isNotEmpty && number.isNotEmpty) {
        contacts.add(MapEntry(name, number));
      }
    }
    return contacts;
  }

  Future<void> _showContactDeliveryOptions(
    MapEntry<String, String> contact,
    String message,
  ) async {
    final option = await showDialog<_SosContactDeliveryOption>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(appLocale.sosDeliveryMethodTitle(contact.key)),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_SosContactDeliveryOption.sms),
            child: _deliveryOption(Icons.sms, appLocale.sosDeliverySms),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_SosContactDeliveryOption.whatsApp),
            child: _deliveryOption(Icons.chat, appLocale.whatsApp),
          ),
        ],
      ),
    );

    if (option == null || !mounted) {
      return;
    }
    if (option == _SosContactDeliveryOption.sms) {
      final smsNumber = _smsNumber(contact.value);
      if (smsNumber == null) {
        final shouldEdit = await _showContactsNeedAttentionDialog();
        if (shouldEdit && mounted) {
          await _openContactsEditor();
        }
        return;
      }
      await launchWithFeedback(
        context,
        smsNumber,
        isCallFailure: false,
        launch: () => openTextMessage(smsNumber, body: message),
      );
      return;
    }

    final whatsAppNumber = _whatsAppNumber(contact.value);
    if (whatsAppNumber == null) {
      final shouldEdit = await _showWhatsAppNumberDialog();
      if (shouldEdit && mounted) {
        await _openContactsEditor();
      }
      return;
    }
    await launchWithFeedback(
      context,
      contact.value,
      isCallFailure: false,
      launch: () => openWhatsApp(whatsAppNumber, body: message),
    );
  }

  String? _smsNumber(String number) => _canonicalPersonalContactNumber(
    number,
    Provider.of<UserInformation>(context, listen: false),
  );

  String? _canonicalPersonalContactNumber(
    String number,
    UserInformation userInformation,
  ) {
    final profileCountryCode = userInformation.location.trim().toUpperCase();
    final countryCode = countryPickerCodes.contains(profileCountryCode)
        ? profileCountryCode
        : defaultPickerCountry.countryCodes.first;
    return PhonePageData.canonicalizePhoneNumber(
      number,
      CountryCode.tryFromCountryCode(countryCode)?.dialCode,
    );
  }

  String? _whatsAppNumber(String number) {
    final normalized = PhonePageData.normalizeDialablePhoneNumber(number);
    if (normalized == null) {
      return null;
    }

    final internationalNumber = normalized.startsWith('00')
        ? '+${normalized.substring(2)}'
        : normalized;
    if (internationalNumber.startsWith('+')) {
      return _internationalWhatsAppNumber(internationalNumber);
    }

    final countryCode = Provider.of<UserInformation>(
      context,
      listen: false,
    ).location.trim().toUpperCase();
    if (!countryPickerCodes.contains(countryCode)) {
      return null;
    }
    final dialCode = CountryCode.tryFromCountryCode(countryCode)?.dialCode;
    if (dialCode == null) {
      return null;
    }
    final localNumber = internationalNumber.startsWith('0')
        ? internationalNumber.substring(1)
        : internationalNumber;
    return _internationalWhatsAppNumber('$dialCode$localNumber');
  }

  String? _internationalWhatsAppNumber(String number) {
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
      return null;
    }
    return number.substring(1);
  }

  Future<bool> _showNoContactsDialog() =>
      _showEditContactsDialog(appLocale.sosDeliveryNoContactsMessage);

  Future<bool> _showWhatsAppNumberDialog() =>
      _showEditContactsDialog(appLocale.sosDeliveryWhatsAppInternationalNumber);

  Future<bool> _showContactsNeedAttentionDialog() =>
      _showEditContactsDialog(appLocale.sosDeliveryContactsNeedAttention);

  Future<bool> _showEditContactsDialog(String message) =>
      _showMessageDialog(message, appLocale.sosDeliveryEditContacts);

  Future<bool> _showLocationFailureDialog(String message) =>
      _showMessageDialog(message, appLocale.asyncRetryButton);

  Future<bool> _showMessageDialog(String message, String actionLabel) async {
    final gender = Provider.of<UserInformation>(context, listen: false).gender;
    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(appLocale.closeButton(gender)),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(actionLabel),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<void> _openContactsEditor() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => ChangeNotifierProvider<PhonePageData>.value(
          value: widget.phonePageData,
          child: PhonePageForm(
            phonePageData: widget.phonePageData,
            next: () => Navigator.of(context).pop(),
            prev: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Widget _sosAction({
    required Key key,
    required String label,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      KeyedSubtree(
        key: key,
        child: circularActionButton(
          context,
          tooltip: tooltip,
          icon: icon,
          onTap: onTap,
        ),
      ),
      const SizedBox(height: 4.0),
      myAutoSizedText(
        label,
        TextStyle(fontWeight: FontWeight.normal, fontSize: 18.sp),
        TextAlign.center,
        18,
        2,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    final gender = userInfoProvider.gender;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.05,
          left: MediaQuery.of(context).size.width * 0.05,
          right: MediaQuery.of(context).size.width * 0.05,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100.0),
            child: Center(
              // Replaced Expanded with Center
              child: Column(
                children: <Widget>[
                  myAutoSizedText(
                    appLocale.phonePageTitle(gender),
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp),
                    TextAlign.center,
                    60,
                  ),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ExpansionTile(
                      leading: Tooltip(
                        message: appLocale.phoneContactDisclaimerMoreTooltip,
                        child: Icon(
                          Icons.info_outline,
                          size: 20.sp,
                          semanticLabel:
                              appLocale.phoneContactDisclaimerMoreTooltip,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: myAutoSizedText(
                        appLocale.phoneContactDisclaimerSummary,
                        TextStyle(fontSize: 12.sp, height: 1.4),
                        TextAlign.start,
                        20,
                        2,
                      ),
                      children: [
                        myAutoSizedText(
                          appLocale.addingContactDisclaimer,
                          TextStyle(fontSize: 12.sp, height: 1.5),
                          TextAlign.start,
                          40,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: myAutoSizedText(
                              appLocale.yourContacts(gender),
                              TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.normal,
                              ),
                              null,
                              30,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('phonePageManageContactsButton'),
                          tooltip: appLocale.addFormEdit(gender),
                          onPressed: _openContactsEditor,
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10.0),
                  //list of phones added in form Phone Page:
                  Consumer<PhonePageData>(
                    builder: (context, phonePageData, child) {
                      final contactCount =
                          phonePageData.savedPhoneNumbers.length <
                              phonePageData.savedPhoneNames.length
                          ? phonePageData.savedPhoneNumbers.length
                          : phonePageData.savedPhoneNames.length;

                      return Column(
                        children: List.generate(contactCount, (index) {
                          final number = phonePageData.savedPhoneNumbers[index];
                          final canonicalNumber =
                              _canonicalPersonalContactNumber(
                                number,
                                userInfoProvider,
                              );
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 10.0,
                            ), // adjust as needed
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30.0,
                              ), // adjust as needed
                              child: phoneContact(
                                number,
                                phonePageData.savedPhoneNames[index],
                                launch: canonicalNumber == null
                                    ? () async => false
                                    : () => dialPhone(canonicalNumber),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _sosAction(
                            key: const Key('phonePageShareLocationButton'),
                            label: appLocale.sosShareLocation,
                            tooltip: appLocale.sosShareLocationTooltip,
                            icon: Icons.location_on,
                            onTap: () {
                              _startLocationDelivery();
                            },
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: _sosAction(
                            key: const Key('phonePageShareMessageButton'),
                            label: appLocale.sosShareMessage,
                            tooltip: appLocale.sosShareMessageTooltip,
                            icon: Icons.message,
                            onTap: () {
                              _startMessageDelivery();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Align(
                    alignment: appLocale.textDirection == "rtl"
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 30.0,
                      ), // adjust the value as needed
                      child: myAutoSizedText(
                        appLocale.emergencyNumbers(gender),
                        TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.normal,
                        ),
                        null,
                        30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  //emergency phones grid: (police/105/etc..)
                  EmergencyPhonesGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
