// Phase D regression suite (ADR-005 §Decision step 4).
//
// These tests pin the contract between the new `AppColors` token layer
// and the legacy palette/buttons that the audit (`docs/UX_GAPS.md §1.1`,
// §1.2) called out. They are deliberately tight: each test fails if a
// future refactor silently drifts the token values, removes the legacy
// forwarders, or reverts `myButtonStyle3` to a raw Material colour.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/async/app_theme.dart';

void main() {
  group('AppColors semantic tokens', () {
    // #431: the token hex values are checked against Figma when they change;
    // what this pins is that every legacy name forwards to a Figma token, so
    // the aliases can be deleted without a visual change.
    test('legacy light names forward to Figma tokens', () {
      expect(AppColors.primary, AppColors.accentPrimary);
      expect(AppColors.onPrimary, AppColors.contentOnAccent);
      expect(AppColors.secondary, AppColors.accentContainer);
      expect(AppColors.onSecondary, AppColors.accentOnContainer);
      expect(AppColors.surface, AppColors.surfaceRaised);
      expect(AppColors.white, AppColors.surfaceRaisedHigh);
      expect(AppColors.onSurface, AppColors.contentPrimary);
      expect(AppColors.error, AppColors.statusDanger);
      expect(AppColors.onError, AppColors.contentOnAccent);
      expect(AppColors.pageBackground, AppColors.surfaceCanvas);
      expect(AppColors.success, AppColors.statusSuccess);
      expect(AppColors.onSuccess, AppColors.contentOnAccent);
      expect(AppColors.neutralLight, AppColors.effectHairline);
      expect(AppColors.neutralDark, AppColors.contentSecondary);
      expect(AppColors.mutedForeground, AppColors.contentSecondary);
    });

    test('legacy dark names forward to Figma tokens', () {
      expect(AppColors.darkPrimary, AppColors.darkAccentPrimary);
      expect(AppColors.darkOnPrimary, AppColors.darkContentOnAccent);
      expect(AppColors.darkSecondary, AppColors.darkAccentContainer);
      expect(AppColors.darkOnSecondary, AppColors.darkAccentOnContainer);
      expect(AppColors.darkPageBackground, AppColors.darkSurfaceCanvas);
      expect(AppColors.darkNavBackground, AppColors.darkSurfaceRaised);
      expect(AppColors.darkSurface, AppColors.darkSurfaceRaised);
      expect(AppColors.darkSurfaceContainer, AppColors.darkSurfaceRaisedHigh);
      expect(AppColors.darkOnSurface, AppColors.darkContentPrimary);
      expect(AppColors.darkError, AppColors.darkStatusDanger);
      expect(AppColors.darkOnError, AppColors.darkContentOnAccent);
      expect(AppColors.darkSuccess, AppColors.darkStatusSuccess);
      expect(AppColors.darkOnSuccess, AppColors.darkContentOnAccent);
      expect(AppColors.darkOutline, AppColors.darkContentSecondary);
      expect(AppColors.darkLogoOutline, const Color(0xFFFFFFFF));
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

    test('keeps Material 2 + Heebo font family', () {
      // The brand button styles in styles.dart target Material 2
      // (custom RoundedRectangleBorder + TextButton.styleFrom). A
      // silent flip to Material 3 would visually break them.
      final theme = buildLightTheme();
      expect(theme.useMaterial3, isFalse);
      expect(theme.brightness, Brightness.light);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Heebo');
      expect(theme.scaffoldBackgroundColor, AppColors.pageBackground);
    });
  });

  group('buildDarkTheme', () {
    test('exposes the accessible dark palette via ColorScheme', () {
      final dark = buildDarkTheme();

      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme, appDarkColorScheme);
      expect(dark.colorScheme.primary, AppColors.darkAccentPrimary);
      expect(dark.primaryColor, AppColors.darkAccentPrimary);
      expect(dark.colorScheme.onPrimary, AppColors.darkContentOnAccent);
      expect(dark.colorScheme.secondary, AppColors.darkAccentContainer);
      expect(dark.colorScheme.onSecondary, AppColors.darkAccentOnContainer);
      expect(dark.colorScheme.tertiary, AppColors.darkStatusSuccess);
      expect(dark.colorScheme.onTertiary, AppColors.darkContentOnAccent);
      expect(dark.colorScheme.surface, AppColors.darkSurfaceRaised);
      expect(dark.colorScheme.onSurface, AppColors.darkContentPrimary);
      expect(dark.colorScheme.error, AppColors.darkStatusDanger);
      expect(dark.colorScheme.onError, AppColors.darkContentOnAccent);
      expect(dark.colorScheme.outline, AppColors.darkContentSecondary);
      expect(dark.colorScheme.outlineVariant, AppColors.darkEffectHairline);
      expect(
        dark.colorScheme.surfaceContainerHighest,
        AppColors.darkSurfaceRaisedHighest,
      );
      expect(dark.scaffoldBackgroundColor, AppColors.darkSurfaceCanvas);
      expect(dark.canvasColor, AppColors.darkSurfaceRaised);
      expect(dark.cardColor, AppColors.darkSurfaceRaisedHigh);
      expect(dark.bottomAppBarTheme.color, AppColors.darkSurfaceRaised);
      expect(dark.appBarTheme.backgroundColor, AppColors.darkSurfaceRaised);
      expect(dark.appBarTheme.foregroundColor, AppColors.darkContentPrimary);
      expect(
        dark.inputDecorationTheme.fillColor,
        AppColors.darkSurfaceRaisedHigh,
      );
      expect(dark.inputDecorationTheme.filled, isTrue);
    });

    test('text pairs should meet 4.5 to 1 contrast', () {
      final pairs = <(Color, Color)>[
        (AppColors.darkContentPrimary, AppColors.darkSurfaceRaised),
        (AppColors.darkContentPrimary, AppColors.darkSurfaceRaisedHigh),
        // darkContentOnAccent on darkAccentPrimary: skipped test below (#433).
        (AppColors.darkAccentOnContainer, AppColors.darkAccentContainer),
        (AppColors.darkContentOnAccent, AppColors.darkStatusDanger),
        (AppColors.darkContentOnAccent, AppColors.darkStatusSuccess),
        (AppColors.darkContentSecondary, AppColors.darkSurfaceRaised),
        (AppColors.darkContentSecondary, AppColors.darkSurfaceRaisedHigh),
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

    test(
      'dark logo outline should meet 4.5 to 1 contrast on dark surfaces',
      () {
        for (final background in [
          AppColors.darkPageBackground,
          AppColors.darkNavBackground,
          AppColors.darkSurface,
          AppColors.darkSurfaceContainer,
        ]) {
          expect(
            _contrastRatio(AppColors.darkLogoOutline, background),
            greaterThanOrEqualTo(4.5),
            reason:
                '${AppColors.darkLogoOutline.toARGB32().toRadixString(16)} on '
                '${background.toARGB32().toRadixString(16)}',
          );
        }
      },
    );

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

    test(
      'primary button label should meet 4.5 to 1 contrast',
      () {
        for (final (foreground, background) in <(Color, Color)>[
          (AppColors.contentOnAccent, AppColors.accentPrimary),
          (AppColors.darkContentOnAccent, AppColors.darkAccentPrimary),
        ]) {
          expect(
            _contrastRatio(foreground, background),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
      skip: 'Known gap: Figma pair is 4.12/4.29 to 1, waiting on design (#433)',
    );

    test(
      'input border should meet 3 to 1 non-text contrast',
      () {
        final colorScheme = buildDarkTheme().colorScheme;
        expect(
          _contrastRatio(
            colorScheme.outlineVariant,
            colorScheme.surfaceContainerHighest,
          ),
          greaterThanOrEqualTo(3),
        );
      },
      skip: 'Known gap: Figma hairline is 1.4 to 1, waiting on design (#433)',
    );

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
