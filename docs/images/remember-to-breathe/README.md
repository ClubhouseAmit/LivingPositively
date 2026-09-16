# Remember to Breathe production-widget captures

Captured on 2026-09-13 with Flutter 3.44.0's widget-test renderer at
420 × 900 logical pixels, device-pixel ratio 1, and normal text scale.
These are direct PNG exports of the production `BreathingPage` render tree.

The temporary harness used the production `buildLightTheme()`, localization
delegates, bundled Rubix fonts and Material icons, and bundled CC0 background
images. It mounted the page in a plain `Scaffold` with Menu's 16-pixel horizontal
inset. The surrounding Menu shell, including its SOS button and bottom
navigation, is outside these captures; its behavior is exercised by
`test/features/remember_to_breathe/ui/breathing_menu_test.dart`.

| Capture | State |
| --- | --- |
| [English landing](en-landing.png) | Initial landing page with the forest background. |
| [Hebrew paused practice](he-practice-paused.png) | Basic practice paused during the second cycle, with the beach background. |
| [Arabic customization](ar-background-customization.png) | First customization step with the monastery background selected. |

The harness used isolated in-memory settings and a controlled monotonic clock;
no personal photo, stress rating, or real history appears in these images.
Each capture checked for Flutter rendering exceptions. The temporary harness
was removed after rendering and is not part of the committed test suite.

Background authors, source URLs, and licenses are listed in
[`assets/images/breathing/manifest.json`](../../../assets/images/breathing/manifest.json).
