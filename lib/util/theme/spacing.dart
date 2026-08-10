/// Consistent spacing tokens for the app.
///
/// Base unit: 4dp (Material Design standard)
/// Scale: xs (1×), sm (2×), md (3×), lg (4×), xl (5×), xxl (6×), xxxl (8×)
///
/// Usage:
/// ```dart
/// padding: EdgeInsets.symmetric(
///   horizontal: AppSpacing.lg,
///   vertical: AppSpacing.md,
/// )
/// ```
abstract class AppSpacing {
  // Extra small: 4dp
  static const xs = 4.0;

  // Small: 8dp
  static const sm = 8.0;

  // Medium: 12dp
  static const md = 12.0;

  // Large: 16dp (default padding)
  static const lg = 16.0;

  // Extra large: 20dp
  static const xl = 20.0;

  // Extra extra large: 24dp
  static const xxl = 24.0;

  // Extra extra extra large: 32dp
  static const xxxl = 32.0;
}
