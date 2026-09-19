import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/shadows.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system card primitive — the replacement for reaching for
/// Material's `Card` or a hand-rolled `Container` with inline decoration.
///
/// Built on `DecoratedBox` (from `widgets.dart`), not `Card`: `Card` carries
/// Material's ink/elevation behavior with it. This is the fix for the drift
/// this session found — a bare `Card()` renders Material 3's default radius
/// (12) and elevation, not this design system's `AppRadii.card` (16) and
/// `AppShadows.card`.
///
/// Defaults to `AppColors.white`, `AppRadii.card`, `AppShadows.card` — see
/// DESIGN.md §3.3. Pass an override only for a documented exception (see
/// DESIGN.md §3.3's "Active Selection Card").
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.white,
    this.radius = AppRadii.card,
    this.shadow = AppShadows.card,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final List<BoxShadow>? shadow;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
        border: border,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
