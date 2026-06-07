import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/pages/FeelGood/FeelGoodInheritedWidget.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/l10n/app_localizations.dart';

void _focusOnPicture(
  context,
  displayImage,
  imagePath,
  index,
  deleteImageFunction,
  appLocale,
  gender,
  imagePaths,
) {
  AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
  mixPanelService.trackEvent("Photo looked at");
  final controller = PageController(initialPage: index);
  int lastPageReported = index;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog.fullscreen(
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
          return Column(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: displayImage(
                    imagePaths[pageIndex],
                    fit: BoxFit.contain,
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
                      message: appLocale!.feelGoodBackTooltip,
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  TextButton(
                    key: const Key('deleteButtonIcon'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(appLocale!.feelGoodDeleteTitle),
                          content: Text(appLocale!.feelGoodDeleteMessage),
                          actions: [
                            TextButton(
                              child: Text(appLocale!.closeButton(gender)),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              key: const Key('deleteButtonText'),
                              child: Text(appLocale!.deleteButton(gender)),
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
                      message: appLocale!.feelGoodDeleteTooltip,
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
    final Function(String path, {BoxFit fit}) displayImage =
        FeelGoodInheritedWidget.of(context)?.displayImage ??
        (String path, {BoxFit fit = BoxFit.none}) {};

    final appLocale = AppLocalizations.of(context);
    final UserInformation userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    final Function(int index) deleteImageFunction =
        FeelGoodInheritedWidget.of(context)?.deleteImage ?? (int index) {};
    return GestureDetector(
      onTap: () {
        _focusOnPicture(
          context,
          displayImage,
          imagePath,
          index,
          deleteImageFunction,
          appLocale,
          gender,
          imagePaths,
        );
      },
      //actual image displayed when clicked on image in above grid:
      child: displayImage(imagePath, fit: BoxFit.cover),
    );
  }
}
