import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/theme/shadows.dart';

// Phase D (ADR-005 §Decision step 4): the nine palette variables below
// previously held literal `Color(...)` values and were mutated by hand
// per page. They now forward to `AppColors` semantic tokens defined in
// `lib/util/theme/app_theme.dart` so the source of truth is one layer.
// The variables are kept (rather than deleted) because ~30 files in
// `lib/` reference them by name — the ADR explicitly calls for legacy
// forwarders during the migration window.
const Color pdfpurple = AppColors.pdfTint;
const Color primaryPurple = AppColors.primary;
const Color lightGray = AppColors.neutralLight;
const Color backgroundGray = AppColors.surface;
const Color darkGray = AppColors.neutralDark;
const Color appGreen = AppColors.success;
const Color appBlue = AppColors.onSurface;
const Color lightPurple = AppColors.secondary;
const Color appWhite = AppColors.surface;

double returnSizedBox(context, int size) {
  if (MediaQuery.of(context).size.width < 400) {
    return size / 2;
  }

  if (MediaQuery.of(context).size.width < 500) {
    return size + 0.1;
  }
  if (MediaQuery.of(context).size.width < 600) {
    return size + 10;
  }
  return size + 20;
}

double formFieldWidth(BuildContext context) {
  final availableWidth = MediaQuery.sizeOf(context).width - 48;
  if (availableWidth > 360) {
    return 360;
  }
  return availableWidth > 0 ? availableWidth : MediaQuery.sizeOf(context).width;
}

/// Form-field container geometry (Figma frame 28, Groups 75/141/142/143).
const double kFormFieldHeight = 53;
const double kFormFieldVerticalPadding = 14.5;
const double kFormFieldRadius = 16;
const double kFormFieldLabelBox = 32;
const double kFormFieldLabelSize = 14;
const double kFormFieldLabelHeight = kFormFieldLabelBox / kFormFieldLabelSize;

/// Border for a form field. Pair with [formFieldShadowDecoration] for shadow.
OutlineInputBorder formFieldBorder(BuildContext context) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(kFormFieldRadius),
  borderSide: BorderSide(
    color: Theme.of(context).colorScheme.outline,
    width: 1,
  ),
);

/// Field decoration for [TextFormField] controls.
InputDecoration formFieldInputDecoration(BuildContext context) =>
    InputDecoration(
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: kFormFieldVerticalPadding,
      ),
      border: formFieldBorder(context),
      enabledBorder: formFieldBorder(context),
      focusedBorder: formFieldBorder(context),
    );

/// Field decoration theme for [DropdownMenu] controls.
InputDecorationTheme formFieldInputDecorationTheme(BuildContext context) =>
    InputDecorationTheme(
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: kFormFieldVerticalPadding,
      ),
      constraints: const BoxConstraints.tightFor(height: kFormFieldHeight),
      border: formFieldBorder(context),
      enabledBorder: formFieldBorder(context),
      focusedBorder: formFieldBorder(context),
    );

/// Shadow-only wrapper for a form field. The border is drawn by the control
/// itself so the focus/error states keep working; this supplies the drop
/// shadow underneath it.
BoxDecoration formFieldShadowDecoration() => BoxDecoration(
  borderRadius: BorderRadius.circular(kFormFieldRadius),
  boxShadow: AppShadows.card,
);

/// Full field container for controls that do not draw their own border
/// (the country picker). Border, radius and shadow in one decoration.
BoxDecoration formFieldDecoration(BuildContext context) => BoxDecoration(
  color: Colors.transparent,
  borderRadius: BorderRadius.circular(kFormFieldRadius),
  border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
  boxShadow: AppShadows.card,
);

ButtonStyle myButtonStyle = TextButton.styleFrom(
  backgroundColor: primaryPurple,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
);
// Phase D (ADR-005 §Decision step 4): destructive-action button. The
// background was previously `Colors.red` — a raw Material colour with
// no semantic meaning. It now points at `AppColors.error`, the same
// hex value as `Colors.red` (Material red 500) so this PR is visually
// a no-op while moving the call site behind a semantic token.
ButtonStyle myButtonStyle3 = TextButton.styleFrom(
  backgroundColor: AppColors.error,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
);
TextStyle myTextStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

ButtonStyle myButtonStyle2 = TextButton.styleFrom(
  backgroundColor: Colors.blue,
  foregroundColor: Colors.black,
  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
);

ButtonStyle primaryButtonStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return TextButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  );
}

ButtonStyle destructiveButtonStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return TextButton.styleFrom(
    backgroundColor: colorScheme.error,
    foregroundColor: colorScheme.onError,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  );
}

TextStyle primaryButtonTextStyle(BuildContext context) {
  return TextStyle(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onPrimary,
  );
}

Widget ConfirmationButton(context, function, text, buttonTextStyle) {
  final textStyle = buttonTextStyle is TextStyle
      ? buttonTextStyle.copyWith(color: Theme.of(context).colorScheme.onPrimary)
      : primaryButtonTextStyle(context);
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: TextButton(
      onPressed: () {
        function();
      },
      style: primaryButtonStyle(context),
      child: myAutoSizedText(text, textStyle, null, 50),
    ),
  );
}

Widget CancelButton(context, function, text, buttonTextStyle) {
  final textStyle = buttonTextStyle is TextStyle
      ? buttonTextStyle.copyWith(color: Theme.of(context).colorScheme.onError)
      : TextStyle(color: Theme.of(context).colorScheme.onError);
  return SizedBox(
    width: MediaQuery.of(context).size.width > 1000
        ? 600
        : MediaQuery.of(context).size.width * 0.6,
    child: TextButton(
      onPressed: () {
        function();
      },
      style: destructiveButtonStyle(context),
      child: myAutoSizedText(text, textStyle, null, 50),
    ),
  );
}

Widget ResetButton(context, function, text, buttonTextStyle) {
  final textStyle = buttonTextStyle is TextStyle
      ? buttonTextStyle.copyWith(color: Theme.of(context).colorScheme.onError)
      : TextStyle(color: Theme.of(context).colorScheme.onError);
  return SizedBox(
    width: MediaQuery.of(context).size.width > 1000
        ? 400
        : MediaQuery.of(context).size.width * 0.3,
    child: TextButton(
      onPressed: () {
        function();
      },
      style: destructiveButtonStyle(context),
      child: myAutoSizedText(text, textStyle, null, 50),
    ),
  );
}

const emptyStyle = TextStyle();

/// Legacy. Use a plain [Text] widget directly.
///
/// All this does is force `fontFamily: 'Rubix'`, which both themes already set
/// via `ThemeData.fontFamily` — so it buys nothing over `Text`, while costing
/// an untyped `style` parameter and hiding the widget behind a helper.
@Deprecated('Use a plain Text widget; ThemeData already applies Rubik.')
Text myText(content, style, align) {
  style ??= emptyStyle;
  return Text(
    content,
    style: style.copyWith(fontFamily: 'Rubix'),
    textAlign: align,
  );
}

/// Legacy, and the more dangerous of the two: the `maxFontSize` argument is
/// what actually paints, while the `fontSize` in `style` is inert whenever
/// `maxLines` is null inside an unbounded-height scroll view — every candidate
/// size "fits", so `AutoSizeText` settles on its ceiling. On issue #338 titles
/// declared at `40.sp` painted at 60 and buttons declared at `20.sp` at 44, and
/// changing the declared size did nothing at all.
///
/// Use a plain [Text] at an explicit size, which cannot drift from its own
/// declaration. See `designs/issue-338-audit.md` §1.
@Deprecated(
  'Use Text at an explicit size; maxFontSize silently overrides style.fontSize.',
)
AutoSizeText myAutoSizedText(
  content,
  style,
  align,
  double maxFontSize, [
  int maxLines = 20,
]) {
  style ??= emptyStyle;
  align ??= TextAlign.center;
  return AutoSizeText(
    content,
    maxFontSize: maxFontSize,
    style: style.copyWith(fontFamily: 'Rubix'),
    textAlign: align,
    maxLines: maxLines == 20 ? null : maxLines,
  );
}

Image myImage(String path, BuildContext context, double width, double height) {
  var screensize = MediaQuery.of(context).size;

  return Image.asset(
    path,
    width: screensize.width * width, // Adjust as needed
    height: screensize.height * height, // Adjust as needed
  );
}

Widget myTextButton(
  Function function,
  IconData icon,
  Color color, {
  String? tooltip,
}) {
  final button = TextButton(
    onPressed: () {
      function();
    },
    child: Icon(icon, color: color, size: 30),
  );
  if (tooltip == null || tooltip.isEmpty) return button;
  return Tooltip(message: tooltip, child: button);
}

/// Inline text-and-icon link — a tertiary action rendered as coloured text
/// with a leading icon and no button chrome (e.g. "add your own",
/// "other suggestions" in the onboarding template).
///
/// The icon leads so `Directionality` mirrors it: reading-start side in both
/// RTL and LTR. Padding and the minimum tap target are reset because the
/// design sizes these to the text box; Material's default 48px minimum would
/// otherwise inflate the surrounding spacing. That is a deliberate trade
/// against the 48px touch-target guideline — prefer [ConfirmationButton] or
/// [myTextButton] where a full-size target matters.
///
/// [designFontSize] is the design's size in whole points. It is used both as
/// the (scaled) style size and as the `AutoSizeText` ceiling, which must stay
/// a whole multiple of `stepGranularity` — so the unscaled value goes there.
Widget LinkButton(
  Function function,
  IconData icon,
  String label,
  Color color, {
  double designFontSize = 14,
  double iconSize = 16,
  double gap = 4,
  double minHeight = 32,
}) {
  return TextButton(
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size(0, minHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: () {
      function();
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        Icon(icon, color: color, size: iconSize),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: designFontSize.sp,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Dot step indicator for the onboarding wizard — one pill per step, filled
/// in [AppColors.primary] up to and including [currentStep] and
/// [AppColors.progressTrack] beyond it.
///
/// Distinct from the `LinearProgressIndicator` in DESIGN.md §3.5: the
/// onboarding flow's design specifies discrete dots, not a continuous bar.
/// Geometry of the wizard's progress dots. Public so the header can reserve
/// the space they occupy instead of guessing at it.
const double kStepDotWidth = 18;
const double kStepDotGap = 8;

/// Width the dots occupy for [stepCount] steps.
double stepDotsWidth(
  int stepCount, {
  double dotWidth = kStepDotWidth,
  double gap = kStepDotGap,
}) => stepCount <= 0 ? 0 : stepCount * dotWidth + (stepCount - 1) * gap;

Widget StepDotsIndicator(
  BuildContext context, {
  required int stepCount,
  required int currentStep,
  double dotWidth = kStepDotWidth,
  double dotHeight = 8,
  //Figma: dots are pitched 26.65 apart at 18.4 wide -> ~8.3 between them.
  double gap = kStepDotGap,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: gap,
    children: List.generate(
      stepCount,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: dotWidth,
        height: dotHeight,
        decoration: BoxDecoration(
          color: index <= currentStep
              ? Theme.of(context).colorScheme.primary
              : AppColors.progressTrack,
          borderRadius: BorderRadius.circular(dotHeight / 2),
        ),
      ),
    ),
  );
}

Icon mainpageListsAddIcon = Icon(
  Icons.add,
  color: primaryPurple, // the color of the add icon
  size: 30, // the size of the add icon
);
