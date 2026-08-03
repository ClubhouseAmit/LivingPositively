import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:mazilon/util/horizontal_logo.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/WellnessTools/more_videos_item.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/userInformation.dart';

class WellnessTools extends StatefulWidget {
  const WellnessTools({
    required this.isFullScreen, required this.setBool, required this.videoData, super.key,
  });
  final Function setBool;
  final bool isFullScreen;
  final Map<String, List<String>> videoData;

  @override
  State<WellnessTools> createState() => _WellnessToolsState();
}

class _WellnessToolsState extends LPExtendedState<WellnessTools> {
  bool isFullScreen = false;
  int selectedVideoIdIndex = 0;
  String selectedVideoId = '';
  final ImagePickerService imageService = GetIt.instance<ImagePickerService>();
  final VideoPlayerPageFactory _videoPlayerPageFactory =
      GetIt.instance<VideoPlayerPageFactory>();

  String? _youtubeId(String videoId) {
    final trimmed = videoId.trim();
    final fromUrl = YoutubePlayer.convertUrlToId(trimmed);
    if (fromUrl != null && fromUrl.isNotEmpty) {
      return fromUrl;
    }
    if (trimmed.length < 11) {
      return null;
    }
    return trimmed.substring(0, 11);
  }

  String getThumbnailUrl(String videoId) {
    final trimmedVideoId = _youtubeId(videoId);
    return 'https://img.youtube.com/vi/$trimmedVideoId/0.jpg';
  }

  bool _hasUsableVideoData() {
    final ids = widget.videoData['videoId'];
    final headlines = widget.videoData['videoHeadline'];
    final descriptions = widget.videoData['videoDescription'];
    if (ids == null ||
        headlines == null ||
        descriptions == null ||
        ids.isEmpty) {
      return false;
    }
    if (ids.length != headlines.length || ids.length != descriptions.length) {
      return false;
    }
    return ids.every((id) => _youtubeId(id) != null);
  }

  List<int> _moreVideoIndexes(int selectedIndex) {
    return List<int>.generate(
      widget.videoData['videoId']!.length,
      (index) => index,
    ).where((index) => index != selectedIndex).toList();
  }

  Widget _videoDataFallback() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: Text(
          appLocale.wellnessVideoDataUnavailableMessage,
          style: TextStyle(fontSize: 18.sp),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _transcript(String? text) {
    final transcript = text?.trim() ?? '';
    if (transcript.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 0, Spacing.xs, Spacing.md),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          appLocale.wellnessTranscriptTitle,
          
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              transcript,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 16.sp,
                height: 1.5,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void setIsFullScreen(bool isFullScreen) {
    setState(() {
      this.isFullScreen = isFullScreen;
    });
    widget.setBool(isFullScreen);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void changeVideo(String newVideoId) {
    setState(() {
      selectedVideoId = newVideoId;
    });
    debugPrint('Video changed to: $newVideoId');
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasUsableVideoData()) {
      return _videoDataFallback();
    }
    final videoIds = widget.videoData['videoId']!;
    final selectedIndex = selectedVideoIdIndex < videoIds.length
        ? selectedVideoIdIndex
        : 0;
    final transcript = widget.videoData['videoTranscript'];
    final moreVideoIndexes = _moreVideoIndexes(selectedIndex);
    final gender = Provider.of<UserInformation>(context, listen: false).gender;

    final playerWidget = _videoPlayerPageFactory.create(
      onFullScreenChanged: setIsFullScreen,
      videoData: widget.videoData,
    );

    if (isFullScreen) {
      return VideoPlayerInheritedWidget(
        videoId: selectedVideoId.isNotEmpty
            ? selectedVideoId
            : _youtubeId(videoIds[selectedIndex])!,
        changeVideo: changeVideo,
        child: Scaffold(
          body: playerWidget,
        ),
      );
    }

    return VideoPlayerInheritedWidget(
      videoId: selectedVideoId.isNotEmpty
          ? selectedVideoId
          : _youtubeId(videoIds[selectedIndex])!,
      changeVideo: changeVideo,
      child: PageLayoutWrapper(
        sliverAppBar: PremiumGlassAppBar(
          variant: AppBarVariant.rootTab,
          titleText: appLocale.homePageWellnessTools(gender),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Spacing.md),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: playerWidget,
            ),
            SizedBox(height: Spacing.sm),
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: AutoSizeText(
                  widget.videoData['videoHeadline']![selectedIndex],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: AutoSizeText(
                widget.videoData['videoDescription']![selectedIndex],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 5,
              ),
            ),
            _transcript(
              transcript != null && selectedIndex < transcript.length
                  ? transcript[selectedIndex]
                  : null,
            ),
            const SizedBox(height: Spacing.md),
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: AutoSizeText(
                  appLocale.moreVideos,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: Spacing.bottomPadding),
              itemCount: moreVideoIndexes.length,
              separatorBuilder: (context, _) => SizedBox(height: Spacing.md),
              itemBuilder: (context, index) {
                final videoIndex = moreVideoIndexes[index];
                final videoId = widget.videoData['videoId']![videoIndex];
                final thumbnailUrl = getThumbnailUrl(videoId);
                return MoreVideosItem(
                  videoData: widget.videoData,
                  index: videoIndex,
                  thumbnailUrl: thumbnailUrl,
                  changeVideoIdIndex: () {
                    return () {
                      setState(() {
                        selectedVideoIdIndex = videoIndex;
                        selectedVideoId = _youtubeId(
                          widget.videoData['videoId']![selectedVideoIdIndex],
                        )!;
                        VideoPlayerInheritedWidget.of(context)?.changeVideo(selectedVideoId);
                      });
                    };
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
