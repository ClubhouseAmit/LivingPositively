import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_controller.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_page.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';

import '../../test_support/contract_persistent_memory_service.dart';

MoodMedicineController _controller(
  ContractPersistentMemoryService memory, {
  List<String> ids = const <String>['entry-1', 'custom-1'],
}) {
  final List<String> mutableIds = List<String>.from(ids);
  return MoodMedicineController(
    MoodMedicineStore(memory),
    idGenerator: () => mutableIds.removeAt(0),
  );
}

Widget _app({
  required MoodMedicineController controller,
  MoodMedicineInitialView initialView = MoodMedicineInitialView.insights,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: MoodMedicinePage(controller: controller, initialView: initialView),
  );
}

void _setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _setNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uses locale directionality for English and Hebrew', (
    WidgetTester tester,
  ) async {
    _setLargeScreen(tester);
    final MoodMedicineController english = _controller(
      ContractPersistentMemoryService(),
    );
    await english.load();
    await tester.pumpWidget(_app(controller: english));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(MoodMedicinePage))),
      TextDirection.ltr,
    );
    expect(find.text('Insights'), findsOneWidget);

    final MoodMedicineController hebrew = _controller(
      ContractPersistentMemoryService(),
    );
    await hebrew.load();
    await tester.pumpWidget(
      _app(controller: hebrew, locale: const Locale('he')),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(MoodMedicinePage))),
      TextDirection.rtl,
    );
    expect(find.byKey(const Key('moodMedicineInsights')), findsOneWidget);
  });

  testWidgets('preserves a failed check-in draft and exposes retry', (
    WidgetTester tester,
  ) async {
    _setLargeScreen(tester);
    final ContractPersistentMemoryService memory =
        ContractPersistentMemoryService();
    var failOnce = true;
    memory.onPersist = (_, PersistentMemoryType _, Object _) {
      if (failOnce) {
        failOnce = false;
        throw StateError('offline');
      }
    };
    final MoodMedicineController controller = _controller(memory);
    await controller.load();
    await tester.pumpWidget(
      _app(
        controller: controller,
        initialView: MoodMedicineInitialView.checkIn,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('moodMedicineMood4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moodMedicineSaveCheckIn')));
    await tester.pumpAndSettle();

    expect(controller.entries, isEmpty);
    expect(controller.pendingCheckInDraft, isNotNull);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(controller.entries, hasLength(1));
  });

  testWidgets('keeps retry available when a second persistence attempt fails', (
    WidgetTester tester,
  ) async {
    _setLargeScreen(tester);
    final ContractPersistentMemoryService memory =
        ContractPersistentMemoryService();
    var failuresRemaining = 2;
    memory.onPersist = (_, PersistentMemoryType _, Object _) {
      if (failuresRemaining > 0) {
        failuresRemaining -= 1;
        throw StateError('offline');
      }
    };
    final MoodMedicineController controller = _controller(memory);
    await controller.load();
    await tester.pumpWidget(
      _app(
        controller: controller,
        initialView: MoodMedicineInitialView.checkIn,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('moodMedicineMood4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moodMedicineSaveCheckIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(controller.hasPendingWrite, isTrue);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(controller.entries, hasLength(1));
    expect(controller.hasPendingWrite, isFalse);
  });

  testWidgets('manages default activities and creates a custom activity', (
    WidgetTester tester,
  ) async {
    _setLargeScreen(tester);
    final MoodMedicineController controller = _controller(
      ContractPersistentMemoryService(),
    );
    await controller.load();
    await tester.pumpWidget(
      _app(
        controller: controller,
        initialView: MoodMedicineInitialView.checkIn,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('moodMedicineMood3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage activities'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide').first);
    await tester.pumpAndSettle();
    expect(controller.hiddenDefaultActivityIds, contains('physical_activity'));

    await tester.tap(find.text('Add personal activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save activity'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an activity name.'), findsOneWidget);
    expect(controller.customActivities, isEmpty);
    await tester.enterText(find.byType(TextField).last, 'Gardening');
    await tester.tap(find.text('Save activity'));
    await tester.pumpAndSettle();
    expect(controller.customActivities.single.label, 'Gardening');
  });

  testWidgets(
    'shows one-point dashboard and private-by-default export controls',
    (WidgetTester tester) async {
      _setLargeScreen(tester);
      final MoodMedicineController controller = _controller(
        ContractPersistentMemoryService(),
      );
      await controller.load();
      await controller.saveCheckIn(
        MoodMedicineCheckInDraft(
          mood: 4,
          activityIds: const <String>['music'],
          note: 'Private thought',
        ),
        occurredAt: DateTime.now(),
      );
      await tester.pumpWidget(_app(controller: controller));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'One check-in is saved. More days will make the trend clearer.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('moodMedicineIncludeNotes')), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('moodMedicineIncludeNotes')),
            )
            .value,
        isFalse,
      );
      expect(find.text('Personal notes are not included.'), findsOneWidget);
    },
  );

  testWidgets('reconciles a failed activity hide after retry', (
    WidgetTester tester,
  ) async {
    _setLargeScreen(tester);
    final ContractPersistentMemoryService memory =
        ContractPersistentMemoryService();
    var failOnce = true;
    memory.onPersist = (_, PersistentMemoryType _, Object _) {
      if (failOnce) {
        failOnce = false;
        throw StateError('offline');
      }
    };
    final MoodMedicineController controller = _controller(memory);
    await controller.load();
    await tester.pumpWidget(
      _app(
        controller: controller,
        initialView: MoodMedicineInitialView.checkIn,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('moodMedicineMood3')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('moodMedicineActivityphysical_activity')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage activities'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide').first);
    await tester.pumpAndSettle();

    expect(controller.hasPendingWrite, isTrue);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(controller.hiddenDefaultActivityIds, contains('physical_activity'));

    await tester.tap(find.byKey(const Key('moodMedicineSaveCheckIn')));
    await tester.pumpAndSettle();
    expect(
      controller.entries.single.activityIds,
      isNot(contains('physical_activity')),
    );
  });

  testWidgets('renders the latest saved custom label for historical activity', (
    WidgetTester tester,
  ) async {
    _setLargeScreen(tester);
    final MoodMedicineController controller = _controller(
      ContractPersistentMemoryService(),
      ids: const <String>['custom-walk', 'old-entry', 'new-entry'],
    );
    await controller.load();
    final MoodMedicineCustomActivity? activity = await controller
        .addCustomActivity('Evening walk');
    expect(activity, isNotNull);
    final DateTime now = DateTime.now();
    await controller.saveCheckIn(
      MoodMedicineCheckInDraft(mood: 3, activityIds: <String>[activity!.id]),
      occurredAt: now.subtract(const Duration(hours: 1)),
    );
    await controller.editCustomActivity(activity.id, 'Morning walk');
    await controller.saveCheckIn(
      MoodMedicineCheckInDraft(mood: 4, activityIds: <String>[activity.id]),
      occurredAt: now,
    );
    await controller.deleteCustomActivity(activity.id);

    await tester.pumpWidget(_app(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Morning walk'), findsOneWidget);
    expect(find.text('Evening walk'), findsNothing);
  });

  testWidgets('keeps D.O.S.E. education readable in narrow Arabic layouts', (
    WidgetTester tester,
  ) async {
    _setNarrowScreen(tester);
    final MoodMedicineController controller = _controller(
      ContractPersistentMemoryService(),
    );
    await controller.load();
    await tester.pumpWidget(
      _app(
        controller: controller,
        initialView: MoodMedicineInitialView.education,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(MoodMedicinePage))),
      TextDirection.rtl,
    );
    expect(find.byKey(const Key('moodMedicineDoseItems')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
