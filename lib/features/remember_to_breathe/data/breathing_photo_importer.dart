import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data' show ByteData, BytesBuilder;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazilon/features/feel_good/data/image_picker_repository.dart'; // TODO: 0.11 inject via feel_good repository

/// A safe photo-import failure that never includes a path or media contents.
final class BreathingPhotoException implements Exception {
  const BreathingPhotoException({this.tooLarge = false});

  final bool tooLarge;

  @override
  String toString() => 'BreathingPhotoException(tooLarge: $tooLarge)';
}

/// Imports a bounded PNG through the existing picker without persisting paths.
///
/// This component performs no persistence. Its caller commits the new photo
/// only after import succeeds, preserving the previous selection on failure.
/// The existing picker contract still lives in the legacy Feel Good module;
/// breathing uses only its gallery pick, never its media or persistence APIs.
class BreathingPhotoImporter {
  BreathingPhotoImporter(this._picker);

  static const int maximumInputBytes = 20 * 1024 * 1024;
  static const int maximumOutputBytes = 512 * 1024;
  static const int maximumDimension = 768;

  final ImagePickerService _picker;

  /// Verifies retained media can still decode as a bounded, single-frame PNG.
  ///
  /// Persistence calls this on saved bytes too: a recognizable PNG signature
  /// alone does not prove that its compressed pixel data is readable.
  static Future<void> validatePhoto(String encoded) async {
    try {
      if (encoded.length > ((maximumOutputBytes + 2) ~/ 3) * 4) {
        throw const BreathingPhotoException(tooLarge: true);
      }
      final bytes = base64Decode(encoded);
      const signature = [137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length > maximumOutputBytes ||
          bytes.length < 33 ||
          !Iterable<int>.generate(8).every((i) => bytes[i] == signature[i])) {
        throw const BreathingPhotoException();
      }
      // PNG requires a 13-byte IHDR as its first chunk. Check dimensions before
      // a web codec can materialize an oversized, highly compressed frame.
      final header = ByteData.sublistView(bytes);
      if (header.getUint32(8) != 13 || header.getUint32(12) != 0x49484452) {
        throw const BreathingPhotoException();
      }
      final width = header.getUint32(16);
      final height = header.getUint32(20);
      if (width == 0 ||
          height == 0 ||
          width > maximumDimension ||
          height > maximumDimension) {
        throw const BreathingPhotoException();
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      ui.ImageDescriptor? descriptor;
      try {
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        final size = await _intrinsicSize(descriptor);
        if (size.width > maximumDimension || size.height > maximumDimension) {
          throw const BreathingPhotoException();
        }
        final codec = await descriptor.instantiateCodec();
        ui.Image? image;
        try {
          if (codec.frameCount != 1) {
            throw const BreathingPhotoException();
          }
          image = (await codec.getNextFrame()).image;
        } finally {
          image?.dispose();
          codec.dispose();
        }
      } finally {
        descriptor?.dispose();
        buffer.dispose();
      }
    } on BreathingPhotoException {
      rethrow;
    } catch (_) {
      throw const BreathingPhotoException();
    }
  }

  static Future<({int width, int height})> _intrinsicSize(
    ui.ImageDescriptor descriptor,
  ) async {
    if (!kIsWeb) {
      return (width: descriptor.width, height: descriptor.height);
    }
    // Encoded descriptor dimension getters are unsupported on Flutter web.
    // Decode only the first frame to inspect its dimensions before resizing.
    final codec = await descriptor.instantiateCodec();
    ui.Image? image;
    try {
      image = (await codec.getNextFrame()).image;
      return (width: image.width, height: image.height);
    } finally {
      image?.dispose();
      codec.dispose();
    }
  }

  /// Returns one normalized first-frame PNG, or null when picking is canceled.
  Future<String?> pickPhoto() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) {
        return null;
      }
      // Check before loading bytes; do not decode an oversized source.
      final declaredLength = await file.length();
      if (declaredLength < 0) {
        throw const BreathingPhotoException();
      }
      if (declaredLength > maximumInputBytes) {
        throw const BreathingPhotoException(tooLarge: true);
      }
      final bytes = await _readBounded(file, declaredLength);
      if (bytes.length > maximumInputBytes) {
        // The source could have changed between querying its size and reading.
        throw const BreathingPhotoException(tooLarge: true);
      }
      return base64Encode(await _normalize(bytes));
    } on BreathingPhotoException {
      rethrow;
    } catch (_) {
      throw const BreathingPhotoException();
    }
  }

  Future<Uint8List> _readBounded(XFile file, int declaredLength) async {
    // Web converts the requested Blob slice as one allocation. An explicit
    // end also bounds a native file that grows after the metadata check.
    var end = maximumInputBytes + 1;
    var retriedShortData = false;
    while (true) {
      final bytes = BytesBuilder(copy: false);
      StreamIterator<Uint8List>? chunks;
      var receivedChunk = false;
      var readFailed = false;
      try {
        chunks = StreamIterator(file.openRead(0, end));
        while (await chunks.moveNext()) {
          receivedChunk = true;
          final chunk = chunks.current;
          if (chunk.length > maximumInputBytes - bytes.length) {
            throw const BreathingPhotoException(tooLarge: true);
          }
          bytes.add(chunk);
        }
        return bytes.takeBytes();
      } on RangeError {
        readFailed = true;
        // cross_file's native fromData reader uses sublist and rejects an end
        // beyond its bytes. Retry only that pre-data case, once, still bounded.
        if (retriedShortData || receivedChunk) {
          rethrow;
        }
        retriedShortData = true;
        end = declaredLength;
      } catch (_) {
        readFailed = true;
        rethrow;
      } finally {
        if (chunks != null) {
          try {
            await chunks.cancel();
          } catch (_) {
            // Cleanup must not replace the original failure (notably tooLarge).
            if (!readFailed) {
              rethrow;
            }
          }
        }
      }
    }
  }

  Future<Uint8List> _normalize(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = await _intrinsicSize(descriptor);
      final longestEdge = math.max(size.width, size.height);
      var targetEdge = math.min(maximumDimension, longestEdge);
      while (true) {
        final scale = targetEdge / longestEdge;
        final codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (size.width * scale).round()),
          targetHeight: math.max(1, (size.height * scale).round()),
        );
        ui.Image? image;
        try {
          // Getting just the first frame intentionally flattens animated input.
          image = (await codec.getNextFrame()).image;
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) {
            throw const BreathingPhotoException();
          }
          if (data.lengthInBytes <= maximumOutputBytes) {
            return data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
          }
        } finally {
          image?.dispose();
          codec.dispose();
        }
        if (targetEdge == 1) {
          throw const BreathingPhotoException(tooLarge: true);
        }
        targetEdge = math.max(1, (targetEdge * 0.75).floor());
      }
    } finally {
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
