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
  final VoidCallback Function() changeVideoIdIndex;

  const MoreVideosItem({
    super.key,
    required this.videoData,
    required this.index,
    required this.thumbnailUrl,
    required this.changeVideoIdIndex,
  });

  @override
  Widget build(BuildContext context) {
    final ImagePickerService imageService =
        GetIt.instance<ImagePickerService>();
    final appLocale = AppLocalizations.of(context);
    final title = videoData['videoHeadline']?[index] ?? '';
    final onSelected = changeVideoIdIndex();
    return SizedBox(
      height: 100,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          child: Tooltip(
            message: title,
            child: Semantics(
              button: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: imageService.getOnlineImage(thumbnailUrl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: myAutoSizedText(
                      title,
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.normal),
                      appLocale!.textDirection == "rtl"
                          ? TextAlign.right
                          : TextAlign.left,
                      20,
                      2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
