import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_repository.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_store.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/sos_location_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/speech_recognition_service.dart';
import 'package:mocktail/mocktail.dart';

class _BreathingRepository extends Mock implements BreathingRepository {}

class _BreathingPhotoImporter extends Mock implements BreathingPhotoImporter {}

void main() {
  group('setupLocator', () {
    setUp(() async {
      await GetIt.instance.reset();
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    test('should register all expected services', () {
      setupLocator();

      expect(GetIt.instance.isRegistered<VideoPlayerPageFactory>(), isTrue);
      expect(GetIt.instance.isRegistered<ImagePickerService>(), isTrue);
      expect(GetIt.instance.isRegistered<FileService>(), isTrue);
      expect(GetIt.instance.isRegistered<IncidentLoggerService>(), isTrue);
      expect(GetIt.instance.isRegistered<LocaleService>(), isTrue);
      expect(GetIt.instance.isRegistered<AnalyticsService>(), isTrue);
      expect(GetIt.instance.isRegistered<PersistentMemoryService>(), isTrue);
      expect(GetIt.instance.isRegistered<SosLocationService>(), isTrue);
      expect(GetIt.instance.isRegistered<SpeechRecognitionService>(), isTrue);
      expect(GetIt.instance.isRegistered<BreathingStore>(), isTrue);
      expect(GetIt.instance.isRegistered<BreathingRepository>(), isTrue);
      expect(GetIt.instance.isRegistered<BreathingPhotoImporter>(), isTrue);
      expect(GetIt.instance.isRegistered<BreathingViewModel>(), isTrue);
    });

    test('should resolve registered services to the impl types', () {
      setupLocator();

      expect(GetIt.instance<LocaleService>(), isA<LocaleServiceImpl>());
      expect(GetIt.instance<IncidentLoggerService>(), isA<SentryServiceImpl>());
      expect(
        GetIt.instance<PersistentMemoryService>(),
        isA<SharedPreferencesService>(),
      );
      expect(GetIt.instance<AnalyticsService>(), isA<MixPanelService>());
      expect(GetIt.instance<FileService>(), isA<FileServiceImpl>());
      expect(
        GetIt.instance<SosLocationService>(),
        isA<GeolocatorSosLocationService>(),
      );
      expect(
        GetIt.instance<SpeechRecognitionService>(),
        isA<SpeechRecognitionServiceImpl>(),
      );
      expect(GetIt.instance<BreathingStore>(), isA<BreathingStore>());
      expect(
        GetIt.instance<BreathingRepository>(),
        same(GetIt.instance<BreathingStore>()),
      );
      expect(
        GetIt.instance<BreathingPhotoImporter>(),
        isA<BreathingPhotoImporter>(),
      );
      final model = GetIt.instance<BreathingViewModel>();
      addTearDown(model.dispose);
      expect(model, isA<BreathingViewModel>());
    });

    test('should return the same lazy singleton instance across resolves', () {
      setupLocator();

      final a = GetIt.instance<LocaleService>();
      final b = GetIt.instance<LocaleService>();
      expect(identical(a, b), isTrue);

      final sosLocationA = GetIt.instance<SosLocationService>();
      final sosLocationB = GetIt.instance<SosLocationService>();
      expect(identical(sosLocationA, sosLocationB), isTrue);

      final speechA = GetIt.instance<SpeechRecognitionService>();
      final speechB = GetIt.instance<SpeechRecognitionService>();
      expect(identical(speechA, speechB), isTrue);

      expect(
        GetIt.instance<BreathingStore>(),
        same(GetIt.instance<BreathingStore>()),
      );
      expect(
        GetIt.instance<BreathingRepository>(),
        same(GetIt.instance<BreathingRepository>()),
      );
      expect(
        GetIt.instance<BreathingPhotoImporter>(),
        same(GetIt.instance<BreathingPhotoImporter>()),
      );
    });

    test(
      'should create page-owned breathing models using registered collaborators',
      () async {
        setupLocator();
        final repository = _BreathingRepository();
        final importer = _BreathingPhotoImporter();
        final snapshot = BreathingSnapshot(
          settings: const BreathingSettings(
            background: BreathingBackground.beach,
            inhaleDuration: Duration(seconds: 5),
          ),
          sessions: const [],
        );
        const importFailure = BreathingPhotoException(tooLarge: true);
        when(repository.load).thenAnswer((_) async => snapshot);
        when(importer.pickPhoto).thenThrow(importFailure);

        // Keep the production view-model factory, replacing only its inputs.
        await GetIt.instance.unregister<BreathingRepository>();
        GetIt.instance.registerSingleton<BreathingRepository>(repository);
        await GetIt.instance.unregister<BreathingPhotoImporter>();
        GetIt.instance.registerSingleton<BreathingPhotoImporter>(importer);

        final model = GetIt.instance<BreathingViewModel>();
        final otherVisit = GetIt.instance<BreathingViewModel>();
        addTearDown(model.dispose);
        addTearDown(otherVisit.dispose);
        expect(model, isNot(same(otherVisit)));

        await model.load();
        expect(model.isReady, isTrue);
        expect(model.settings, same(snapshot.settings));
        expect(otherVisit.isReady, isFalse);
        verify(repository.load).called(1);

        model.openCustomization();
        await model.importPhoto();
        expect(model.error, same(importFailure));
        expect(model.draftSettings, same(snapshot.settings));
        verify(importer.pickPhoto).called(1);
      },
    );
  });
}
