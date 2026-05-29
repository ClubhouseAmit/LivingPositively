import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:mazilon/util/theme/app_theme.dart';

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

Container ConfirmationButton(context, function, text, buttonTextStyle) {
  return Container(
    width: MediaQuery.of(context).size.width > 1000
        ? 600
        : MediaQuery.of(context).size.width * 0.6,
    child: TextButton(
      onPressed: () {
        function();
      },
      style: myButtonStyle,
      child: myAutoSizedText(text, buttonTextStyle, null, 50),
    ),
  );
}

Container CancelButton(context, function, text, buttonTextStyle) {
  return Container(
    width: MediaQuery.of(context).size.width > 1000
        ? 600
        : MediaQuery.of(context).size.width * 0.6,
    child: TextButton(
      onPressed: () {
        function();
      },
      style: myButtonStyle3,
      child: myAutoSizedText(text, buttonTextStyle, null, 50),
    ),
  );
}

Container ResetButton(context, function, text, buttonTextStyle) {
  return Container(
    width: MediaQuery.of(context).size.width > 1000
        ? 400
        : MediaQuery.of(context).size.width * 0.3,
    child: TextButton(
      onPressed: () {
        function();
      },
      style: myButtonStyle3,
      child: myAutoSizedText(text, buttonTextStyle, null, 50),
    ),
  );
}

const emptyStyle = TextStyle();
Text myText(content, style, align) {
  style ??= emptyStyle;
  return Text(
    content,
    style: style.copyWith(fontFamily: 'Rubix'),
    textAlign: align,
  );
}

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

Icon mainpageListsAddIcon = Icon(
  Icons.add,
  color: primaryPurple, // the color of the add icon
  size: 30, // the size of the add icon
);
