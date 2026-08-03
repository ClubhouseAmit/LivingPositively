import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Phone/EmergencyPhones.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';

class PhonePage extends StatefulWidget {
  const PhonePage({
    required this.phonePageData,
    this.onBackPressed,
    super.key,
  });
  final PhonePageData phonePageData;
  final VoidCallback? onBackPressed;

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
    final shareFailedMessage = appLocale.sosShareLocationShareFailed;
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

          if (permission == LocationPermission.whileInUse) {
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
      final shareSucceeded = await fileService.shareTextOnly(messageToShare);
      if (!shareSucceeded && mounted) {
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(SnackBar(content: Text(shareFailedMessage)));
      }
    } catch (_) {
      if (mounted) {
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(SnackBar(content: Text(shareFailedMessage)));
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
    );

    final gender = userInfoProvider.gender;

    return PageLayoutWrapper(
      sliverAppBar: PremiumGlassAppBar(
        variant: AppBarVariant.detailScreen,
        onBackPressed: widget.onBackPressed,
        titleText: appLocale.phonePageTitle(gender),
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: Spacing.md),
            Text(
              appLocale.phonePageTitle(gender),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: Spacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AutoSizeText(
                        appLocale.yourContacts(gender),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.normal,
                            ),
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

            const SizedBox(height: 10),
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
                        bottom: 10,
                      ), // adjust as needed
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      appLocale.sosShareLocation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  KeyedSubtree(
                    key: const Key('phonePageShareLocationButton'),
                    child: circularActionButton(
                      context,
                      tooltip: appLocale.sosShareLocationTooltip,
                      icon: Icons.location_on,
                      onTap: _shareCurrentLocation,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AutoSizeText(
                  appLocale.emergencyNumbers(gender),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            //emergency phones grid: (police/105/etc..)
            const EmergencyPhonesGrid(),
          ],
        ),
    );
  }
}
