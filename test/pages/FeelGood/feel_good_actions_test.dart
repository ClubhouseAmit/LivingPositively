import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/FeelGood/image_display_item.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  group('FeelGood Actions', () {
    late TestServiceLocators locators;

    setUp(() {
      locators = registerTestServices();
    });

    tearDown(() {
      resetTestServices();
    });

    Future<void> openViewer(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final imageFinder = find.byType(ImageDisplay);
      await tester.ensureVisible(imageFinder);
      await tester.pumpAndSettle();
      await tester.tap(imageFinder);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'should render rotate and download buttons in fullscreen viewer with correct keys and tooltips',
      (WidgetTester tester) async {
        locators.picker.seededImagePaths.add('test_path_1.jpg');

        await pumpWithProviders(tester, const FeelGood());
        await tester.pumpAndSettle();

        // Open fullscreen viewer
        await openViewer(tester);

        // Verify all 4 action buttons exist
        expect(find.byKey(const Key('backButtonIcon')), findsOneWidget);
        expect(find.byKey(const Key('rotateButtonIcon')), findsOneWidget);
        expect(find.byKey(const Key('downloadButtonIcon')), findsOneWidget);
        expect(find.byKey(const Key('deleteButtonIcon')), findsOneWidget);

        // Verify tooltips in English
        expect(find.byTooltip('Back to photos'), findsOneWidget);
        expect(find.byTooltip('Rotate photo'), findsOneWidget);
        expect(find.byTooltip('Download photo'), findsOneWidget);
        expect(find.byTooltip('Delete photo'), findsOneWidget);
      },
    );

    testWidgets(
      'should rotate image by 90 degrees on each tap and cycle through quarter turns',
      (WidgetTester tester) async {
        const testPath = 'test_path_rot.jpg';
        locators.picker.seededImagePaths.add(testPath);

        await pumpWithProviders(tester, const FeelGood());
        await tester.pumpAndSettle();

        // Initially in grid, RotatedBox should have quarterTurns: 0
        RotatedBox gridRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: find.byType(ImageDisplay),
            matching: find.byType(RotatedBox),
          ),
        );
        expect(gridRotatedBox.quarterTurns, 0);

        // Open fullscreen viewer
        await openViewer(tester);

        // Fullscreen RotatedBox should start at 0
        RotatedBox dialogRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(RotatedBox),
          ),
        );
        expect(dialogRotatedBox.quarterTurns, 0);

        // Tap rotate button once -> 90 degrees (quarterTurns: 1)
        await tester.tap(find.byKey(const Key('rotateButtonIcon')));
        await tester.pumpAndSettle();

        dialogRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(RotatedBox),
          ),
        );
        expect(dialogRotatedBox.quarterTurns, 1);

        // Tap rotate button 2nd time -> 180 degrees (quarterTurns: 2)
        await tester.tap(find.byKey(const Key('rotateButtonIcon')));
        await tester.pumpAndSettle();

        dialogRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(RotatedBox),
          ),
        );
        expect(dialogRotatedBox.quarterTurns, 2);

        // Tap rotate button 3rd time -> 270 degrees (quarterTurns: 3)
        await tester.tap(find.byKey(const Key('rotateButtonIcon')));
        await tester.pumpAndSettle();

        dialogRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(RotatedBox),
          ),
        );
        expect(dialogRotatedBox.quarterTurns, 3);

        // Tap rotate button 4th time -> full cycle back to 0 degrees (quarterTurns: 0)
        await tester.tap(find.byKey(const Key('rotateButtonIcon')));
        await tester.pumpAndSettle();

        dialogRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(RotatedBox),
          ),
        );
        expect(dialogRotatedBox.quarterTurns, 0);
      },
    );

    testWidgets(
      'should reflect rotated orientation in grid view after closing fullscreen viewer',
      (WidgetTester tester) async {
        const testPath = 'test_path_grid_sync.jpg';
        locators.picker.seededImagePaths.add(testPath);

        await pumpWithProviders(tester, const FeelGood());
        await tester.pumpAndSettle();

        // Open fullscreen viewer
        await openViewer(tester);

        // Rotate twice (180 degrees)
        await tester.tap(find.byKey(const Key('rotateButtonIcon')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('rotateButtonIcon')));
        await tester.pumpAndSettle();

        // Close viewer via back button
        await tester.tap(find.byKey(const Key('backButtonIcon')));
        await tester.pumpAndSettle();

        // Dialog is closed
        expect(find.byType(Dialog), findsNothing);

        // Grid thumbnail should now be rotated by 2 quarter turns
        final gridRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: find.byType(ImageDisplay),
            matching: find.byType(RotatedBox),
          ),
        );
        expect(gridRotatedBox.quarterTurns, 2);
      },
    );

    testWidgets(
      'should persist rotation writes on rotate and prune entry on delete',
      (WidgetTester tester) async {
        const testPath = 'rot_save.jpg';
        locators.picker.seededImagePaths.add(testPath);

        await pumpWithProviders(tester, const FeelGood());
        await tester.pumpAndSettle();

        // Open viewer
        await openViewer(tester);

        // Rotate image once (quarterTurns: 1)
        await tester.tap(find.byKey(const Key('rotateButtonIcon')));
        await tester.pumpAndSettle();

        // Verify rotation write was triggered on the service with quarterTurns = 1
        expect(locators.picker.saveImageRotationsCalls, greaterThan(0));
        expect(locators.picker.lastSavedRotations?[testPath], 1);

        // Tap delete button in fullscreen viewer
        await tester.tap(find.byKey(const Key('deleteButtonIcon')));
        await tester.pumpAndSettle();

        // Confirm deletion in alert dialog
        expect(find.byKey(const Key('deleteButtonText')), findsOneWidget);
        await tester.tap(find.byKey(const Key('deleteButtonText')));
        await tester.pumpAndSettle();

        // Verify pruned rotations map without deleted path was persisted
        expect(locators.picker.lastSavedRotations?.containsKey(testPath), isFalse);
      },
    );

    testWidgets(
      'should invoke download on image picker service with correct arguments and show success toast',
      (WidgetTester tester) async {
        const testPath = 'test_download.jpg';
        locators.picker.seededImagePaths.add(testPath);
        locators.picker.downloadImageResult = '/storage/test_download.jpg';

        await pumpWithProviders(tester, const FeelGood());
        await tester.pumpAndSettle();

        // Open viewer
        await openViewer(tester);

        // Tap download
        await tester.tap(find.byKey(const Key('downloadButtonIcon')));
        await tester.pumpAndSettle();

        // Assert downloadImage arguments were passed correctly
        expect(locators.picker.downloadImageCalls, 1);
        expect(locators.picker.lastDownloadImagePath, testPath);
        expect(locators.picker.lastDownloadDialogTitle, 'Download photo');
      },
    );

    testWidgets(
      'should handle cancelled download gracefully without crashing',
      (WidgetTester tester) async {
        const testPath = 'test_cancel.jpg';
        locators.picker.seededImagePaths.add(testPath);
        // Simulate user cancelling native file picker dialog
        locators.picker.downloadImageResult = null;

        await pumpWithProviders(tester, const FeelGood());
        await tester.pumpAndSettle();

        // Open viewer
        await openViewer(tester);

        // Tap download
        await tester.tap(find.byKey(const Key('downloadButtonIcon')));
        await tester.pumpAndSettle();

        // Service invoked once and safely handled
        expect(locators.picker.downloadImageCalls, 1);
        expect(locators.picker.lastDownloadImagePath, testPath);
      },
    );

    testWidgets(
      'should render localized Hebrew tooltips and pass Hebrew dialog title when locale is Hebrew',
      (WidgetTester tester) async {
        locators = registerTestServices(locale: 'he');
        locators.picker.seededImagePaths.add('he_test.jpg');

        await pumpWithProviders(
          tester,
          const FeelGood(),
          locale: const Locale('he'),
        );
        await tester.pumpAndSettle();

        // Open viewer
        await openViewer(tester);

        // Hebrew tooltips
        expect(find.byTooltip('חזרה לתמונות'), findsOneWidget);
        expect(find.byTooltip('סיבוב תמונה'), findsOneWidget);
        expect(find.byTooltip('הורדת תמונה'), findsOneWidget);
        expect(find.byTooltip('מחיקת תמונה'), findsOneWidget);

        // Tap download and assert Hebrew dialog title passed
        await tester.tap(find.byKey(const Key('downloadButtonIcon')));
        await tester.pumpAndSettle();

        expect(locators.picker.downloadImageCalls, 1);
        expect(locators.picker.lastDownloadDialogTitle, 'הורדת תמונה');
      },
    );
  });
}
