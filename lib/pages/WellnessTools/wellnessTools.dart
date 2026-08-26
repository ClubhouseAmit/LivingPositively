import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/WellnessTools/more_videos_item.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
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
  static const _videoAspectRatio = 16 / 9;
  static const _videoVerticalPadding = 8.0;
  static const _maximumPinnedPlayerHeightFactor = 0.55;

  var isFullScreen = false;
  var selectedVideoIdIndex = 0;
  var selectedVideoId = '';
  final ScrollController _scrollController = ScrollController();
  final VideoPlayerPageFactory _videoPlayerPageFactory =
      GetIt.instance<VideoPlayerPageFactory>();

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

  String getThumbnailUrl(String videoId) =>
      'https://img.youtube.com/vi/${_youtubeId(videoId)}/0.jpg';

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

  void _selectVideo(int videoIndex) {
    final videoId = _youtubeId(widget.videoData['videoId']![videoIndex])!;
    setState(() {
      selectedVideoIdIndex = videoIndex;
      selectedVideoId = videoId;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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

    return VideoPlayerInheritedWidget(
      videoId: selectedVideoId.isNotEmpty
          ? selectedVideoId
          : _youtubeId(videoIds[selectedIndex])!,
      changeVideo: changeVideo,
      child: SafeArea(
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                key: const Key('wellnessToolsScrollView'),
                controller: _scrollController,
                slivers: [
                  SliverVisibility(
                    visible: !isFullScreen,
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SizedBox(
                              height: 130.0,
                              child: Image.asset(
                                'assets/images/Logo.png',
                                width:
                                    MediaQuery.sizeOf(context).width * 0.4 >
                                        1000
                                    ? 500
                                    : MediaQuery.sizeOf(context).width,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              8.0,
                              10.0,
                              8,
                              10,
                            ),
                            child: myAutoSizedText(
                              widget.videoData['videoHeadline']![selectedIndex],
                              TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              appLocale.textDirection == "rtl"
                                  ? TextAlign.right
                                  : TextAlign.left,
                              28,
                              3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PinnedHeaderSliver(
                    child: SizedBox(
                      height: isFullScreen
                          ? constraints.maxHeight
                          : math.min(
                              constraints.maxWidth / _videoAspectRatio +
                                  _videoVerticalPadding * 2,
                              constraints.maxHeight *
                                  _maximumPinnedPlayerHeightFactor,
                            ),
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: isFullScreen
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(
                                  vertical: _videoVerticalPadding,
                                ),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: _videoAspectRatio,
                              child: _videoPlayerPageFactory.create(
                                onFullScreenChanged: setIsFullScreen,
                                videoData: widget.videoData,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isFullScreen)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4.0, 4, 20),
                            child: myAutoSizedText(
                              widget
                                  .videoData['videoDescription']![selectedIndex],
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
                          _transcript(
                            transcript != null &&
                                    selectedIndex < transcript.length
                                ? transcript[selectedIndex]
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4.0, 4, 20),
                            child: myAutoSizedText(
                              appLocale.moreVideos,
                              TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              appLocale.textDirection == "rtl"
                                  ? TextAlign.right
                                  : TextAlign.left,
                              20,
                              3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isFullScreen)
                    SliverList.separated(
                      itemCount: moreVideoIndexes.length,
                      itemBuilder: (context, index) {
                        final videoIndex = moreVideoIndexes[index];
                        return MoreVideosItem(
                          videoData: widget.videoData,
                          index: videoIndex,
                          thumbnailUrl: getThumbnailUrl(
                            widget.videoData['videoId']![videoIndex],
                          ),
                          changeVideoIdIndex: () {
                            return () => _selectVideo(videoIndex);
                          },
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
