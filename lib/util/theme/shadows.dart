import 'package:flutter/material.dart';

/// Drop-shadow tokens, matching the `shadows` block in `DESIGN.md`'s
/// frontmatter. DESIGN.md §2.4 has told callers to use "the `AppShadows`
/// library" since it was written; this is that library.
///
/// Values come from the frontmatter rather than §2.4's prose list, because the
/// frontmatter is what matches the Figma effect styles. The prose had drifted
/// (it listed the card shadow as `0x0F0E2851`, offset (0,4), blur 10) and has
/// been corrected to agree with this.
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
