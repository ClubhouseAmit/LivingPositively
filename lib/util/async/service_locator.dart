import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/locale_service.dart';
import 'package:mazilon/features/feel_good/data/image_picker_repository.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_repository.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_source_link_service.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/features/wellness_tools/ui/video_player_page_factory.dart';
import 'package:mazilon/features/phone/data/sos_location_service.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/async/speech_recognition_service.dart';

import 'package:mazilon/util/async/file_service.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_repository.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_store.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';

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
  getIt.registerLazySingleton<GlobalKey<NavigatorState>>(
    () => GlobalKey<NavigatorState>(),
  );
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<MoodMedicineStore>(
    () => MoodMedicineStore(getIt<PersistentMemoryService>()),
  );
  getIt.registerLazySingleton<MoodMedicineRepository>(
    () => getIt<MoodMedicineStore>(),
  );
  getIt.registerLazySingleton<MoodMedicineReportExporter>(
    () => MoodMedicineReportExporter(
      incidentLoggerService: getIt<IncidentLoggerService>(),
    ),
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
      incidentLoggerService: getIt<IncidentLoggerService>(),
    ),
  );
  getIt.registerLazySingleton<BreathingStore>(
    () => BreathingStore(getIt<PersistentMemoryService>()),
  );
  getIt.registerLazySingleton<BreathingRepository>(
    () => getIt<BreathingStore>(),
  );
  getIt.registerLazySingleton<BreathingPhotoImporter>(
    () => BreathingPhotoImporter(getIt<ImagePickerService>()),
  );
  getIt.registerFactory<BreathingViewModel>(
    () => BreathingViewModel(
      getIt<BreathingRepository>(),
      photoImporter: getIt<BreathingPhotoImporter>(),
    ),
  );
}
