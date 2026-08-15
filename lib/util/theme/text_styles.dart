import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/util/theme/font_weight.dart';

/// Named text roles for the onboarding flows, so a screen says *what a piece of
/// text is* rather than respelling its size, weight and colour.
///
/// Sits beside [AppColors], [AppSpacing], [AppFontWeight] and [AppShadows] as
/// the typography layer of the same token set. Before this existed, "screen
/// title" was written out as a `TextStyle(fontSize: 26.sp, …)` three times and
/// the body style six times — so a design change meant finding all nine.
///
/// No role sets `fontFamily`. `ThemeData.fontFamily` is already `Rubix` for
/// both themes; repeating it per call site is noise that also hides the day the
/// app gains a second family.
///
/// Colours resolve from the [ColorScheme], so dark mode follows automatically.
/// Sizes use ScreenUtil's `.sp` against the 360pt design width, which is the
/// Figma frames' own width.
abstract class AppTextStyles {
  /// Screen title. Figma nodes 1660:1267 / 1660:2281 / 1660:2316 — 26pt,
  /// Medium, line height 33.8 (1.3), in the `blue` style.
  static TextStyle screenTitle(BuildContext context) => TextStyle(
    fontSize: 26.sp,
    height: 1.3,
    fontWeight: AppFontWeight.medium,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Supporting copy under a title. Figma nodes 1660:1289 / 1660:2282 and the
  /// first run of 1660:2317 — 16pt, Regular, in the `grey` style.
  static TextStyle screenBody(BuildContext context) => TextStyle(
    fontSize: 16.sp,
    height: 1.19,
    fontWeight: AppFontWeight.regular,
    color: Theme.of(context).colorScheme.outline,
  );

  /// The accented second paragraph. Figma node 1660:1288 and the second run of
  /// 1660:2317 — 16pt, Medium, in the `green` style.
  static TextStyle screenBodyAccent(BuildContext context) => TextStyle(
    fontSize: 16.sp,
    height: 1.19,
    fontWeight: AppFontWeight.medium,
    color: Theme.of(context).colorScheme.tertiary,
  );

  /// Label on a filled primary button. Figma nodes 1660:1274 and
  /// I1660:2301;325:2 — 18pt, Medium, on the button's own foreground.
  static TextStyle primaryAction(BuildContext context) => TextStyle(
    fontSize: 18.sp,
    fontWeight: AppFontWeight.medium,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  /// Label on a secondary action, drawn as a link rather than a button.
  /// Figma node I1660:2320;218:535 — same size and weight, brand colour.
  static TextStyle secondaryAction(BuildContext context) => TextStyle(
    fontSize: 18.sp,
    fontWeight: AppFontWeight.medium,
    color: Theme.of(context).colorScheme.primary,
  );

  /// Header link — the skip control. Figma node 1660:2302: 16pt, Medium, in
  /// the `blue` style.
  static TextStyle headerLink(BuildContext context) => TextStyle(
    fontSize: 16.sp,
    fontWeight: AppFontWeight.medium,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Form-field label. Figma nodes 1660:2288 / 2294 / 2300 — 14pt, SemiBold,
  /// in a 32pt line box, which is what makes the label+field group 90 tall.
  static TextStyle fieldLabel(BuildContext context) => TextStyle(
    fontSize: fieldLabelSize.sp,
    height: fieldLabelBox / fieldLabelSize,
    fontWeight: AppFontWeight.semiBold,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static const double fieldLabelSize = 14;
  static const double fieldLabelBox = 32;
}
