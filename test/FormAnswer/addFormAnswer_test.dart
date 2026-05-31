import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/FormAnswer/addFormAnswer.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _FakePersistentMemoryService implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;
  @override
  Future<void> reset() async {}
  @override
  Future<void> setItem(String key, PersistentMemoryType type, value) async {}
}

Widget _hostDialog({
  required UserInformation userInfo,
  required Function edit,
  required String text,
  Locale locale = const Locale('en'),
  Size size = const Size(800, 1200),
}) {
  return MultiProvider(
    providers: [ChangeNotifierProvider<UserInformation>.value(value: userInfo)],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: locale,
      home: ScreenUtilInit(
        designSize: size,
        builder: (context, _) => Scaffold(
          body: AddFormAnswer(index: 3, edit: edit, text: text),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation userInfo;

  setUp(() {
    userInfo = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
    );
  });

  testWidgets('renders the initial text in the editor', (tester) async {
    await tester.pumpWidget(
      _hostDialog(userInfo: userInfo, edit: (_, _) {}, text: 'hello'),
    );
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('cancel button closes the dialog without invoking edit', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserInformation>.value(value: userInfo),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('en'),
          home: ScreenUtilInit(
            designSize: const Size(800, 1200),
            builder: (context, _) => Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: ctx,
                    builder: (_) => AddFormAnswer(
                      index: 0,
                      edit: (i, t) => calls++,
                      text: 'initial',
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AddFormAnswer), findsOneWidget);

    // Tap the close button (first TextButton in the dialog).
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(find.byType(AddFormAnswer), findsNothing);
    expect(calls, 0);
  });

  testWidgets(
    'save with empty text fails validation; save with non-empty calls edit',
    (tester) async {
      int? capturedIndex;
      String? capturedText;

      await tester.pumpWidget(
        _hostDialog(
          userInfo: userInfo,
          edit: (i, t) {
            capturedIndex = i;
            capturedText = t;
          },
          text: '',
        ),
      );
      await tester.pumpAndSettle();

      // Press save while empty -> validator returns the error string and edit
      // is NOT called.
      final saveButton = find.byType(TextButton).last;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(capturedIndex, isNull);
      expect(capturedText, isNull);

      // Enter text and try again.
      await tester.enterText(find.byType(TextFormField), 'updated value');
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(capturedIndex, 3);
      expect(capturedText, 'updated value');
    },
  );

  testWidgets('renders on small screens (height adapts to width <= 400)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(380, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _hostDialog(
        userInfo: userInfo,
        edit: (_, _) {},
        text: 'small',
        size: const Size(380, 700),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddFormAnswer), findsOneWidget);
    expect(find.text('small'), findsOneWidget);
  });
}
