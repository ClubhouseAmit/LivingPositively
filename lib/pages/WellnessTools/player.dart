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
  bool _hasInitialVideo = false;
  bool? _isPlaying;
  String? _loadedVideoId;
  String? _requestedVideoId;
  String? _pendingVideoId;
  int? _pendingLoadRequest;
  int? _pendingLoadWithUnmatchedError;
  String? _retryableVideoId;
  int _nextLoadRequest = 0;

  @override
  void initState() {
    super.initState();
  }

  void _initializeController() {
    final inheritedVideoId = _youtubeId(
      VideoPlayerInheritedWidget.of(context)?.videoId ?? '',
    );
    final videoIds = widget.videoData['videoId'];
    final initialVideoId =
        inheritedVideoId ??
        (videoIds != null && videoIds.isNotEmpty
            ? _youtubeId(videoIds.first)
            : null);
    if (initialVideoId == null) {
      _hasInitialVideo = false;
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final newController = YoutubePlayerController(
      key: initialVideoId,
      params: YoutubePlayerParams(
        enableCaption: true,
        captionLanguage: languageCode,
        interfaceLanguage: languageCode,
      ),
    );

    newController.setFullScreenListener(widget.onFullScreenChanged);
    final subscription = newController.stream.listen(_trackIsPlaying);
    controller = newController;
    _controllerSubscription = subscription;
    _loadedVideoId = initialVideoId;
    _requestedVideoId = initialVideoId;
    _controllerInitialized = true;
    _hasInitialVideo = true;
    unawaited(_cueInitialVideo(newController, initialVideoId));
  }

  Future<void> _cueInitialVideo(
    YoutubePlayerController targetController,
    String videoId,
  ) async {
    try {
      await targetController.cueVideoById(videoId: videoId);
    } catch (_) {
      // `fromVideoId` leaves this iframe-ready future unobserved. Retain a
      // retryable selection when the player is unavailable instead.
      if (mounted &&
          identical(controller, targetController) &&
          _requestedVideoId == videoId) {
        _loadedVideoId = null;
        _retryableVideoId = videoId;
      }
    }
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
    if (value.hasError) {
      _handlePlayerError(value);
    }

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

  void _handlePlayerError(YoutubePlayerValue value) {
    final failedVideoId = _youtubeId(value.metaData.videoId);
    final pendingLoadRequest = _pendingLoadRequest;
    if (failedVideoId != null &&
        failedVideoId == _pendingVideoId &&
        pendingLoadRequest != null) {
      _retryableVideoId = failedVideoId;
      _clearPendingLoad(failedVideoId, pendingLoadRequest);
      return;
    }

    if (_pendingLoadRequest != null) {
      // Iframe errors include only an error code and retain the last metadata.
      // Do not cancel a newer request unless that metadata identifies it.
      _pendingLoadWithUnmatchedError = _pendingLoadRequest;
      return;
    }

    if (_requestedVideoId == _loadedVideoId) {
      if (failedVideoId == _loadedVideoId) {
        _loadedVideoId = null;
      }
      // Untagged or stale errors cannot safely clear the active ID. Remember
      // the requested selection so a later explicit selection can retry it.
      _retryableVideoId = _requestedVideoId;
    }
  }

  void _requestVideoLoad(String videoId) {
    _requestedVideoId = videoId;
    if (videoId == _pendingVideoId ||
        (videoId == _loadedVideoId && videoId != _retryableVideoId)) {
      return;
    }

    final request = ++_nextLoadRequest;
    if (_retryableVideoId == videoId) {
      _retryableVideoId = null;
    }
    _pendingLoadWithUnmatchedError = null;
    _pendingVideoId = videoId;
    _pendingLoadRequest = request;
    unawaited(_loadVideo(videoId, request));
  }

  Future<void> _loadVideo(String videoId, int request) async {
    try {
      await controller.loadVideoById(videoId: videoId);
      if (!mounted || !_isPendingLoad(videoId, request)) {
        return;
      }
      final sawUnmatchedError = _pendingLoadWithUnmatchedError == request;
      _loadedVideoId = videoId;
      _clearPendingLoad(videoId, request);
      if (sawUnmatchedError) {
        _retryableVideoId = videoId;
      }
    } catch (_) {
      if (mounted && _isPendingLoad(videoId, request)) {
        _retryableVideoId = videoId;
        _clearPendingLoad(videoId, request);
      }
    }
  }

  bool _isPendingLoad(String videoId, int request) {
    return _pendingVideoId == videoId && _pendingLoadRequest == request;
  }

  void _clearPendingLoad(String videoId, int request) {
    if (_isPendingLoad(videoId, request)) {
      _pendingVideoId = null;
      _pendingLoadRequest = null;
      if (_pendingLoadWithUnmatchedError == request) {
        _pendingLoadWithUnmatchedError = null;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerInitialized) {
      _initializeController();
      return;
    }

    // Update the video when the inherited widget provides a new videoId.
    final newVideoId = VideoPlayerInheritedWidget.of(context)?.videoId ?? '';
    final normalizedVideoId = _youtubeId(newVideoId);
    if (normalizedVideoId != null) {
      _requestVideoLoad(normalizedVideoId);
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
    if (!_controllerInitialized) {
      return const SizedBox.shrink();
    }
    debugPrint(controller.metadata.videoId);
    return YoutubePlayer(controller: controller);
  }
}
