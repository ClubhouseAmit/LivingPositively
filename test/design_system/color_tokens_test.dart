import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `AppColorTokens.dark` must hold, for every field, the `dark`-prefixed
/// `AppColors` constant of the same name, and `light` the plain one. A
/// swapped or mistyped constant compiles fine, so it is checked here.
void main() {
  final String source = File(
    'lib/design_system/tokens/color_tokens.dart',
  ).readAsStringSync();

  Map<String, String> setFields(String name) {
    final RegExpMatch? set = RegExp(
      '^  $name\\(([^)]*)\\)[,;]',
      multiLine: true,
    ).firstMatch(source);
    expect(set, isNotNull, reason: 'no `$name` set in color_tokens.dart');
    return {
      for (final RegExpMatch m in RegExp(
        r'(\w+): AppColors\.(\w+),',
      ).allMatches(set!.group(1)!))
        m.group(1)!: m.group(2)!,
    };
  }

  // A value of another shape (`Color(0x…)`, `AppColors.x.withValues(…)`)
  // would be skipped by setFields in both sets alike, so count fields too.
  final int fieldCount = RegExp(
    r'^    required this\.\w+,',
    multiLine: true,
  ).allMatches(source).length;

  test('every field is a plain AppColors constant in both sets', () {
    expect(fieldCount, greaterThan(0));
    expect(setFields('light'), hasLength(fieldCount));
    expect(setFields('dark'), hasLength(fieldCount));
  });

  test('light uses the plain name for every field', () {
    final Map<String, String> light = setFields('light');
    expect(light, isNotEmpty);
    light.forEach((field, constant) => expect(constant, field));
  });

  test('dark uses the dark-prefixed name for every field', () {
    final Map<String, String> dark = setFields('dark');
    expect(dark.keys, setFields('light').keys);
    dark.forEach((field, constant) {
      expect(
        constant,
        'dark${field[0].toUpperCase()}${field.substring(1)}',
        reason: field,
      );
    });
  });
}
