import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/about.dart';
import 'package:mazilon/pages/WellnessTools/wellnessTools.dart';
import 'package:image_picker/image_picker.dart';

class _FakeImagePickerService implements ImagePickerService {
  @override
  Future<void> deleteImages() async {}

  @override
  void deleteImage(int index, List<String> imagePaths) {}

  @override
  Image displayImage(String path, {BoxFit fit = BoxFit.none}) {
    throw UnimplementedError();
  }

  @override
  Future<void> getImage(String source, List<String> imagePaths) async {}

  @override
  Widget getOnlineImage(String url) {
    throw UnimplementedError();
  }

  @override
  Future<void> loadImagePaths(List<String> imagePaths) async {}

  @override
  Future<XFile?> pickImage({required ImageSource source}) async => null;

  @override
  Future<File> saveImagePaths(List<String> imagePaths) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> downloadImage(
    String imagePath, {
    String? fileName,
    String? dialogTitle,
  }) async => null;
}

class _FakeVideoPlayerPageFactory implements VideoPlayerPageFactory {
  @override
  Widget create({
    required Function(bool p1) onFullScreenChanged,
    required Map<String, List<String>> videoData,
  }) {
    return const SizedBox.shrink();
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<ImagePickerService>(_FakeImagePickerService());
    getIt.registerSingleton<VideoPlayerPageFactory>(
      _FakeVideoPlayerPageFactory(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('Arabic hard-coded string coverage', () {
    testWidgets(
      'About page does not keep the English version label in Arabic',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('ar'),
            home: About(version: '1.2.3'),
          ),
        );

        expect(
          find.text('Living Positively App Version : 1.2.3'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Wellness empty state does not keep the English copy in Arabic',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            builder: (context, child) {
              return MaterialApp(
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                locale: const Locale('ar'),
                home: WellnessTools(
                  isFullScreen: false,
                  setBool: (_) {},
                  videoData: const {
                    'videoId': <String>[],
                    'videoHeadline': <String>[],
                    'videoDescription': <String>[],
                  },
                ),
              );
            },
          ),
        );

        expect(
          find.text('No videos available for your locale, sorry.'),
          findsNothing,
        );
      },
    );
  });
}
