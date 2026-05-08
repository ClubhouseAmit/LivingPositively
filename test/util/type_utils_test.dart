import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/type_utils.dart';

void main() {
  group('TypeUtils.castToStringList', () {
    test('returns empty list for null', () {
      expect(TypeUtils.castToStringList(null), <String>[]);
    });

    test('casts a List<dynamic> of strings', () {
      final dynamic value = <dynamic>['a', 'b', 'c'];
      expect(TypeUtils.castToStringList(value), ['a', 'b', 'c']);
    });

    test('returns empty list for an empty List<dynamic>', () {
      final dynamic value = <dynamic>[];
      expect(TypeUtils.castToStringList(value), <String>[]);
    });

    test('throws on non-string element when cast forced', () {
      final dynamic value = <dynamic>[1, 2, 3];
      expect(() => TypeUtils.castToStringList(value), throwsA(isA<TypeError>()));
    });
  });

  group('TypeUtils.castToString', () {
    test('returns empty string for null', () {
      expect(TypeUtils.castToString(null), '');
    });

    test('returns string for non-null int', () {
      expect(TypeUtils.castToString(42), '42');
    });

    test('returns string for already-string value', () {
      expect(TypeUtils.castToString('hello'), 'hello');
    });

    test('returns string for bool', () {
      expect(TypeUtils.castToString(true), 'true');
    });
  });
}
