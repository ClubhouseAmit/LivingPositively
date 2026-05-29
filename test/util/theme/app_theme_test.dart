// Phase D regression suite (ADR-005 §Decision step 4).
//
// These tests pin the contract between the new `AppColors` token layer
// and the legacy palette/buttons that the audit (`docs/UX_GAPS.md §1.1`,
// §1.2) called out. They are deliberately tight: each test fails if a
// future refactor silently drifts the token values, removes the legacy
// forwarders, or reverts `myButtonStyle3` to a raw Material colour.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/app_theme.dart';

void main() {
  group('AppColors semantic tokens', () {
    test('primary preserves the brand lavender hex from styles.dart', () {
      expect(AppColors.primary, const Color(0xFFA688F8));
    });

    test('surface preserves the off-white scaffold hex', () {
      expect(AppColors.surface, const Color(0xFFFAF8F8));
    });

    test('onSurface preserves the dark navy used for body text', () {
      expect(AppColors.onSurface, const Color(0xFF0F2851));
    });

    test('error is Material red 500 (visual parity with Colors.red)', () {
      // Phase D intent is a no-op at the pixel level; the value of
      // `Colors.red` is `0xFFF44336` (Material red 500). Diverging here
      // would change every destructive button without a design pass.
      expect(AppColors.error.toARGB32(), Colors.red.toARGB32());
    });

    test('pdfTint keeps the unusual literal verbatim', () {
      // The original `pdfpurple` literal `0xfaf6fd` lacks an alpha byte.
      // Preserve byte-for-byte so PDF exports do not shift colour.
      // ignore: use_full_hex_values_for_flutter_colors
      expect(AppColors.pdfTint, const Color(0xfaf6fd));
    });
  });

  group('legacy palette forwarders', () {
    test('every legacy variable forwards to an AppColors token', () {
      expect(primaryPurple, AppColors.primary);
      expect(lightPurple, AppColors.secondary);
      expect(appWhite, AppColors.surface);
      expect(backgroundGray, AppColors.surface);
      expect(appBlue, AppColors.onSurface);
      expect(appGreen, AppColors.success);
      expect(lightGray, AppColors.neutralLight);
      expect(darkGray, AppColors.neutralDark);
      expect(pdfpurple, AppColors.pdfTint);
    });
  });

  group('destructive button uses semantic token', () {
    testWidgets('myButtonStyle3 background resolves to AppColors.error',
        (tester) async {
      const states = <WidgetState>{};
      final bg = myButtonStyle3.backgroundColor?.resolve(states);
      expect(bg, isNotNull,
          reason: 'myButtonStyle3 must declare a background colour');
      expect(bg, AppColors.error);
    });
  });

  group('buildLightTheme', () {
    test('exposes AppColors via ColorScheme', () {
      final theme = buildLightTheme();
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.onPrimary, AppColors.onPrimary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.onSurface, AppColors.onSurface);
      expect(theme.colorScheme.error, AppColors.error);
    });

    test('keeps Material 2 + Rubix font family', () {
      // The brand button styles in styles.dart target Material 2
      // (custom RoundedRectangleBorder + TextButton.styleFrom). A
      // silent flip to Material 3 would visually break them.
      final theme = buildLightTheme();
      expect(theme.useMaterial3, isFalse);
      expect(theme.brightness, Brightness.light);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Rubix');
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });
  });

  group('buildDarkThemeStub', () {
    test('mirrors the light scheme (ADR-005: light-only dark stub)', () {
      final dark = buildDarkThemeStub();
      final light = buildLightTheme();
      expect(dark.colorScheme.primary, light.colorScheme.primary);
      expect(dark.colorScheme.surface, light.colorScheme.surface);
      expect(dark.colorScheme.onSurface, light.colorScheme.onSurface);
    });
  });
}
