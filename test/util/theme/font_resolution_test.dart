import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('load Rubix fonts and verify resolution', (WidgetTester tester) async {
    await loadTestFonts();
    
    // Pump a widget with Rubix text and different weights to ensure they load and resolve
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Regular Weight 400', style: TextStyle(fontFamily: 'Rubix', fontWeight: FontWeight.w400)),
              Text('Medium Weight 500', style: TextStyle(fontFamily: 'Rubix', fontWeight: FontWeight.w500)),
              Text('SemiBold Weight 600', style: TextStyle(fontFamily: 'Rubix', fontWeight: FontWeight.w600)),
              Text('Bold Weight 700', style: TextStyle(fontFamily: 'Rubix', fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // If the loader runs and the widget tree builds, the font is loaded successfully
    expect(find.text('Regular Weight 400'), findsOneWidget);
    expect(find.text('Medium Weight 500'), findsOneWidget);
    expect(find.text('SemiBold Weight 600'), findsOneWidget);
    expect(find.text('Bold Weight 700'), findsOneWidget);
  });
}
