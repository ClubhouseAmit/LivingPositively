import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/circular_action_button.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const String _personalPlanVideoId = 'WCmX1xInZ-4';
final Uri _spiUri = Uri.parse('https://suicidesafetyplan.com/');
final Uri _rppUri = Uri.parse(
  'https://www.heretohelp.bc.ca/infosheet/'
  'preventing-relapse-of-a-mental-illness',
);

/// Presents the Personal Plan information modal from an icon-only action.
final class PersonalPlanInfoButton extends StatelessWidget {
  const PersonalPlanInfoButton({super.key, this.actionKey});

  /// Key applied to the actionable hit target when a caller needs to identify it.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return SizedBox(
      key: actionKey,
      child: circularActionButton(
        context,
        tooltip: l10n.personalPlanInfoTooltip,
        icon: Icons.info_outline,
        diameter: 32,
        iconSize: 20,
        onTap: () {
          unawaited(showPersonalPlanInfoModal(context));
        },
      ),
    );
  }
}

/// Shows the explanatory video and text for the user's Personal Plan.
Future<void> showPersonalPlanInfoModal(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const PersonalPlanInfoModal(),
  );
}

/// Displays the Personal Plan's localized explanatory content in a dialog.
final class PersonalPlanInfoModal extends StatefulWidget {
  const PersonalPlanInfoModal({super.key});

  @override
  State<PersonalPlanInfoModal> createState() => _PersonalPlanInfoModalState();
}

enum _PersonalPlanInfoView { text, video }

final class _PersonalPlanInfoModalState extends State<PersonalPlanInfoModal> {
  _PersonalPlanInfoView _selectedView = _PersonalPlanInfoView.text;
  YoutubePlayerController? _videoController;

  @override
  void dispose() {
    _releaseVideoController();
    super.dispose();
  }

  void _selectView(_PersonalPlanInfoView view) {
    if (_selectedView == view) {
      return;
    }

    if (view == _PersonalPlanInfoView.video) {
      _videoController ??= _createVideoController();
    } else {
      _releaseVideoController();
    }

    setState(() {
      _selectedView = view;
    });
  }

  YoutubePlayerController _createVideoController() {
    final String languageCode = Localizations.localeOf(context).languageCode;
    final YoutubePlayerController controller = YoutubePlayerController(
      key: _personalPlanVideoId,
      params: YoutubePlayerParams(
        enableCaption: true,
        captionLanguage: languageCode,
        interfaceLanguage: languageCode,
      ),
    );
    unawaited(_cueVideo(controller));
    return controller;
  }

  Future<void> _cueVideo(YoutubePlayerController controller) async {
    try {
      await controller.cueVideoById(videoId: _personalPlanVideoId);
    } catch (_) {
      // The platform player owns rendering errors, including failures while
      // this dialog is closing and its controller has already been released.
    }
  }

  void _releaseVideoController() {
    final YoutubePlayerController? controller = _videoController;
    if (controller == null) {
      return;
    }

    _videoController = null;
    unawaited(_stopAndCloseVideo(controller));
  }

  Future<void> _stopAndCloseVideo(YoutubePlayerController controller) async {
    try {
      await controller.pauseVideo();
    } catch (_) {
      // A platform view can be disposed before its pause request is handled.
    } finally {
      await controller.close();
    }
  }

  void _close() {
    _releaseVideoController();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final YoutubePlayerController? videoController = _videoController;

    return Semantics(
      namesRoute: true,
      label: l10n.personalPlanInfoTitle,
      child: Dialog(
        key: const Key('personalPlanInfoModal'),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.personalPlanInfoTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      IconButton(
                        key: const Key('personalPlanInfoCloseButton'),
                        tooltip: l10n.personalPlanInfoClose,
                        onPressed: _close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        key: const Key('personalPlanInfoTextTab'),
                        label: Text(l10n.personalPlanInfoReadText),
                        selected: _selectedView == _PersonalPlanInfoView.text,
                        onSelected: (_) =>
                            _selectView(_PersonalPlanInfoView.text),
                      ),
                      ChoiceChip(
                        key: const Key('personalPlanInfoVideoTab'),
                        label: Text(l10n.personalPlanInfoVideo),
                        selected: _selectedView == _PersonalPlanInfoView.video,
                        onSelected: (_) =>
                            _selectView(_PersonalPlanInfoView.video),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_selectedView == _PersonalPlanInfoView.text)
                    _PersonalPlanInfoText(l10n: l10n)
                  else if (videoController != null)
                    AspectRatio(
                      key: const Key('personalPlanInfoVideoPlayer'),
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(controller: videoController),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _PersonalPlanInfoText extends StatelessWidget {
  const _PersonalPlanInfoText({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final TextStyle? bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.personalPlanInfoIntro,
          style: bodyStyle,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.personalPlanInfoExplanation,
          style: bodyStyle,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.md),
        _PersonalPlanInfoBullet(
          text: l10n.personalPlanInfoBulletTriggers,
          style: bodyStyle,
        ),
        _PersonalPlanInfoBullet(
          text: l10n.personalPlanInfoBulletSelfSoothing,
          style: bodyStyle,
        ),
        _PersonalPlanInfoBullet(
          text: l10n.personalPlanInfoBulletSupportCircle,
          style: bodyStyle,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.personalPlanInfoRecommendation,
          style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.personalPlanInfoFurtherReading,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('personalPlanInfoSpiLink'),
            onPressed: () {
              unawaited(_openExternalLink(_spiUri));
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.personalPlanInfoSpi),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('personalPlanInfoRppLink'),
            onPressed: () {
              unawaited(_openExternalLink(_rppUri));
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.personalPlanInfoRpp),
          ),
        ),
      ],
    );
  }
}

final class _PersonalPlanInfoBullet extends StatelessWidget {
  const _PersonalPlanInfoBullet({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u2022', style: style),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: style, textAlign: TextAlign.start),
          ),
        ],
      ),
    );
  }
}

Future<void> _openExternalLink(Uri uri) async {
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}
