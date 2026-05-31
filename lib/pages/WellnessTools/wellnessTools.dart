import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/WellnessTools/more_videos_item.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';

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

  String getThumbnailUrl(String videoId) {
    var trimmedVideoId = videoId.substring(0, 11);
    return 'https://img.youtube.com/vi/$trimmedVideoId/0.jpg';
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
    if (widget.videoData['videoId']!.isEmpty) {
      return Center(
        child: Text(
          appLocale.noVideosAvailableForLocale,
          style: TextStyle(fontSize: 18.sp),
        ),
      );
    }
    return VideoPlayerInheritedWidget(
      videoId: selectedVideoId,
      changeVideo: changeVideo,
      child: SafeArea(
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: !isFullScreen,
                child: Center(
                  child: SizedBox(
                    //color: Colors.white,
                    height: 130.0,
                    //margin: EdgeInsets.only(top: 15),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      width: MediaQuery.sizeOf(context).width * 0.4 > 1000
                          ? 500
                          : MediaQuery.sizeOf(
                              context,
                            ).width, // Adjust as needed
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: !isFullScreen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 10.0, 8, 10),
                  child: myAutoSizedText(
                    widget.videoData['videoHeadline']![selectedVideoIdIndex],
                    TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                    appLocale.textDirection == "rtl"
                        ? TextAlign.right
                        : TextAlign.left,
                    28,
                    3,
                  ),
                ),
              ),
              Expanded(
                child: _videoPlayerPageFactory.create(
                  onFullScreenChanged: setIsFullScreen,
                  videoData: widget.videoData,
                ),
              ),
              SizedBox(height: 10),
              Visibility(
                visible: !isFullScreen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4.0, 4, 20),
                  child: myAutoSizedText(
                    widget.videoData['videoDescription']![selectedVideoIdIndex],
                    TextStyle(fontSize: 18.sp, fontWeight: FontWeight.normal),
                    appLocale.textDirection == "rtl"
                        ? TextAlign.right
                        : TextAlign.left,
                    20,
                    3,
                  ),
                ),
              ),
              Visibility(
                visible: !isFullScreen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4.0, 4, 20),
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
              Visibility(
                visible: !isFullScreen,
                child: Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      if (index == selectedVideoIdIndex) {
                        return Container();
                      }
                      var videoId = widget.videoData['videoId']![index];
                      var thumbnailUrl = getThumbnailUrl(videoId);
                      return MoreVideosItem(
                        videoData: widget.videoData,
                        index: index,
                        thumbnailUrl: thumbnailUrl,
                        changeVidoeIdIndex: () {
                          return () {
                            setState(() {
                              selectedVideoIdIndex = index;
                              VideoPlayerInheritedWidget.of(
                                context,
                              )?.changeVideo(
                                widget
                                    .videoData['videoId']![selectedVideoIdIndex],
                              );
                            });
                          };
                        },
                      );
                    },
                    itemCount: widget.videoData['videoId']!.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 10.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
