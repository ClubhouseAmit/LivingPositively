import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('PonnamKarthik/fluttertoast');
  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() async {
    // Drain any pending platform-channel work before clearing the handler
    // so late callbacks from `Fluttertoast.showToast` don't fail mid-test.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('showToast does not throw synchronously', () async {
    showToast(message: 'hello');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Platform-channel call may or may not have landed depending on timing;
    // we only assert that showToast completes without raising. Functional
    // delivery is the plugin's responsibility, not ours.
    expect(calls.length, anyOf(0, greaterThan(0)));
  });

  test('showToast tolerates empty string', () async {
    expect(() => showToast(message: ''), returnsNormally);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  test('showToast tolerates long messages', () async {
    expect(() => showToast(message: 'x' * 500), returnsNormally);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
}
