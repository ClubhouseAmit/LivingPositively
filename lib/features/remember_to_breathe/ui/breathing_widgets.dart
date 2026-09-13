import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/theme/spacing.dart';

/// Localized labels for the bundled and personal breathing backgrounds.
String breathingBackgroundLabel(
  AppLocalizations strings,
  BreathingBackground background,
) => switch (background) {
  BreathingBackground.forest => strings.breathingForest,
  BreathingBackground.mountains => strings.breathingMountains,
  BreathingBackground.cosmos => strings.breathingCosmos,
  BreathingBackground.beach => strings.breathingBeach,
  BreathingBackground.flowers => strings.breathingFlowers,
  BreathingBackground.sunset => strings.breathingSunset,
  BreathingBackground.house => strings.breathingHouse,
  BreathingBackground.monastery => strings.breathingMonastery,
  BreathingBackground.personal => strings.breathingPersonal,
};

/// Localized names shared by the pattern selector and history rows.
String breathingPatternLabel(
  AppLocalizations strings,
  BreathingPattern pattern,
) => switch (pattern) {
  BreathingPattern.basic => strings.breathingBasic,
  BreathingPattern.box => strings.breathingBox,
  BreathingPattern.custom => strings.breathingCustom,
};

/// A local background whose personal image is decoded only when it changes.
class BreathingBackgroundImage extends StatefulWidget {
  const BreathingBackgroundImage({super.key, required this.settings});

  final BreathingSettings settings;

  @override
  State<BreathingBackgroundImage> createState() =>
      _BreathingBackgroundImageState();
}

class _BreathingBackgroundImageState extends State<BreathingBackgroundImage> {
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    _decodePhoto();
  }

  @override
  void didUpdateWidget(BreathingBackgroundImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.personalPhotoBase64 !=
        widget.settings.personalPhotoBase64) {
      _decodePhoto();
    }
  }

  void _decodePhoto() {
    final encoded = widget.settings.personalPhotoBase64;
    try {
      _photo = encoded == null ? null : base64Decode(encoded);
    } on FormatException {
      _photo = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settings.background == BreathingBackground.personal &&
        _photo != null) {
      return Image.memory(
        _photo!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: _imageUnavailable,
      );
    }
    final background =
        widget.settings.background == BreathingBackground.personal
        ? BreathingBackground.forest
        : widget.settings.background;
    return Image.asset(
      'assets/images/breathing/${background.name}.jpg',
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: _imageUnavailable,
    );
  }

  Widget _imageUnavailable(
    BuildContext context,
    Object error,
    StackTrace? stack,
  ) => ColoredBox(color: Theme.of(context).colorScheme.primaryContainer);
}

/// An optional stress selector; no value is selected until an explicit action.
class BreathingRatingInput extends StatelessWidget {
  const BreathingRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.keyPrefix,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.breathingStressQuestion,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var rating = 1; rating <= 10; rating++)
              ChoiceChip(
                key: Key('$keyPrefix$rating'),
                label: Text('$rating'),
                selected: value == rating,
                onSelected: (_) => onChanged(rating),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
        if (value == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(strings.breathingNoRating),
          ),
      ],
    );
  }
}

/// Keyboard-accessible alternatives to measuring a breath by touch.
class BreathingDurationButtons extends StatelessWidget {
  const BreathingDurationButtons({
    super.key,
    required this.duration,
    required this.label,
    required this.onAdjust,
    required this.keyPrefix,
  });

  final Duration duration;
  final String label;
  final ValueChanged<int> onAdjust;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: Key('${keyPrefix}Decrease'),
              tooltip: strings.breathingDecrease,
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: duration > const Duration(seconds: 3)
                  ? () => onAdjust(-1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Flexible(
              child: Text(
                strings.breathingSeconds(
                  (duration.inMilliseconds / 1000).toStringAsFixed(1),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              key: Key('${keyPrefix}Increase'),
              tooltip: strings.breathingIncrease,
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: duration < const Duration(seconds: 9)
                  ? () => onAdjust(1)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
