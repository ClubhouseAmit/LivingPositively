import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final Function(bool isFullScreen) onFullScreenChanged;
  final Map<String, List<String>> videoData;
  const VideoPlayerPage({
    super.key,
    required this.onFullScreenChanged,
    required this.videoData,
  });
  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VoidCallback listener;
  late YoutubePlayerController controller;
  bool _controllerInitialized = false;
  bool _hasInitialVideo = false;
  bool? _isPlaying;

  @override
  void initState() {
    super.initState();
  }

  void _initializeController() {
    final videoIds = widget.videoData['videoId'];
    final initialVideoId = videoIds != null && videoIds.isNotEmpty
        ? _youtubeId(videoIds.first)
        : null;
    _hasInitialVideo = initialVideoId != null;
    controller = YoutubePlayerController(
      initialVideoId: initialVideoId ?? '',
      flags: YoutubePlayerFlags(
        autoPlay: false,
        enableCaption: true,
        captionLanguage: Localizations.localeOf(context).languageCode,
      ),
    );

    listener = () {
      widget.onFullScreenChanged(controller.value.isFullScreen);
      _trackIsPlaying();
    };
    controller.addListener(listener);
    _controllerInitialized = true;
  }

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

  void _trackIsPlaying() {
    if (_isPlaying != controller.value.isPlaying) {
      _isPlaying = controller.value.isPlaying;
      _logEvent(
        _isPlaying!,
        controller.metadata.title,
        controller.metadata.videoId,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerInitialized) {
      _initializeController();
    }
    // Update the video when the inherited widget provides a new videoId
    final newVideoId = VideoPlayerInheritedWidget.of(context)?.videoId ?? '';
    final normalizedVideoId = _youtubeId(newVideoId);
    if (normalizedVideoId != null &&
        normalizedVideoId != controller.metadata.videoId) {
      controller.load(normalizedVideoId);
    }
  }

  @override
  void dispose() {
    if (!_controllerInitialized) {
      super.dispose();
      return;
    }
    controller.removeListener(listener);
    // CI run 26463427363 reproduced youtube_player_flutter#1143 on Android:
    // YoutubePlayerController.dispose() calls value.webViewController?.dispose()
    // after the child InAppWebView has already disposed the same platform
    // controller. Flutter unmounts children before State.dispose(), so the
    // YoutubePlayer widget listener is gone here; after removing our listener,
    // this reset only detaches the stale WebView reference before disposing
    // the ValueNotifier. Recheck when upgrading youtube_player_flutter.
    // https://github.com/sarbagyastha/youtube_player_flutter/issues/1143
    controller.updateValue(YoutubePlayerValue());
    controller.dispose();
    super.dispose();
  }

  void _logEvent(bool isPlaying, title, String url) {
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    debugPrint("logging");
    if (isPlaying) {
      mixPanelService.trackEvent("Video unpaused", {
        "title": title,
        "url": url,
      });
    } else {
      mixPanelService.trackEvent("Video paused", {"title": title, "url": url});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllerInitialized) {
      return const SizedBox.shrink();
    }
    if (!_hasInitialVideo) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.wellnessVideoUnavailableMessage,
          textAlign: TextAlign.center,
        ),
      );
    }
    debugPrint(controller.metadata.videoId);
    return YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: true,
      onReady: () {
        debugPrint('Player is ready.');
      },
    );
  }
}
