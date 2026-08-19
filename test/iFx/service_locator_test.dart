import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/sos_location_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/speech_recognition_service.dart';

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
    });
  });
}
