import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system frosted-glass surface.
///
/// This is a stylistic choice, not an attempt at pixel-perfect iOS 26
/// "Liquid Glass" fidelity — real Liquid Glass does live specular refraction
/// of the content behind it, which needs a native platform view to render
/// (see `cupertino_native`). `AppGlass` is a `BackdropFilter` blur plus a
/// translucent tint: pure Dart, one implementation, identical on iOS and
/// Android — the same choice Spotify-style platform-agnostic apps make.
///
/// Built on `BackdropFilter`/`ClipRRect` (`widgets.dart`), not a Material
/// widget, so it renders with no `MaterialApp` ancestor.
class AppGlass extends StatelessWidget {
  const AppGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppSpacing.lg,
    this.blurSigma = 16,
    this.tint = const Color(0x33FFFFFF),
    this.border = const Color(0x33FFFFFF),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Backdrop blur strength. Higher = softer/frostier.
  final double blurSigma;

  /// Translucent overlay tinting the blurred backdrop. Pass a token color at
  /// low alpha (e.g. `AppColors.surface.withValues(alpha: 0.2)`); defaults to
  /// a neutral white frost so this primitive has no color-token dependency.
  final Color tint;

  /// Hairline edge that keeps the glass legible against a busy backdrop.
  final Color border;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: borderRadius,
            border: Border.all(color: border),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
