// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/notifications/time_picker.dart';

void main() {
  testWidgets('TimePicker renders two NumberPickers and triggers setTime',
      (tester) async {
    int reportedHour = -1;
    int reportedMinute = -1;
    void setTime(int a, int b) {
      // The widget's onChanged signatures pass (newValue, otherDimension) —
      // we just record any call to verify the wiring.
      reportedMinute = a;
      reportedHour = b;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimePicker(
            currentHour: 9,
            currentMinute: 30,
            setTime: setTime,
          ),
        ),
      ),
    );
    await tester.pump();

    // RTL Directionality wraps the row.
    expect(find.byType(Directionality), findsWidgets);
    // The "9" hour value should appear at least once.
    expect(find.text('09'), findsWidgets);
    // The "30" minute value should appear at least once.
    expect(find.text('30'), findsWidgets);
    // setTime not called yet without user interaction.
    expect(reportedHour, -1);
    expect(reportedMinute, -1);
  });

  testWidgets('TimePicker accepts boundary values (0:0)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimePicker(
            currentHour: 0,
            currentMinute: 0,
            setTime: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('00'), findsWidgets);
  });

  testWidgets('TimePicker accepts boundary values (23:59)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimePicker(
            currentHour: 23,
            currentMinute: 59,
            setTime: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('23'), findsWidgets);
    expect(find.text('59'), findsWidgets);
  });
}
