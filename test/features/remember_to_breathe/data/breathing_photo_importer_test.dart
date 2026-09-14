import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_repository.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mocktail/mocktail.dart';

class _Picker extends Mock implements ImagePickerService {}

class _File extends Mock implements XFile {}

class _Repository extends Mock implements BreathingRepository {}

class _DataFile extends XFile {
  _DataFile(super.bytes, {int? declaredLength})
    : super.fromData(length: declaredLength);

  final List<(int?, int?)> ranges = [];
  bool readAllBytes = false;

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    ranges.add((start, end));
    return super.openRead(start, end);
  }

  @override
  Future<Uint8List> readAsBytes() {
    readAllBytes = true;
    throw StateError('Unbounded acquisition is forbidden.');
  }
}

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
      when(
        () => file.openRead(0, 20 * 1024 * 1024 + 1),
      ).thenAnswer((_) => Stream.value(bytes));
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
        verify(() => picker.pickImage(source: ImageSource.gallery)).called(1);
        verifyNoMoreInteractions(picker);
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
      verifyNever(() => file.openRead(any(), any()));
    });

    test(
      'should reject negative length metadata without opening the file',
      () async {
        when(file.length).thenAnswer((_) async => -1);
        await expectLater(
          importer.pickPhoto(),
          throwsA(isA<BreathingPhotoException>()),
        );
        verifyNever(() => file.openRead(any(), any()));
        verifyNever(file.readAsBytes);
      },
    );

    test(
      'should import a real short in-memory file using only bounded ranges',
      () async {
        final png = await _png(20, 10);
        final selected = _DataFile(png);
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => selected);

        final result = (await importer.pickPhoto())!;
        await BreathingPhotoImporter.validatePhoto(result);
        expect(selected.ranges.first, (0, 20 * 1024 * 1024 + 1));
        expect(selected.ranges.length, inInclusiveRange(1, 2));
        if (selected.ranges.length == 2) {
          expect(selected.ranges.last, (0, png.length));
        }
        expect(selected.readAllBytes, isFalse);
        verify(() => picker.pickImage(source: ImageSource.gallery)).called(1);
        verifyNoMoreInteractions(picker);
      },
    );

    test(
      'should detect a real oversized file with understated metadata',
      () async {
        final selected = _DataFile(
          Uint8List(20 * 1024 * 1024 + 1),
          declaredLength: 1,
        );
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => selected);

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
        expect(selected.ranges, [(0, 20 * 1024 * 1024 + 1)]);
        expect(selected.readAllBytes, isFalse);
      },
    );

    test(
      'should accept exactly twenty MiB before normalizing its first frame',
      () async {
        final png = await _png(20, 10);
        final bytes = Uint8List(20 * 1024 * 1024)..setRange(0, png.length, png);
        final selected = _DataFile(bytes);
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => selected);

        final result = (await importer.pickPhoto())!;
        await BreathingPhotoImporter.validatePhoto(result);
        expect(base64Decode(result).length, lessThanOrEqualTo(512 * 1024));
        expect(selected.readAllBytes, isFalse);
      },
    );

    test(
      'should reject a source that grows between size check and reading',
      () async {
        when(file.length).thenAnswer((_) async => 10);
        var cancelled = false;
        var readPastLimit = false;
        Stream<Uint8List> growingSource() async* {
          try {
            final block = Uint8List(64 * 1024);
            for (var index = 0; index < 320; index++) {
              yield block;
            }
            yield Uint8List(1);
            readPastLimit = true;
            yield Uint8List(64 * 1024);
          } finally {
            cancelled = true;
          }
        }

        when(
          () => file.openRead(0, 20 * 1024 * 1024 + 1),
        ).thenAnswer((_) => growingSource());
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
        expect(cancelled, isTrue);
        expect(readPastLimit, isFalse);
        verify(() => file.openRead(0, 20 * 1024 * 1024 + 1)).called(1);
        verifyNever(file.readAsBytes);
      },
    );

    test(
      'should retry a pre-data range error only once at the checked length',
      () async {
        when(file.length).thenAnswer((_) async => 10);
        when(
          () => file.openRead(0, 20 * 1024 * 1024 + 1),
        ).thenAnswer((_) => Stream.error(RangeError('Invalid end.')));
        when(
          () => file.openRead(0, 10),
        ).thenAnswer((_) => Stream.error(RangeError('Still invalid.')));

        await expectLater(
          importer.pickPhoto(),
          throwsA(isA<BreathingPhotoException>()),
        );
        verify(file.length).called(1);
        verify(() => file.openRead(0, 20 * 1024 * 1024 + 1)).called(1);
        verify(() => file.openRead(0, 10)).called(1);
        verifyNoMoreInteractions(file);
      },
    );

    test('should not retry a range error after even an empty chunk', () async {
      when(file.length).thenAnswer((_) async => 10);
      var cancelled = false;
      Stream<Uint8List> source() async* {
        try {
          yield Uint8List(0);
          throw RangeError('Later failure.');
        } finally {
          cancelled = true;
        }
      }

      when(
        () => file.openRead(0, 20 * 1024 * 1024 + 1),
      ).thenAnswer((_) => source());

      await expectLater(
        importer.pickPhoto(),
        throwsA(isA<BreathingPhotoException>()),
      );
      expect(cancelled, isTrue);
      verify(file.length).called(1);
      verify(() => file.openRead(0, 20 * 1024 * 1024 + 1)).called(1);
      verifyNoMoreInteractions(file);
    });

    test(
      'should preserve an oversized-read failure when cancellation also fails',
      () async {
        when(file.length).thenAnswer((_) async => 10);
        var cancelled = false;
        final source = StreamController<Uint8List>();
        source.onListen = () => source.add(Uint8List(20 * 1024 * 1024 + 1));
        source.onCancel = () {
          cancelled = true;
          throw StateError('Cleanup failure.');
        };
        addTearDown(source.close);
        when(
          () => file.openRead(0, 20 * 1024 * 1024 + 1),
        ).thenAnswer((_) => source.stream);

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
        expect(cancelled, isTrue);
        verifyNever(file.readAsBytes);
      },
    );

    test(
      'should preserve the previous photo after cancellation or failed reading until replacement',
      () async {
        final previous = base64Encode(await _png(20, 10));
        final repository = _Repository();
        when(repository.load).thenAnswer(
          (_) async => BreathingSnapshot(
            settings: BreathingSettings(
              background: BreathingBackground.personal,
              personalPhotoBase64: previous,
            ),
            sessions: const [],
          ),
        );
        final model = BreathingViewModel(repository, photoImporter: importer);
        addTearDown(model.dispose);
        await model.load();
        model.openCustomization();
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => null);
        await model.importPhoto();
        expect(model.error, isNull);
        expect(model.draftSettings.personalPhotoBase64, previous);
        expect(model.settings.personalPhotoBase64, previous);
        when(
          () => picker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => file);
        when(file.length).thenAnswer((_) async => 10);
        var cancelled = false;
        Stream<Uint8List> source() async* {
          try {
            yield Uint8List.fromList([1, 2]);
            throw StateError('Private source became unavailable.');
          } finally {
            cancelled = true;
          }
        }

        when(
          () => file.openRead(0, 20 * 1024 * 1024 + 1),
        ).thenAnswer((_) => source());

        await model.importPhoto();
        expect(cancelled, isTrue);
        expect(model.error, isA<BreathingPhotoException>());
        expect(model.draftSettings.personalPhotoBase64, previous);
        expect(model.settings.personalPhotoBase64, previous);

        pickedBytes(await _png(30, 20));
        await model.importPhoto();
        expect(model.error, isNull);
        expect(model.draftSettings.personalPhotoBase64, isNot(previous));
        await BreathingPhotoImporter.validatePhoto(
          model.draftSettings.personalPhotoBase64!,
        );
        expect(model.settings.personalPhotoBase64, previous);
        verify(repository.load).called(1);
        verifyNoMoreInteractions(repository);
        verify(() => picker.pickImage(source: ImageSource.gallery)).called(3);
        verifyNoMoreInteractions(picker);
        verifyNever(file.readAsBytes);
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
        verify(() => picker.pickImage(source: ImageSource.gallery)).called(1);
        verifyNoMoreInteractions(picker);
        verifyNever(file.readAsBytes);
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

    test('should bound portrait and one-pixel-wide image dimensions', () async {
      for (final dimensions in [
        (width: 800, height: 1600, outputWidth: 384, outputHeight: 768),
        (width: 1, height: 1600, outputWidth: 1, outputHeight: 768),
      ]) {
        pickedBytes(await _png(dimensions.width, dimensions.height));
        final output = (await importer.pickPhoto())!;
        await BreathingPhotoImporter.validatePhoto(output);
        final codec = await ui.instantiateImageCodec(base64Decode(output));
        final image = (await codec.getNextFrame()).image;
        try {
          expect(image.width, dimensions.outputWidth);
          expect(image.height, dimensions.outputHeight);
        } finally {
          image.dispose();
          codec.dispose();
        }
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
      'should reject oversized retained PNGs before creating an image',
      () async {
        final oversized = await _png(2048, 2048);
        expect(oversized.length, lessThan(512 * 1024));
        final previousOnCreate = ui.Image.onCreate;
        var imagesCreated = 0;
        ui.Image.onCreate = (image) {
          imagesCreated++;
          previousOnCreate?.call(image);
        };
        try {
          await expectLater(
            BreathingPhotoImporter.validatePhoto(base64Encode(oversized)),
            throwsA(isA<BreathingPhotoException>()),
          );
          expect(imagesCreated, 0);
        } finally {
          ui.Image.onCreate = previousOnCreate;
        }
      },
    );

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
          base64Encode(
            Uint8List.fromList(await _png(20, 10))
              ..[12] = 0, // The first chunk must be IHDR.
          ),
          base64Encode(
            Uint8List.fromList(await _png(20, 10))
              ..[11] = 12, // IHDR must contain exactly 13 bytes.
          ),
          base64Encode(
            Uint8List.fromList(await _png(20, 10))
              ..[19] = 0, // Zero width is invalid even before codec validation.
          ),
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
