import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/tokens/type_scale.dart';

/// Named type-scale slots, matching `AppTypeScale`'s tokens 1:1.
enum AppTextStyle {
  headlineLarge,
  headlineMedium,
  titleLarge,
  titleSmall,
  labelLarge,
  bodyLarge,
  bodySmall,
  labelSmall,
}

/// Design-system text primitive.
///
/// Built directly on `Text` (from `widgets.dart`, not `material.dart`) so it
/// never reads `Theme.of(context)` — the font, size, weight and line height
/// all come from `AppTypeScale`, not from a Material `ThemeData` ancestor.
/// This is deliberate: a widget in `design_system/` must render correctly
/// with no `MaterialApp`/`Theme` above it at all.
///
/// [color] overrides the token's default color (tokens carry no color; pass
/// one from `AppColors` explicitly, same as any other design-system caller).
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style = AppTextStyle.bodyLarge,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// The text to display.
  final String data;

  /// Which `AppTypeScale` token to render with.
  final AppTextStyle style;

  /// Foreground color. Pass an `AppColors` token; defaults to inherited
  /// `DefaultTextStyle` color when omitted.
  final Color? color;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static const Map<AppTextStyle, TextStyle> _tokens = {
    AppTextStyle.headlineLarge: AppTypeScale.headlineLarge,
    AppTextStyle.headlineMedium: AppTypeScale.headlineMedium,
    AppTextStyle.titleLarge: AppTypeScale.titleLarge,
    AppTextStyle.titleSmall: AppTypeScale.titleSmall,
    AppTextStyle.labelLarge: AppTypeScale.labelLarge,
    AppTextStyle.bodyLarge: AppTypeScale.bodyLarge,
    AppTextStyle.bodySmall: AppTypeScale.bodySmall,
    AppTextStyle.labelSmall: AppTypeScale.labelSmall,
  };

  @override
  Widget build(BuildContext context) {
    final TextStyle resolved = _tokens[style]!.copyWith(color: color);
    return Text(
      data,
      style: resolved,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
