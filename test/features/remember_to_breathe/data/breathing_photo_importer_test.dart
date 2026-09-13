import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mocktail/mocktail.dart';

class _Picker extends Mock implements ImagePickerService {}

class _File extends Mock implements XFile {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BreathingPhotoImporter', () {
    late _Picker picker;
    late _File file;
    late BreathingPhotoImporter importer;

    setUp(() {
      picker = _Picker();
      file = _File();
      importer = BreathingPhotoImporter(picker);
      when(
        () => picker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => file);
    });

    void pickedBytes(Uint8List bytes) {
      when(file.length).thenAnswer((_) async => bytes.length);
      when(file.readAsBytes).thenAnswer((_) async => bytes);
    }

    test(
      'should return null after cancellation without reading or saving',
      () async {
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => null);
        expect(await importer.pickPhoto(), isNull);
        verifyNever(file.length);
        verifyNever(file.readAsBytes);
        verifyNoMoreInteractions(file);
      },
    );

    test('should reject an oversized input before loading its bytes', () async {
      when(file.length).thenAnswer((_) async => 20 * 1024 * 1024 + 1);
      await expectLater(
        importer.pickPhoto(),
        throwsA(
          isA<BreathingPhotoException>().having(
            (error) => error.tooLarge,
            'tooLarge',
            true,
          ),
        ),
      );
      verifyNever(file.readAsBytes);
    });

    test(
      'should reject a source that grows between size check and reading',
      () async {
        when(file.length).thenAnswer((_) async => 10);
        when(
          file.readAsBytes,
        ).thenAnswer((_) async => Uint8List(20 * 1024 * 1024 + 1));
        await expectLater(
          importer.pickPhoto(),
          throwsA(
            isA<BreathingPhotoException>().having(
              (error) => error.tooLarge,
              'tooLarge',
              true,
            ),
          ),
        );
      },
    );

    test(
      'should replace picker, read, and decoder errors with a safe failure',
      () async {
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenThrow(StateError('private/path.jpg'));
        await expectLater(
          importer.pickPhoto(),
          throwsA(isA<BreathingPhotoException>()),
        );
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => file);
        when(file.length).thenThrow(StateError('private/path.jpg'));
        await expectLater(
          importer.pickPhoto(),
          throwsA(isA<BreathingPhotoException>()),
        );
        pickedBytes(Uint8List.fromList([1, 2, 3]));
        await expectLater(
          importer.pickPhoto(),
          throwsA(isA<BreathingPhotoException>()),
        );
        expect(
          const BreathingPhotoException().toString(),
          'BreathingPhotoException(tooLarge: false)',
        );
      },
    );

    test(
      'should normalize a large image while preserving aspect ratio',
      () async {
        pickedBytes(await _png(1600, 800));
        final output = await importer.pickPhoto();
        final bytes = base64Decode(output!);
        final codec = await ui.instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        try {
          expect(image.width, 768);
          expect(image.height, 384);
          expect(bytes.length, lessThanOrEqualTo(512 * 1024));
          expect(codec.frameCount, 1);
        } finally {
          image.dispose();
          codec.dispose();
        }
      },
    );

    test('should retain a small image without upscaling', () async {
      pickedBytes(await _png(60, 120));
      final bytes = base64Decode((await importer.pickPhoto())!);
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      try {
        expect(image.width, 60);
        expect(image.height, 120);
      } finally {
        image.dispose();
        codec.dispose();
      }
    });

    test(
      'should reduce noisy PNGs again until output is within 512 KiB',
      () async {
        final source = await _png(768, 768, noisy: true);
        expect(source.length, greaterThan(512 * 1024));
        pickedBytes(source);
        final bytes = base64Decode((await importer.pickPhoto())!);
        final codec = await ui.instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        try {
          expect(bytes.length, lessThanOrEqualTo(512 * 1024));
          expect(image.width, lessThan(768));
          expect(image.width, image.height);
        } finally {
          image.dispose();
          codec.dispose();
        }
      },
    );

    test('should flatten animated input to the first frame', () async {
      final gif = Uint8List.fromList([
        71, 73, 70, 56, 57, 97, // GIF89a
        1, 0, 1, 0, 128, 0, 0, // 1x1, two global palette colors.
        0, 0, 0, 255, 255, 255,
        33, 249, 4, 0, 1, 0, 0, 0,
        44, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 68, 1, 0,
        33, 249, 4, 0, 1, 0, 0, 0,
        44, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 76, 1, 0,
        59,
      ]);
      final sourceCodec = await ui.instantiateImageCodec(gif);
      expect(sourceCodec.frameCount, 2);
      sourceCodec.dispose();
      pickedBytes(gif);
      final codec = await ui.instantiateImageCodec(
        base64Decode((await importer.pickPhoto())!),
      );
      final image = (await codec.getNextFrame()).image;
      try {
        expect(codec.frameCount, 1);
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(pixels!.buffer.asUint8List(), [0, 0, 0, 255]);
      } finally {
        image.dispose();
        codec.dispose();
      }
    });

    test(
      'should validate actual retained pixels and reject malformed or oversized PNGs',
      () async {
        await BreathingPhotoImporter.validatePhoto(
          base64Encode(await _png(20, 10)),
        );
        for (final encoded in [
          'bad base64',
          base64Encode([0, 1, 2]),
          base64Encode([137, 80, 78, 71, 13, 10, 26, 10]),
          base64Encode(await _png(769, 100)),
          base64Encode(await _png(768, 768, noisy: true)),
        ]) {
          await expectLater(
            BreathingPhotoImporter.validatePhoto(encoded),
            throwsA(isA<BreathingPhotoException>()),
          );
        }
      },
    );
  });
}

Future<Uint8List> _png(int width, int height, {bool noisy = false}) async {
  final pixels = Uint8List(width * height * 4);
  final random = Random(7);
  for (var index = 0; index < pixels.length; index += 4) {
    pixels[index] = noisy ? random.nextInt(256) : 30;
    pixels[index + 1] = noisy ? random.nextInt(256) : 120;
    pixels[index + 2] = noisy ? random.nextInt(256) : 70;
    pixels[index + 3] = 255;
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  final image = await completer.future;
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
  }
}
