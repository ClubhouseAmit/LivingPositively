import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'wellnessTools.dart'; // Make sure this path is correct
import 'package:http/http.dart' as http;

// Create a MockClient using the Mockito package.
class MockClient extends Mock implements http.Client {}

void main() {
  // Instantiate the mock client.

  group('WellnessTools Widget Tests', () {
    testWidgets('WellnessTools displays video data correctly', (
      WidgetTester tester,
    ) async {
      // Mock video data
      final videoData = {
        'videoId': ['test1', "test2", "test3"],
        'videoHeadline': [
          'Test Video Title1',
          "Test Video Title2",
          "Test Video Title3",
        ],
        'videoDescription': [
          'Test Video Description1',
          "Test Video Description2",
          "Test Video Description3",
        ],
      };

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: WellnessTools(
            isFullScreen: false,
            setBool: (_) {},
            videoData: videoData,
            // Ensure your widget can accept and use the mockClient if necessary.
          ),
        ),
      );

      // Verify that the video headline and description are displayed.
      expect(find.text('Test Video Title1'), findsOneWidget);
      expect(find.text('Test Video Description1'), findsOneWidget);
      expect(find.byKey(Key("tap0")), findsNothing);
      expect(find.byKey(Key("tap1")), findsWidgets);
      expect(find.byKey(Key("tap2")), findsWidgets);

      await tester.tap(find.byKey(Key("tap1")));
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: 1));
      expect(find.byKey(Key("tap1")), findsNothing);
      expect(find.byKey(Key("tap0")), findsWidgets);
      expect(find.byKey(Key("tap2")), findsWidgets);
      await tester.tap(find.byKey(Key("tap0")));
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: 1));
      expect(find.byKey(Key("tap0")), findsNothing);
      expect(find.byKey(Key("tap1")), findsWidgets);
      expect(find.byKey(Key("tap2")), findsWidgets);
      await tester.tap(find.byKey(Key("tap2")));
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: 1));
      expect(find.byKey(Key("tap2")), findsNothing);
      expect(find.byKey(Key("tap0")), findsWidgets);
      expect(find.byKey(Key("tap1")), findsWidgets);
    });
  });
}
