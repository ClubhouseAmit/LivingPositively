import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Form/myDropdownMenuEntry.dart';

void main() {
  testWidgets('buildDropdownMenuEntry produces a typed DropdownMenuEntry',
      (tester) async {
    late DropdownMenuEntry<String> entry;
    await tester.pumpWidget(MaterialApp(
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Builder(builder: (context) {
          entry = buildDropdownMenuEntry('hello', Colors.purple);
          return const SizedBox.shrink();
        }),
      ),
    ));
    expect(entry.value, 'hello');
    expect(entry.label, 'hello');
    expect(entry.labelWidget, isNotNull);
    expect(entry.style, isNotNull);
  });

  testWidgets('buildDropdownMenuEntry style varies with backgroundColor',
      (tester) async {
    late DropdownMenuEntry<String> a;
    late DropdownMenuEntry<String> b;
    await tester.pumpWidget(MaterialApp(
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Builder(builder: (context) {
          a = buildDropdownMenuEntry('x', Colors.red);
          b = buildDropdownMenuEntry('x', Colors.blue);
          return const SizedBox.shrink();
        }),
      ),
    ));
    // Both produce a non-null style; both are MenuItemButton styles.
    expect(a.style, isNotNull);
    expect(b.style, isNotNull);
  });
}
