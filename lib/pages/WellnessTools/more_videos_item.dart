import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';

class MoreVideosItem extends StatelessWidget {

  const MoreVideosItem({
    required this.videoData, required this.index, required this.thumbnailUrl, required this.changeVideoIdIndex, super.key,
  });
  final Map<String, List<String>> videoData;
  final int index;
  final String thumbnailUrl;
  final VoidCallback Function() changeVideoIdIndex;

  @override
  Widget build(BuildContext context) {
    final imageService =
        GetIt.instance<ImagePickerService>();
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
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: imageService.getOnlineImage(thumbnailUrl),
                  ),
                  SizedBox(width: Spacing.md),
                  Expanded(
                    child: AutoSizeText(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                      
                      maxLines: 2,
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
