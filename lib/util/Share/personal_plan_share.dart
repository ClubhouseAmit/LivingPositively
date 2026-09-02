import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/personal_plan_export_snapshot.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mazilon/util/PDF/create_pdf.dart';

/// Captures one source after its pending model saves finish.
///
/// An alternate source never waits on or copies another store's model. Edits
/// arriving during capture trigger another preparation attempt; later edits
/// cannot mutate the returned value. Continuous edits fail instead of hanging.
Future<PersonalPlanExportSnapshot> preparePersonalPlanExportSnapshot({
  UserInformation? userInformation,
  PersistentMemoryService? memoryService,
}) async {
  final source =
      memoryService ??
      userInformation?.service ??
      GetIt.instance<PersistentMemoryService>();
  final sourceUserInformation = identical(source, userInformation?.service)
      ? userInformation
      : null;
  for (var attempt = 0; attempt < 8; attempt++) {
    final categoriesBeforePreparation =
        sourceUserInformation?.pendingCustomCategoriesSave;
    final dreamsBeforePreparation =
        sourceUserInformation?.pendingDreamsAndGoalsSave;
    await sourceUserInformation?.prepareForPersonalPlanExport(
      memoryService: source,
    );
    if (!identical(
          categoriesBeforePreparation,
          sourceUserInformation?.pendingCustomCategoriesSave,
        ) ||
        !identical(
          dreamsBeforePreparation,
          sourceUserInformation?.pendingDreamsAndGoalsSave,
        )) {
      continue;
    }
    final categoriesSave = sourceUserInformation?.pendingCustomCategoriesSave;
    final dreamsSave = sourceUserInformation?.pendingDreamsAndGoalsSave;
    final revision = sourceUserInformation?.dreamsAndGoalsSaveRevision;
    final snapshot = await PersonalPlanExportSnapshot.capture(source);
    if (identical(
          categoriesSave,
          sourceUserInformation?.pendingCustomCategoriesSave,
        ) &&
        identical(
          dreamsSave,
          sourceUserInformation?.pendingDreamsAndGoalsSave,
        ) &&
        revision == sourceUserInformation?.dreamsAndGoalsSaveRevision) {
      return snapshot;
    }
  }
  throw StateError(
    'The Personal Plan kept changing during export preparation.',
  );
}

/// Shares the Personal Plan PDF export with the given [message] after stabilizing persistence state.
///
/// When provided, [userInformation] triggers awaited personal-plan preparation.
/// [fileService] overrides the default [FileService] resolved from [GetIt].
/// [memoryService] takes precedence over [UserInformation.service]. The selected
/// service is an independent source. Its data is captured without staging model
/// values into it. PDF generation consumes only that immutable capture.
///
/// Preparation, metadata, or sharing failures are caught, logged via [IncidentLoggerService],
/// and returned as `null` without throwing uncaught exceptions to callers.
Future<ShareResult?> sharePersonalPlanFile({
  required String message,
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required AppInformation appInformation,
  UserInformation? userInformation,
  FileService? fileService,
  PersistentMemoryService? memoryService,
  Set<String>? approvedPdfHosts,
}) async {
  try {
    final hosts = Set<String>.unmodifiable(
      (approvedPdfHosts ?? defaultApprovedPdfLinkHosts).map(
        (host) => host.trim().toLowerCase(),
      ),
    );
    final PersistentMemoryService? effectiveMemoryService =
        memoryService ?? userInformation?.service;
    final exportMetadata = buildPersonalPlanExportMetadata(
      appLocale,
      gender,
      username,
    );
    final service = fileService ?? GetIt.instance<FileService>();
    final sanitizedTexts = Map<String, String>.unmodifiable(
      sanitizeSharePdfTexts(appInformation.sharePDFtexts, approvedHosts: hosts),
    );
    final snapshot = await preparePersonalPlanExportSnapshot(
      userInformation: userInformation,
      memoryService: effectiveMemoryService,
    );
    return await service.share(
      message,
      exportMetadata.titles,
      exportMetadata.subTitles,
      sanitizedTexts,
      ShareFileType.PDF,
      mainTitle: exportMetadata.mainTitle,
      textDirection: appLocale.textDirection,
      memoryService: effectiveMemoryService,
      snapshot: snapshot,
      approvedPdfHosts: hosts,
    );
  } catch (error, stackTrace) {
    try {
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      }
    } catch (_) {}
    return null;
  }
}
