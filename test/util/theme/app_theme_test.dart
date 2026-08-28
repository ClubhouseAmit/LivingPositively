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

    test('dark tokens should match the approved cool-taupe palette', () {
      expect(AppColors.darkPageBackground, const Color(0xFF2D2B2A));
      expect(AppColors.darkNavBackground, const Color(0xFF393739));
      expect(AppColors.darkSurface, const Color(0xFF2B2A2C));
      expect(AppColors.darkSurfaceContainer, const Color(0xFF4C494B));
      expect(AppColors.darkPrimary, const Color(0xFFD0C1A4));
      expect(AppColors.darkOnPrimary, const Color(0xFF2B2A2C));
      expect(AppColors.darkSecondary, const Color(0xFFB9AEA0));
      expect(AppColors.darkOnSecondary, const Color(0xFF2B2A2C));
      expect(AppColors.darkOnSurface, const Color(0xFFF5F0E8));
      expect(AppColors.darkError, const Color(0xFFA15857));
      expect(AppColors.darkOnError, const Color(0xFFFFF5F0));
      expect(AppColors.darkOutline, const Color(0xFFD0C1A4));
      expect(AppColors.darkSuccess, const Color(0xFF74AD82));
      expect(AppColors.darkOnSuccess, const Color(0xFF102A1B));
    });

    test('success preserves the light-mode green', () {
      expect(AppColors.success, const Color(0xFF01B91E));
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
    testWidgets('myButtonStyle3 background resolves to AppColors.error', (
      tester,
    ) async {
      const states = <WidgetState>{};
      final bg = myButtonStyle3.backgroundColor?.resolve(states);
      expect(
        bg,
        isNotNull,
        reason: 'myButtonStyle3 must declare a background colour',
      );
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
      expect(theme.scaffoldBackgroundColor, AppColors.pageBackground);
    });
  });

  group('buildDarkTheme', () {
    test('exposes the accessible dark palette via ColorScheme', () {
      final dark = buildDarkTheme();

      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme, appDarkColorScheme);
      expect(dark.colorScheme.primary, AppColors.darkPrimary);
      expect(dark.colorScheme.onPrimary, AppColors.darkOnPrimary);
      expect(dark.colorScheme.secondary, AppColors.darkSecondary);
      expect(dark.colorScheme.onSecondary, AppColors.darkOnSecondary);
      expect(dark.colorScheme.tertiary, AppColors.darkSuccess);
      expect(dark.colorScheme.onTertiary, AppColors.darkOnSuccess);
      expect(dark.colorScheme.surface, AppColors.darkSurface);
      expect(dark.colorScheme.onSurface, AppColors.darkOnSurface);
      expect(dark.colorScheme.error, AppColors.darkError);
      expect(dark.colorScheme.onError, AppColors.darkOnError);
      expect(dark.colorScheme.outline, AppColors.darkOutline);
      expect(dark.colorScheme.outlineVariant, AppColors.darkOutline);
      expect(
        dark.colorScheme.surfaceContainerHighest,
        AppColors.darkSurfaceContainer,
      );
      expect(dark.scaffoldBackgroundColor, AppColors.darkPageBackground);
      expect(dark.canvasColor, AppColors.darkSurface);
      expect(dark.cardColor, AppColors.darkSurfaceContainer);
      expect(dark.bottomAppBarTheme.color, AppColors.darkNavBackground);
      expect(dark.appBarTheme.backgroundColor, AppColors.darkNavBackground);
      expect(dark.appBarTheme.foregroundColor, AppColors.darkOnSurface);
      expect(
        dark.inputDecorationTheme.fillColor,
        AppColors.darkSurfaceContainer,
      );
      expect(dark.inputDecorationTheme.filled, isTrue);
    });

    test('text pairs should meet 4.5 to 1 contrast', () {
      final pairs = <(Color, Color)>[
        (AppColors.darkOnSurface, AppColors.darkSurface),
        (AppColors.darkOnSurface, AppColors.darkSurfaceContainer),
        (AppColors.darkOnPrimary, AppColors.darkPrimary),
        (AppColors.darkOnSecondary, AppColors.darkSecondary),
        (AppColors.darkOnError, AppColors.darkError),
        (AppColors.darkOnSuccess, AppColors.darkSuccess),
        (AppColors.darkOutline, AppColors.darkSurface),
        (AppColors.darkOutline, AppColors.darkSurfaceContainer),
      ];

      for (final (foreground, background) in pairs) {
        expect(
          _contrastRatio(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason:
              '${foreground.toARGB32().toRadixString(16)} on '
              '${background.toARGB32().toRadixString(16)}',
        );
      }
    });

    test('green outlines should meet 3 to 1 non-text contrast', () {
      for (final background in [
        AppColors.darkPageBackground,
        AppColors.darkSurfaceContainer,
      ]) {
        expect(
          _contrastRatio(AppColors.darkSuccess, background),
          greaterThanOrEqualTo(3),
          reason:
              '${AppColors.darkSuccess.toARGB32().toRadixString(16)} on '
              '${background.toARGB32().toRadixString(16)}',
        );
      }
    });

    test('outlineVariant should meet 3 to 1 non-text contrast', () {
      final colorScheme = buildDarkTheme().colorScheme;

      expect(colorScheme.outlineVariant, AppColors.darkOutline);
      expect(
        _contrastRatio(
          colorScheme.outlineVariant,
          colorScheme.surfaceContainerHighest,
        ),
        greaterThanOrEqualTo(3),
      );
    });

    test('does not silently fall back to the light palette', () {
      final dark = buildDarkTheme();
      final light = buildLightTheme();

      expect(dark.colorScheme.surface, isNot(light.colorScheme.surface));
      expect(dark.colorScheme.onSurface, isNot(light.colorScheme.onSurface));
    });
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
