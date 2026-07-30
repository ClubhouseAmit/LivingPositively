import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
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
  bool _isSharingLocation = false;

  bool get _supportsLocationSharing =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _shareCurrentLocation() async {
    if (_isSharingLocation) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    final fileService = GetIt.instance<FileService>();
    final helpMessage = appLocale.sosShareLocationMessage;
    final unavailableMessage = appLocale.sosShareLocationUnavailable;
    final shareErrorMessage = appLocale.asyncErrorMessage;
    var messageToShare = helpMessage;
    var locationUnavailable = !_supportsLocationSharing;

    setState(() {
      _isSharingLocation = true;
    });

    try {
      if (!locationUnavailable) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          locationUnavailable = true;
        } else {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              ),
            );
            messageToShare =
                '$helpMessage\nhttps://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
          } else {
            locationUnavailable = true;
          }
        }
      }
    } catch (_) {
      locationUnavailable = true;
    }

    if (locationUnavailable && mounted) {
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(unavailableMessage)));
    }

    try {
      await fileService.shareTextOnly(messageToShare);
    } catch (_) {
      if (mounted) {
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(SnackBar(content: Text(shareErrorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingLocation = false;
        });
      }
    }
  }

  void _openContactsEditor() {
    Navigator.of(context).push(
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
                        children: List.generate(
                          contactCount,
                          (index) => Container(
                            margin: const EdgeInsets.only(
                              bottom: 10.0,
                            ), // adjust as needed
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30.0,
                              ), // adjust as needed
                              child: phoneContact(
                                phonePageData.savedPhoneNumbers[index],
                                phonePageData.savedPhoneNames[index],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: myText(
                            appLocale.sosShareLocation,
                            TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 20.sp,
                            ),
                            null,
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        KeyedSubtree(
                          key: const Key('phonePageShareLocationButton'),
                          child: circularActionButton(
                            context,
                            tooltip: appLocale.sosShareLocationTooltip,
                            icon: Icons.location_on,
                            onTap: _shareCurrentLocation,
                          ),
                        ),
                        const SizedBox(width: 10.0),
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
