import 'dart:async';

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
  late YoutubePlayerController controller;
  StreamSubscription<YoutubePlayerValue>? _controllerSubscription;
  bool _controllerInitialized = false;
  bool _initializationAttempted = false;
  bool _hasInitialVideo = false;
  bool? _isPlaying;
  String? _loadedVideoId;

  @override
  void initState() {
    super.initState();
  }

  void _initializeController() {
    _initializationAttempted = true;
    final videoIds = widget.videoData['videoId'];
    final initialVideoId = videoIds != null && videoIds.isNotEmpty
        ? _youtubeId(videoIds.first)
        : null;
    _hasInitialVideo = initialVideoId != null;
    if (initialVideoId == null) {
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    controller = YoutubePlayerController.fromVideoId(
      videoId: initialVideoId,
      autoPlay: false,
      params: YoutubePlayerParams(
        enableCaption: true,
        captionLanguage: languageCode,
        interfaceLanguage: languageCode,
      ),
    );

    controller.setFullScreenListener(widget.onFullScreenChanged);
    _controllerSubscription = controller.stream.listen(_trackIsPlaying);
    _loadedVideoId = initialVideoId;
    _controllerInitialized = true;
  }

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

  void _trackIsPlaying(YoutubePlayerValue value) {
    final isPlaying = switch (value.playerState) {
      PlayerState.playing => true,
      PlayerState.paused => false,
      _ => null,
    };
    if (isPlaying != null && _isPlaying != isPlaying) {
      _isPlaying = isPlaying;
      _logEvent(isPlaying, value.metaData.title, value.metaData.videoId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializationAttempted) {
      _initializeController();
    }
    if (!_controllerInitialized) {
      return;
    }
    // Update the video when the inherited widget provides a new videoId
    final newVideoId = VideoPlayerInheritedWidget.of(context)?.videoId ?? '';
    final normalizedVideoId = _youtubeId(newVideoId);
    if (normalizedVideoId != null && normalizedVideoId != _loadedVideoId) {
      _loadedVideoId = normalizedVideoId;
      unawaited(controller.loadVideoById(videoId: normalizedVideoId));
    }
  }

  @override
  void dispose() {
    if (!_controllerInitialized) {
      super.dispose();
      return;
    }
    unawaited(_controllerSubscription?.cancel());
    unawaited(controller.close());
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
    if (!_hasInitialVideo) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.wellnessVideoUnavailableMessage,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!_controllerInitialized || !_initializationAttempted) {
      return const SizedBox.shrink();
    }
    debugPrint(controller.metadata.videoId);
    return YoutubePlayer(controller: controller);
  }
}
