import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/WellnessTools/more_videos_item.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class WellnessTools extends StatefulWidget {
  final Function setBool;
  final bool isFullScreen;
  final Map<String, List<String>> videoData;
  const WellnessTools({
    super.key,
    required this.isFullScreen,
    required this.setBool,
    required this.videoData,
  });

  @override
  State<WellnessTools> createState() => _WellnessToolsState();
}

class _WellnessToolsState extends LPExtendedState<WellnessTools> {
  var isFullScreen = false;
  var selectedVideoIdIndex = 0;
  var selectedVideoId = '';
  final ImagePickerService imageService = GetIt.instance<ImagePickerService>();
  final VideoPlayerPageFactory _videoPlayerPageFactory =
      GetIt.instance<VideoPlayerPageFactory>();
  final ScrollController _scrollController = ScrollController();

  String? _youtubeId(String videoId) {
    final trimmed = videoId.trim();
    final fromUrl = YoutubePlayerController.convertUrlToId(trimmed);
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
        padding: const EdgeInsets.all(24),
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
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 12),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          appLocale.wellnessTranscriptTitle,
          textAlign: appLocale.textDirection == "rtl"
              ? TextAlign.right
              : TextAlign.left,
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
    isFullScreen = widget.isFullScreen;
  }

  @override
  void didUpdateWidget(covariant WellnessTools oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFullScreen != widget.isFullScreen) {
      isFullScreen = widget.isFullScreen;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final moreVideosChildCount = moreVideoIndexes.isEmpty
        ? 0
        : moreVideoIndexes.length * 2 - 1;

    return VideoPlayerInheritedWidget(
      videoId: selectedVideoId.isNotEmpty
          ? selectedVideoId
          : _youtubeId(videoIds[selectedIndex])!,
      changeVideo: changeVideo,
      child: SafeArea(
        child: Scaffold(
          body: Scrollbar(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                if (!isFullScreen) ...[
                  SliverToBoxAdapter(
                    child: Center(
                      child: SizedBox(
                        height: 130.0,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          width: MediaQuery.sizeOf(context).width * 0.4 > 1000
                              ? 500
                              : MediaQuery.sizeOf(context).width,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        10.0,
                        AppSpacing.sm,
                        10.0,
                      ),
                      child: myAutoSizedText(
                        widget.videoData['videoHeadline']![selectedIndex],
                        TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                        appLocale.textDirection == "rtl"
                            ? TextAlign.right
                            : TextAlign.left,
                        28,
                        3,
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _videoPlayerPageFactory.create(
                      onFullScreenChanged: setIsFullScreen,
                      videoData: widget.videoData,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                if (!isFullScreen) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.xs,
                        AppSpacing.xs,
                        AppSpacing.xl,
                      ),
                      child: myAutoSizedText(
                        widget.videoData['videoDescription']![selectedIndex],
                        TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.normal,
                        ),
                        appLocale.textDirection == "rtl"
                            ? TextAlign.right
                            : TextAlign.left,
                        20,
                        3,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _transcript(
                      transcript != null && selectedIndex < transcript.length
                          ? transcript[selectedIndex]
                          : null,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.xs,
                        AppSpacing.xs,
                        AppSpacing.xl,
                      ),
                      child: myAutoSizedText(
                        appLocale.moreVideos,
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        appLocale.textDirection == "rtl"
                            ? TextAlign.right
                            : TextAlign.left,
                        20,
                        3,
                      ),
                    ),
                  ),
                  if (moreVideosChildCount > 0)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index.isOdd) {
                          return const SizedBox(height: 10.0);
                        }
                        final videoIndex = moreVideoIndexes[index ~/ 2];
                        final videoId =
                            widget.videoData['videoId']![videoIndex];
                        final thumbnailUrl = getThumbnailUrl(videoId);
                        return MoreVideosItem(
                          key: ValueKey(videoId),
                          videoData: widget.videoData,
                          index: videoIndex,
                          thumbnailUrl: thumbnailUrl,
                          changeVideoIdIndex: () {
                            return () {
                              setState(() {
                                selectedVideoIdIndex = videoIndex;
                                selectedVideoId = _youtubeId(
                                  widget
                                      .videoData['videoId']![selectedVideoIdIndex],
                                )!;
                                VideoPlayerInheritedWidget.of(
                                  context,
                                )?.changeVideo(selectedVideoId);
                              });
                            };
                          },
                        );
                      }, childCount: moreVideosChildCount),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
