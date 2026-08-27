import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/file_save_utils.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

abstract class ImagePickerService {
  Future<XFile?> pickImage({required ImageSource source});
  Future<File> saveImagePaths(List<String> imagePaths);
  Future<void> getImage(String source, List<String> imagePaths);
  void deleteImage(int index, List<String> imagePaths);
  Future<void> loadImagePaths(List<String> imagePaths);
  Widget displayImage(String path, {BoxFit fit = BoxFit.none});
  Widget getOnlineImage(String url);
  Future<void> deleteImages();

  /// Downloads the image at [imagePath] to user-selected device storage.
  ///
  /// [imagePath] is the local filesystem path of the source image to download.
  /// [fileName] is an optional custom filename for the saved file. If omitted,
  /// a timestamped filename with the source image's file extension is generated.
  /// [dialogTitle] is an optional title displayed on the native save file dialog.
  ///
  /// Returns the destination file path returned by [FilePicker.saveFile] on
  /// success, or `null` if the user cancels, the source file does not exist,
  /// or a read/write error occurs.
  Future<String?> downloadImage(
    String imagePath, {
    String? fileName,
    String? dialogTitle,
  });

  /// Loads saved image rotations from persistent storage.
  Future<Map<String, int>> loadImageRotations();

  /// Saves image rotations to persistent storage.
  Future<void> saveImageRotations(Map<String, int> imageRotations);
}

class ImagePickerServiceImpl implements ImagePickerService {
  final ImagePicker _picker;
  final AnalyticsService? analyticsService;
  final IncidentLoggerService? loggerService;
  final PersistentMemoryService? persistentMemoryService;
  final Future<dynamic> Function({
    String? dialogTitle,
    String? fileName,
    FileType type,
    String? initialDirectory,
    Uint8List? bytes,
    List<String>? allowedExtensions,
  })? customFileSaver;

  ImagePickerServiceImpl({
    ImagePicker? picker,
    this.analyticsService,
    this.loggerService,
    this.persistentMemoryService,
    Future<dynamic> Function({
      String? dialogTitle,
      String? fileName,
      FileType type,
      String? initialDirectory,
      Uint8List? bytes,
      List<String>? allowedExtensions,
    })? fileSaver,
  })  : _picker = picker ?? ImagePicker(),
        customFileSaver = fileSaver;

  AnalyticsService? get _effectiveAnalyticsService =>
      analyticsService ??
      (GetIt.instance.isRegistered<AnalyticsService>()
          ? GetIt.instance<AnalyticsService>()
          : null);

  IncidentLoggerService? get _effectiveLoggerService =>
      loggerService ??
      (GetIt.instance.isRegistered<IncidentLoggerService>()
          ? GetIt.instance<IncidentLoggerService>()
          : null);

  PersistentMemoryService? get _effectiveMemoryService =>
      persistentMemoryService ??
      (GetIt.instance.isRegistered<PersistentMemoryService>()
          ? GetIt.instance<PersistentMemoryService>()
          : null);

  @override
  Future<XFile?> pickImage({required ImageSource source}) {
    return _picker.pickImage(source: source);
  }

  @override
  Future<void> deleteImages() async {
    List<String> tempPath = [];
    try {
      await loadImagePaths(tempPath);
    } catch (_) {
      // Best-effort cleanup during the Settings reset flow. loadImagePaths
      // now rethrows genuine read failures (and has already logged them); if
      // the manifest cannot be read we cannot enumerate files to delete, so
      // skip rather than abort the surrounding reset.
      return;
    }

    while (tempPath.isNotEmpty) {
      File(tempPath[0]).deleteSync();
      tempPath.removeAt(0);
      saveImagePaths(tempPath);
    }
  }

  @override
  Future<File> saveImagePaths(List<String> imagePaths) async {
    final file = await getImagePathFile();
    return file.writeAsString(imagePaths.join('\n'));
  }

  String _extractImageExtension(String filePath) {
    final base = filePath.split(RegExp(r'[/\\]')).last;
    final dotIndex = base.lastIndexOf('.');
    if (dotIndex != -1) {
      final ext = base.substring(dotIndex).toLowerCase();
      const validExtensions = {
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
        '.gif',
        '.heic',
        '.heif',
        '.bmp',
      };
      if (validExtensions.contains(ext)) {
        return ext;
      }
    }
    return '.jpg';
  }

  Future<void> _trackEventSafely(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    try {
      await _effectiveAnalyticsService?.trackEvent(eventName, properties);
    } catch (analyticsError, analyticsStackTrace) {
      try {
        await _effectiveLoggerService?.captureLog(
          analyticsError,
          stackTrace: analyticsStackTrace,
        );
      } catch (_) {
        // Telemetry and incident logging are strictly best-effort and must
        // never escape or fail the outer business operation.
      }
    }
  }

  @override
  Future<void> getImage(String source, List<String> imagePaths) async {
    ImageSource imageSource = source == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    try {
      final pickedFile = await _picker.pickImage(source: imageSource);

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final extension = _extractImageExtension(pickedFile.path);
        int counter = 0;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        String candidateName = '$timestamp$extension';
        var targetFile = File('${appDir.path}/$candidateName');
        while (await targetFile.exists()) {
          counter++;
          candidateName = '${timestamp}_$counter$extension';
          targetFile = File('${appDir.path}/$candidateName');
        }
        final savedImage = await File(
          pickedFile.path,
        ).copy(targetFile.path);
        imagePaths.add(savedImage.path);
        await saveImagePaths(imagePaths);
        await _trackEventSafely("Photo Added", {"Source": source});
      }
    } catch (error, stackTrace) {
      debugPrint("errored");
      await _effectiveLoggerService?.captureLog(error, stackTrace: stackTrace);
    }
  }

  @override
  void deleteImage(int index, List<String> imagePaths) {
    File(imagePaths[index]).deleteSync();
    imagePaths.removeAt(index);
    saveImagePaths(imagePaths);
  }

  @override
  Future<void> loadImagePaths(List<String> imagePaths) async {
    try {
      final file = await getImagePathFile();
      // First run / nothing saved yet is the EMPTY state, not an error: the
      // manifest file simply does not exist. Return normally so the Feel Good
      // grid renders its add affordance and AsyncStateView stays out of its
      // error branch.
      if (!await file.exists()) {
        return;
      }

      String contents = await file.readAsString();

      imagePaths.addAll(
        contents.split('\n').where((path) => path.isNotEmpty).toList(),
      );
    } catch (error, stackTrace) {
      await _effectiveLoggerService?.captureLog(error, stackTrace: stackTrace);
      // A manifest that exists but cannot be read (corruption, permission,
      // decode failure) is a genuine failure. Phase E (ADR-005 §Decision
      // step 5): rethrow so the caller's error UI surfaces it with a retry,
      // instead of swallowing it and rendering an empty grid (UX_GAPS.md
      // §3.10). The previous `imagePaths = []` reassigned the local parameter
      // and was a no-op.
      rethrow;
    }
  }

  Future<File> getImagePathFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/imagePaths.txt');
  }

  @override
  Image displayImage(String path, {BoxFit fit = BoxFit.none}) {
    return Image.file(File(path), fit: fit);
  }

  @override
  getOnlineImage(String url) {
    return Image.network(url);
  }

  /// Normalizes platform-specific save results ([String] or [Uri]) to a destination string.
  static String? normalizeSavedFileDestination(dynamic result) =>
      FileSaveUtils.normalizeSavedFileDestination(result);

  /// Backwards-compatible alias for [normalizeSavedFileDestination].
  static String? normalizeSavedFilePath(dynamic result) =>
      normalizeSavedFileDestination(result);

  @override
  Future<String?> downloadImage(
    String imagePath, {
    String? fileName,
    String? dialogTitle,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }
      final bytes = await file.readAsBytes();
      final extension = _extractImageExtension(imagePath);
      final name = fileName ??
          'feel_good_${DateTime.now().millisecondsSinceEpoch}$extension';
      final customImageFileSaver = customFileSaver;
      final String? savedFilePath;
      if (customImageFileSaver != null) {
        final dynamic rawResult = await customImageFileSaver(
          dialogTitle: dialogTitle ?? 'Save image',
          fileName: name,
          bytes: bytes,
        );
        savedFilePath = normalizeSavedFileDestination(rawResult);
      } else {
        final dynamic rawResult = await FilePicker.saveFile(
          dialogTitle: dialogTitle ?? 'Save image',
          fileName: name,
          bytes: bytes,
        );
        savedFilePath = normalizeSavedFileDestination(rawResult);
      }
      if (savedFilePath != null) {
        await _trackEventSafely("Photo downloaded");
      }
      return savedFilePath;
    } catch (error, stackTrace) {
      await _effectiveLoggerService?.captureLog(error, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<Map<String, int>> loadImageRotations() async {
    final rotations = <String, int>{};
    try {
      final service = _effectiveMemoryService;
      if (service != null) {
        final serializedRotationEntries = await service.getItem(
          'feelGoodImageRotations',
          PersistentMemoryType.StringList,
        );
        if (serializedRotationEntries is List<dynamic>) {
          for (final serializedRotationEntry in serializedRotationEntries) {
            if (serializedRotationEntry is String) {
              final parts = serializedRotationEntry.split(':');
              if (parts.length >= 2) {
                final rotationQuarterTurns = int.tryParse(parts.last);
                final path = parts.sublist(0, parts.length - 1).join(':');
                if (rotationQuarterTurns != null) {
                  final normalizedQuarterTurns =
                      ((rotationQuarterTurns % 4) + 4) % 4;
                  rotations[path] = normalizedQuarterTurns;
                }
              }
            }
          }
        }
      }
    } catch (error, stackTrace) {
      await _effectiveLoggerService?.captureLog(error, stackTrace: stackTrace);
    }
    return rotations;
  }

  @override
  Future<void> saveImageRotations(Map<String, int> imageRotations) async {
    try {
      final service = _effectiveMemoryService;
      if (service != null) {
        final serializedRotationEntries = imageRotations.entries
            .map((e) => '${e.key}:${((e.value % 4) + 4) % 4}')
            .toList();
        await service.setItem(
          'feelGoodImageRotations',
          PersistentMemoryType.StringList,
          serializedRotationEntries,
        );
      }
    } catch (error, stackTrace) {
      await _effectiveLoggerService?.captureLog(error, stackTrace: stackTrace);
    }
  }
}
