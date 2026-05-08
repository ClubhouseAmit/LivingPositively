// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/SignIn/form_container.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('FormContainer renders a TextFormField', (tester) async {
    await tester.pumpWidget(_wrap(FormContainer(
      hintText: 'enter',
    )));
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('FormContainer accepts text via controller', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_wrap(FormContainer(
      controller: controller,
      fieldKey: const Key('input'),
    )));
    await tester.enterText(find.byKey(const Key('input')), 'hello');
    expect(controller.text, 'hello');
  });

  testWidgets('FormContainer hides text initially when isPasswordField=true',
      (tester) async {
    await tester.pumpWidget(_wrap(FormContainer(
      isPasswordField: true,
      fieldKey: const Key('pw'),
    )));
    // Eye-off icon present indicates obscured state
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('FormContainer toggles visibility on suffix tap',
      (tester) async {
    await tester.pumpWidget(_wrap(FormContainer(
      isPasswordField: true,
      fieldKey: const Key('pw'),
    )));
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('FormContainer shows no eye icon for non-password',
      (tester) async {
    await tester.pumpWidget(_wrap(FormContainer(
      isPasswordField: false,
      hintText: 'username',
    )));
    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
  });

  testWidgets('FormContainer does not obscure when isPasswordField=false',
      (tester) async {
    await tester.pumpWidget(_wrap(FormContainer(
      isPasswordField: false,
      fieldKey: const Key('plain'),
    )));
    // Visible-eye icon should be absent for plain fields
    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
  });

  testWidgets('FormContainer renders with custom inputType', (tester) async {
    await tester.pumpWidget(_wrap(FormContainer(
      inputType: TextInputType.emailAddress,
      fieldKey: const Key('email'),
    )));
    expect(find.byKey(const Key('email')), findsOneWidget);
  });

  testWidgets('FormContainer wires onFieldSubmitted', (tester) async {
    String? submitted;
    await tester.pumpWidget(_wrap(FormContainer(
      fieldKey: const Key('s'),
      onFieldSubmitted: (v) => submitted = v,
    )));
    await tester.enterText(find.byKey(const Key('s')), 'submitme');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submitted, 'submitme');
  });
}
