import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_repository.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_source_link_service.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/sos_location_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/speech_recognition_service.dart';

import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

// Initialize GetIt instance
final getIt = GetIt.instance;

void setupLocator() {
  // Register YoutubePlayer as a singleton for the VideoPlayerController interface
  getIt.registerLazySingleton<VideoPlayerPageFactory>(
    () => VideoPlayerPageFactoryImpl(),
  );
  getIt.registerLazySingleton<ImagePickerService>(
    () => ImagePickerServiceImpl(),
  );
  getIt.registerLazySingleton<IncidentLoggerService>(() => SentryServiceImpl());
  getIt.registerLazySingleton<SosLocationService>(
    () => GeolocatorSosLocationService(
      incidentLoggerService: getIt<IncidentLoggerService>(),
    ),
  );
  getIt.registerLazySingleton<SpeechRecognitionService>(
    () => SpeechRecognitionServiceImpl(),
  );

  getIt.registerLazySingleton<FileService>(() => FileServiceImpl());
  getIt.registerLazySingleton<LocaleService>(() => LocaleServiceImpl());
  getIt.registerLazySingleton<AnalyticsService>(() => MixPanelService());
  getIt.registerLazySingleton<PersistentMemoryService>(
    () => SharedPreferencesService(),
  );
  getIt.registerLazySingleton<MoodMedicineStore>(
    () => MoodMedicineStore(getIt<PersistentMemoryService>()),
  );
  getIt.registerLazySingleton<MoodMedicineRepository>(
    () => getIt<MoodMedicineStore>(),
  );
  getIt.registerLazySingleton<MoodMedicineReportExporter>(
    () => MoodMedicineReportExporter(),
  );
  getIt.registerLazySingleton<MoodMedicineReportExportService>(
    () => getIt<MoodMedicineReportExporter>(),
  );
  getIt.registerLazySingleton<MoodMedicineSourceLinkService>(
    () => const UrlLauncherMoodMedicineSourceLinkService(),
  );
  getIt.registerFactory<MoodMedicineViewModel>(
    () => MoodMedicineViewModel(
      getIt<MoodMedicineRepository>(),
      getIt<MoodMedicineReportExportService>(),
      sourceLinkService: getIt<MoodMedicineSourceLinkService>(),
    ),
  );
}
