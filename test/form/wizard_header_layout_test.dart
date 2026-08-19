// The wizard header centres the progress dots on the screen and puts the
// back chevron and "save and exit" control on the edges. The dots are laid
// out independently of those controls, so a long label runs straight into
// them unless it is bounded by the space actually left beside the dots.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
  key: 'phone',
  header: 'h',
  subTitle: 's',
  midTitle: 'm',
  phoneNameTitle: 'n',
  phoneNumberTitle: 'p',
  phoneNames: const <String>[],
  phoneNumbers: const <String>[],
  savedPhoneNames: const <String>[],
  savedPhoneNumbers: const <String>[],
  phoneDescription: const <String>[],
);

Rect _dotsBounds(WidgetTester tester) {
  final dots = find.byType(AnimatedContainer);
  final first = tester.getRect(dots.first);
  final last = tester.getRect(dots.last);
  return Rect.fromLTRB(
    first.left < last.left ? first.left : last.left,
    first.top,
    first.right > last.right ? first.right : last.right,
    first.bottom,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => registerTestServices(locale: 'he'));
  tearDown(resetTestServices);

  for (final probe in const [
    ('he', 320.0),
    ('ar', 320.0),
    ('en', 320.0),
    ('he', 375.0),
    ('ar', 402.0),
  ]) {
    final languageCode = probe.$1;
    final width = probe.$2;

    testWidgets('header controls clear the progress dots at ${width.toInt()}px '
        '($languageCode)', (tester) async {
      // The view is set rather than the surface: setSurfaceSize resizes the
      // render surface but leaves MediaQuery reporting the old width, and
      // the header bound is computed from MediaQuery.
      await tester.binding.setSurfaceSize(null);
      tester.view.physicalSize = Size(width * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final phoneData = _phoneData();
      final user = UserInformation()..gender = 'other';
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserInformation>.value(value: user),
            ChangeNotifierProvider<AppInformation>.value(
              value: AppInformation(),
            ),
            ChangeNotifierProvider<PhonePageData>.value(value: phoneData),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(languageCode),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: buildLightTheme(),
            home: ScreenUtilInit(
              designSize: const Size(360, 690),
              child: FormProgressIndicator(
                phonePageData: phoneData,
                changeLocale: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      drainOverflowExceptions(tester);

      final dots = _dotsBounds(tester);
      for (final element in find.byType(TextButton).evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        if (rect.top > 80) {
          continue; // header band only
        }
        expect(
          rect.overlaps(dots),
          isFalse,
          reason: 'header control $rect runs into the progress dots $dots',
        );
      }
    });
  }

  test('side controls are bounded by the space left beside the dots', () {
    // 320px screen, 7 steps: 288 usable, 174 of it taken by the dots.
    expect(headerSideControlMaxWidth(320, 7), (288 - 174) / 2 - 8);
    // A screen narrower than the dots leaves nothing rather than a negative.
    expect(headerSideControlMaxWidth(180, 7), 0);
  });
}
