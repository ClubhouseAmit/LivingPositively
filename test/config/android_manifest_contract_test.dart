import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidManifest', () {
    test('should declare SMS composer package visibility', () async {
      final manifest = await File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsString();

      expect(_hasSmsComposerVisibilityQuery(manifest), isTrue);
    });

    test('should reject SMS visibility declarations outside queries', () {
      const misplaced = '''
<manifest>
  <queries></queries>
  <application>
    <intent>
      <action android:name="android.intent.action.SENDTO" />
      <data android:scheme="smsto" />
    </intent>
  </application>
</manifest>
''';

      expect(_hasSmsComposerVisibilityQuery(misplaced), isFalse);
    });

    test('should reject an intent nested below a queries child', () {
      const nested = '''
<manifest>
  <queries>
    <provider>
      <intent>
        <action android:name="android.intent.action.SENDTO" />
        <data android:scheme="smsto" />
      </intent>
    </provider>
  </queries>
</manifest>
''';

      expect(_hasSmsComposerVisibilityQuery(nested), isFalse);
    });

    test('should reject malformed query XML', () {
      const malformed = '''
<manifest>
  <queries>
    <intent>
      <action android:name="android.intent.action.SENDTO" />
      <data android:scheme="smsto" />
    </provider>
  </queries>
</manifest>
''';

      expect(_hasSmsComposerVisibilityQuery(malformed), isFalse);
    });
  });
}

bool _hasSmsComposerVisibilityQuery(String manifest) {
  final queries = RegExp(
    r'<queries\b[^>]*>([\s\S]*?)</queries>',
  ).firstMatch(manifest)?.group(1);
  if (queries == null) return false;

  return _directChildElements(queries, 'intent').any((intent) {
    final body = intent
        .replaceFirst(RegExp(r'^<intent\b[^>]*>'), '')
        .replaceFirst(RegExp(r'</intent>$'), '');
    final actions = _directChildElements(body, 'action');
    final data = _directChildElements(body, 'data');
    return actions.any(
          (element) => element.contains(
            'android:name="android.intent.action.SENDTO"',
          ),
        ) &&
        data.any(
          (element) => element.contains('android:scheme="smsto"'),
        );
  });
}

List<String> _directChildElements(String xml, String targetName) {
  final tags = RegExp(
    r'<\s*(/?)\s*([A-Za-z_][A-Za-z0-9_.:-]*)\b[^>]*?>',
  ).allMatches(xml);
  final openElements = <String>[];
  final elements = <String>[];
  int? targetStart;

  for (final tag in tags) {
    final closing = tag.group(1)!.isNotEmpty;
    final name = tag.group(2)!;
    final selfClosing = tag.group(0)!.trimRight().endsWith('/>');
    if (closing) {
      if (openElements.isEmpty || openElements.last != name) return const [];
      openElements.removeLast();
      if (name == targetName && openElements.isEmpty && targetStart != null) {
        elements.add(xml.substring(targetStart, tag.end));
        targetStart = null;
      }
      continue;
    }

    if (openElements.isEmpty && name == targetName) {
      if (selfClosing) {
        elements.add(tag.group(0)!);
      } else {
        targetStart = tag.start;
      }
    }
    if (!selfClosing) openElements.add(name);
  }
  return openElements.isEmpty ? elements : const [];
}
