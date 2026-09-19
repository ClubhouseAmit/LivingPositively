import 'package:flutter/painting.dart' show BoxShadow, Color, Offset;

/// Drop-shadow tokens, matching the `shadows` block in `DESIGN.md`'s
/// frontmatter.
///
/// Relocated verbatim from `lib/util/theme/shadows.dart` as step 1 of the
/// design-system extraction. `BoxShadow`/`Color`/`Offset` come from
/// `painting.dart`, not `material.dart` — this file owns zero Material
/// imports.
abstract class AppShadows {
  /// Cards, form fields and raised buttons. DESIGN.md `shadows.card`;
  /// Figma effect style `2` — #F1EDEA at 48%, offset (0,3), blur 11.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x7AF1EDEA), offset: Offset(0, 3), blurRadius: 11),
  ];

  /// Bottom navigation and bottom sheets. DESIGN.md `shadows.sheet`.
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, -11), blurRadius: 28),
  ];

  /// Selected or highlighted card. DESIGN.md `shadows.active`.
  static const List<BoxShadow> active = [
    BoxShadow(color: Color(0x990F2851), offset: Offset(0, 4), blurRadius: 12),
  ];
}
