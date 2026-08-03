import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

// Initialize GetIt instance
final GetIt getIt = GetIt.instance;

void setupLocator() {
  // Register YoutubePlayer as a singleton for the VideoPlayerController interface
  getIt.registerLazySingleton<VideoPlayerPageFactory>(
      VideoPlayerPageFactoryImpl.new);
  getIt.registerLazySingleton<ImagePickerService>(
      ImagePickerServiceImpl.new);

  getIt.registerLazySingleton<FileService>(FileServiceImpl.new);
  getIt.registerLazySingleton<IncidentLoggerService>(SentryServiceImpl.new);
  getIt.registerLazySingleton<LocaleService>(LocaleServiceImpl.new);
  getIt.registerLazySingleton<AnalyticsService>(MixPanelService.new);
  getIt.registerLazySingleton<PersistentMemoryService>(
      SharedPreferencesService.new);
}
