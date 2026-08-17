import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/pages/FeelGood/FeelGoodInheritedWidget.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/l10n/app_localizations.dart';

void _focusOnPicture(
  BuildContext context,
  Widget Function(String path, {BoxFit fit}) displayImage,
  String imagePath,
  int index,
  Function(int index) deleteImageFunction,
  Function(int index) rotateImageFunction,
  int Function(String path) getImageRotationFunction,
  AppLocalizations? appLocale,
  String gender,
  List<String> imagePaths,
) {
  if (appLocale == null) return;
  AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
  mixPanelService.trackEvent("Photo looked at");
  final controller = PageController(initialPage: index);
  int lastPageReported = index;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog.fullscreen(
        child: PageView.builder(
          controller: controller,
          itemCount: imagePaths.length,
          padEnds: false,
          onPageChanged: (page) {
            if (page != lastPageReported) {
              lastPageReported = page;
              mixPanelService.trackEvent("Photo looked at");
            }
          },
          itemBuilder: (context, pageIndex) {
            final currentPath = imagePaths[pageIndex];
            final rotation = getImageRotationFunction(currentPath);
            return Column(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RotatedBox(
                      quarterTurns: rotation,
                      child: displayImage(
                        currentPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      key: const Key('backButtonIcon'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Tooltip(
                        message: appLocale.feelGoodBackTooltip,
                        child: const Icon(Icons.arrow_back),
                      ),
                    ),
                    TextButton(
                      key: const Key('rotateButtonIcon'),
                      onPressed: () {
                        rotateImageFunction(pageIndex);
                        setDialogState(() {});
                      },
                      child: Tooltip(
                        message: appLocale.feelGoodRotateTooltip,
                        child: const Icon(Icons.rotate_right),
                      ),
                    ),
                    TextButton(
                      key: const Key('downloadButtonIcon'),
                      onPressed: () async {
                        final pickerService =
                            GetIt.instance<ImagePickerService>();
                        final result = await pickerService.downloadImage(
                          currentPath,
                          dialogTitle: appLocale.feelGoodDownloadTooltip,
                        );
                        if (result != null) {
                          showToast(
                            message: appLocale.finishedDownloading(gender),
                          );
                        } else {
                          showToast(
                            message: appLocale.downloadFailed(gender),
                          );
                        }
                      },
                      child: Tooltip(
                        message: appLocale.feelGoodDownloadTooltip,
                        child: const Icon(Icons.download),
                      ),
                    ),
                    TextButton(
                      key: const Key('deleteButtonIcon'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(appLocale.feelGoodDeleteTitle),
                            content: Text(appLocale.feelGoodDeleteMessage),
                            actions: [
                              TextButton(
                                child: Text(appLocale.closeButton(gender)),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                key: const Key('deleteButtonText'),
                                child: Text(appLocale.deleteButton(gender)),
                                onPressed: () {
                                  deleteImageFunction(pageIndex); // Delete image
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Tooltip(
                        message: appLocale.feelGoodDeleteTooltip,
                        child: const Icon(Icons.delete),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class ImageDisplay extends StatelessWidget {
  final String imagePath;
  final int index;
  final List<String> imagePaths;

  const ImageDisplay({
    super.key,
    required this.imagePath,
    required this.index,
    required this.imagePaths,
  });
  @override
  Widget build(BuildContext context) {
    final inherited = FeelGoodInheritedWidget.of(context);
    final Widget Function(String path, {BoxFit fit}) displayImage =
        inherited?.displayImage ??
        (String path, {BoxFit fit = BoxFit.none}) => const SizedBox.shrink();

    final appLocale = AppLocalizations.of(context);
    final UserInformation userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    final Function(int index) deleteImageFunction =
        inherited?.deleteImage ?? (int index) {};
    final Function(int index) rotateImageFunction =
        inherited?.rotateImage ?? (int index) {};
    final int Function(String path) getImageRotationFunction =
        inherited?.getImageRotation ?? (String path) => 0;

    final rotation = getImageRotationFunction(imagePath);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _focusOnPicture(
          context,
          displayImage,
          imagePath,
          index,
          deleteImageFunction,
          rotateImageFunction,
          getImageRotationFunction,
          appLocale,
          gender,
          imagePaths,
        );
      },
      //actual image displayed when clicked on image in above grid:
      child: RotatedBox(
        quarterTurns: rotation,
        child: displayImage(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
