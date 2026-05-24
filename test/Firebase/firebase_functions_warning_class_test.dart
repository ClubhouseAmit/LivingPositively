// Direct unit coverage for the small `Warning` data class in
// lib/util/Firebase/firebase_functions.dart.
//
// `Warning` is only constructed inside `fetchWarnings`, which uses
// `FirebaseFirestore.instance` directly (no optional `firestore` named
// param), so the production call-site is unreachable from a unit-test
// without violating ADR-001's no-production-changes rule. The class itself
// however is plain Dart and can be instantiated directly to cover the
// constructor line and the two final fields.

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';

void main() {
  group('Warning', () {
    test('constructor stores text + warnings as-is', () {
      final w = Warning(text: 'pick-me', warnings: const ['a', 'b', 'c']);
      expect(w.text, 'pick-me');
      expect(w.warnings, ['a', 'b', 'c']);
    });

    test('warnings list can be empty', () {
      final w = Warning(text: '', warnings: const []);
      expect(w.text, '');
      expect(w.warnings, isEmpty);
    });
  });
}
