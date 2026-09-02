import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Share/personal_plan_share.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/personal_plan_export_snapshot.dart';
import 'package:mazilon/util/userInformation.dart';

import 'package:mazilon/util/PDF/create_pdf.dart';

@immutable
class _PersonalPlanDownloadContext {
  final String localeName;
  final String textDirection;
  final String gender;
  final String username;
  final Map<String, String> sharePdfTexts;
  final String snapshotFingerprint;
  final PersistentMemoryService? memoryService;
  final FileService fileService;
  final Set<String> approvedPdfHosts;

  _PersonalPlanDownloadContext({
    required AppLocalizations appLocale,
    required this.gender,
    required this.username,
    required Map<String, String> sharePdfTexts,
    required this.fileService,
    required PersonalPlanExportSnapshot snapshot,
    required this.memoryService,
    Set<String>? approvedPdfHosts,
  }) : localeName = appLocale.localeName,
       textDirection = appLocale.textDirection,
       approvedPdfHosts = Set<String>.unmodifiable(
         (approvedPdfHosts ?? defaultApprovedPdfLinkHosts).map(
           (host) => host.trim().toLowerCase(),
         ),
       ),
       sharePdfTexts = Map<String, String>.unmodifiable(
         sanitizeSharePdfTexts(
           sharePdfTexts,
           approvedHosts: approvedPdfHosts ?? defaultApprovedPdfLinkHosts,
         ),
       ),
       snapshotFingerprint = snapshot.fingerprint;

  static int _computeMapHashCode(Map<String, String> map) {
    var hash = 0;
    for (final entry in map.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PersonalPlanDownloadContext &&
        other.localeName == localeName &&
        other.textDirection == textDirection &&
        other.gender == gender &&
        other.username == username &&
        mapEquals(other.sharePdfTexts, sharePdfTexts) &&
        other.snapshotFingerprint == snapshotFingerprint &&
        identical(other.memoryService, memoryService) &&
        identical(other.fileService, fileService) &&
        setEquals(other.approvedPdfHosts, approvedPdfHosts);
  }

  @override
  int get hashCode => Object.hash(
    localeName,
    textDirection,
    gender,
    username,
    _computeMapHashCode(sharePdfTexts),
    snapshotFingerprint,
    identityHashCode(memoryService),
    identityHashCode(fileService),
    Object.hashAllUnordered(approvedPdfHosts),
  );
}

final Map<_PersonalPlanDownloadContext, Future<String?>>
_activePersonalPlanDownloads =
    <_PersonalPlanDownloadContext, Future<String?>>{};

// Retain results while overlapping requests for this source are still capturing
// their data. Otherwise a fast renderer can finish before the second serialized
// capture reaches the deduplication check.
final Map<PersistentMemoryService, int> _pendingSourceCaptures = {};
final Set<_PersonalPlanDownloadContext> _completedDownloads = {};

void _releaseSourceCapture(PersistentMemoryService source) {
  final remaining = _pendingSourceCaptures[source]! - 1;
  if (remaining == 0) {
    _pendingSourceCaptures.remove(source);
    _removeCompletedDownloads(source);
  } else {
    _pendingSourceCaptures[source] = remaining;
  }
}

void _removeCompletedDownloads(PersistentMemoryService source) {
  if (_pendingSourceCaptures.containsKey(source)) return;
  _completedDownloads.removeWhere((key) {
    if (!identical(key.memoryService, source)) return false;
    _activePersonalPlanDownloads.remove(key);
    return true;
  });
}

/// Downloads the Personal Plan PDF export after stabilizing persistence state,
/// notifying the user of success or failure through standard toast feedback.
///
/// Preparation and download errors are caught, logged via [IncidentLoggerService],
/// and reported via the [AppLocalizations.downloadFailed] error toast.
/// User cancellation or unsupported platform outcomes return `null` without an error toast.
///
/// Concurrent requests with an identical immutable export context coalesce into a single
/// in-flight download operation to prevent duplicate file generations and repeated toasts,
/// while requests with different contexts execute independently.
Future<String?> downloadPersonalPlanFile({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required AppInformation appInformation,
  required FileService fileService,
  UserInformation? userInformation,
  PersistentMemoryService? memoryService,
  Set<String>? approvedPdfHosts,
}) async {
  PersistentMemoryService? requestSource;
  try {
    final texts = Map<String, String>.of(appInformation.sharePDFtexts);
    final hosts = Set<String>.of(
      approvedPdfHosts ?? defaultApprovedPdfLinkHosts,
    );
    final source =
        memoryService ??
        userInformation?.service ??
        GetIt.instance<PersistentMemoryService>();
    requestSource = source;
    _pendingSourceCaptures[source] = (_pendingSourceCaptures[source] ?? 0) + 1;
    final snapshot = await preparePersonalPlanExportSnapshot(
      userInformation: userInformation,
      memoryService: source,
    );
    final contextKey = _PersonalPlanDownloadContext(
      appLocale: appLocale,
      gender: gender,
      username: username,
      sharePdfTexts: texts,
      fileService: fileService,
      snapshot: snapshot,
      memoryService: source,
      approvedPdfHosts: hosts,
    );

    final existingDownload = _activePersonalPlanDownloads[contextKey];
    if (existingDownload != null) {
      _releaseSourceCapture(source);
      requestSource = null;
      return await existingDownload;
    }

    final downloadFuture =
        _executeDownloadPersonalPlanFile(
          appLocale: appLocale,
          gender: gender,
          username: username,
          sharePdfTexts: contextKey.sharePdfTexts,
          fileService: fileService,
          snapshot: snapshot,
          memoryService: contextKey.memoryService,
          approvedPdfHosts: contextKey.approvedPdfHosts,
        ).whenComplete(() {
          _completedDownloads.add(contextKey);
          _removeCompletedDownloads(source);
        });

    _activePersonalPlanDownloads[contextKey] = downloadFuture;
    _releaseSourceCapture(source);
    requestSource = null;
    return await downloadFuture;
  } catch (error, stackTrace) {
    await _reportDownloadFailure(error, stackTrace, appLocale, gender);
    return null;
  } finally {
    if (requestSource != null) {
      _releaseSourceCapture(requestSource);
    }
  }
}

Future<String?> _executeDownloadPersonalPlanFile({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required Map<String, String> sharePdfTexts,
  required FileService fileService,
  required PersonalPlanExportSnapshot snapshot,
  PersistentMemoryService? memoryService,
  Set<String>? approvedPdfHosts,
}) async {
  try {
    final exportMetadata = buildPersonalPlanExportMetadata(
      appLocale,
      gender,
      username,
    );
    final result = await fileService.download(
      exportMetadata.titles,
      exportMetadata.subTitles,
      sharePdfTexts,
      ShareFileType.PDF,
      mainTitle: exportMetadata.mainTitle,
      textDirection: appLocale.textDirection,
      memoryService: memoryService,
      snapshot: snapshot,
      approvedPdfHosts: approvedPdfHosts,
    );
    if (result != null) {
      await showToast(message: appLocale.finishedDownloading(gender));
    }
    return result;
  } catch (error, stackTrace) {
    await _reportDownloadFailure(error, stackTrace, appLocale, gender);
    return null;
  }
}

Future<void> _reportDownloadFailure(
  Object error,
  StackTrace stackTrace,
  AppLocalizations appLocale,
  String gender,
) async {
  try {
    if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
      await GetIt.instance<IncidentLoggerService>().captureLog(
        error,
        stackTrace: stackTrace,
      );
    }
  } catch (_) {}
  await showToast(message: appLocale.downloadFailed(gender));
}
