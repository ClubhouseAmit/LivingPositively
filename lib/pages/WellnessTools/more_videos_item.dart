import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';

import 'package:mazilon/util/styles.dart';
import 'package:mazilon/l10n/app_localizations.dart';

class MoreVideosItem extends StatelessWidget {
  final Map<String, List<String>> videoData;
  final int index;
  final String thumbnailUrl;
  final Function changeVidoeIdIndex;

  const MoreVideosItem({
    super.key,
    required this.videoData,
    required this.index,
    required this.thumbnailUrl,
    required this.changeVidoeIdIndex,
  });

  @override
  Widget build(BuildContext context) {
    final ImagePickerService imageService =
        GetIt.instance<ImagePickerService>();
    final appLocale = AppLocalizations.of(context);
    return SizedBox(
      width: 150,
      height: 100,
      child: GestureDetector(
        onTap: changeVidoeIdIndex(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: imageService.getOnlineImage(thumbnailUrl),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  myAutoSizedText(
                    videoData['videoHeadline']![index],
                    TextStyle(fontSize: 18.sp, fontWeight: FontWeight.normal),
                    appLocale!.textDirection == "rtl"
                        ? TextAlign.right
                        : TextAlign.left,
                    20,
                    2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
