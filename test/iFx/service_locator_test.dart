import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

void main() {
  group('setupLocator', () {
    setUp(() async {
      await GetIt.instance.reset();
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    test('registers all expected services', () {
      setupLocator();

      expect(GetIt.instance.isRegistered<VideoPlayerPageFactory>(), isTrue);
      expect(GetIt.instance.isRegistered<ImagePickerService>(), isTrue);
      expect(GetIt.instance.isRegistered<FileService>(), isTrue);
      expect(GetIt.instance.isRegistered<IncidentLoggerService>(), isTrue);
      expect(GetIt.instance.isRegistered<LocaleService>(), isTrue);
      expect(GetIt.instance.isRegistered<AnalyticsService>(), isTrue);
      expect(GetIt.instance.isRegistered<PersistentMemoryService>(), isTrue);
    });

    test('registered services resolve to the impl types', () {
      setupLocator();

      expect(GetIt.instance<LocaleService>(), isA<LocaleServiceImpl>());
      expect(GetIt.instance<IncidentLoggerService>(),
          isA<SentryServiceImpl>());
      expect(GetIt.instance<PersistentMemoryService>(),
          isA<SharedPreferencesService>());
      expect(GetIt.instance<AnalyticsService>(), isA<MixPanelService>());
      expect(GetIt.instance<FileService>(), isA<FileServiceImpl>());
    });

    test('lazy singletons return the same instance across resolves', () {
      setupLocator();

      final a = GetIt.instance<LocaleService>();
      final b = GetIt.instance<LocaleService>();
      expect(identical(a, b), isTrue);
    });
  });
}
