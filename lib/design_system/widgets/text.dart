import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter/widgets.dart' as flutter show Text;

import 'package:mazilon/design_system/tokens/type_scale.dart';

/// Named type-scale slots. Each maps to the `AppTypeScale` token that
/// `ThemeData.textTheme` uses for the same Material slot (`app_theme.dart`).
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
/// Built directly on Flutter's `Text` (from `widgets.dart`, not `material.dart`) so it
/// never reads `Theme.of(context)` — the font, size, weight and line height
/// all come from `AppTypeScale`, not from a Material `ThemeData` ancestor.
/// The font follows the app language (`AppTypeScale.familyFor`).
/// This is deliberate: a widget in `design_system/` must render correctly
/// with no `MaterialApp`/`Theme` above it at all.
///
/// [color] overrides the token's default color (tokens carry no color; pass
/// one from `AppColors` explicitly, same as any other design-system caller).
class Text extends StatelessWidget {
  const Text(
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
    AppTextStyle.headlineLarge: AppTypeScale.headingH1,
    AppTextStyle.headlineMedium: AppTypeScale.headingH2,
    AppTextStyle.titleLarge: AppTypeScale.titleLarge,
    AppTextStyle.titleSmall: AppTypeScale.titleBase,
    AppTextStyle.labelLarge: AppTypeScale.titleSmall,
    AppTextStyle.bodyLarge: AppTypeScale.bodyBase,
    AppTextStyle.bodySmall: AppTypeScale.bodyXSmall,
    AppTextStyle.labelSmall: AppTypeScale.captionMicro,
  };

  @override
  Widget build(BuildContext context) {
    final TextStyle resolved = _tokens[style]!.copyWith(
      color: color,
      fontFamily: AppTypeScale.familyFor(Localizations.maybeLocaleOf(context)),
    );
    return flutter.Text(
      data,
      style: resolved,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
