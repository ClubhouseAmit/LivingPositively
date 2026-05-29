// Phase E regression suite (ADR-005 §Decision step 5) — production path.
//
// The shared AsyncStateView only earns its keep if the REAL Feel Good load
// path can actually reach the error-with-retry branch. Before the Phase E
// service fix, ImagePickerServiceImpl.loadImagePaths swallowed every
// exception, so the future always resolved and the error branch was dead
// code (the empty-grid-on-failure bug, UX_GAPS.md §3.10).
//
// This test drives the real FeelGood widget with an ImagePickerService whose
// loadImagePaths rejects, and asserts the error UI appears — then that a
// retry recovers once the service stops failing. No stubbed widgets (see the
// team's real-widget test-pattern note).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';

import '../../helpers/widget_test_scaffold.dart';

/// Picker whose [loadImagePaths] throws until [failLoad] is flipped to false,
/// mirroring a manifest that exists but cannot be read.
class _FlakyImagePickerService implements ImagePickerService {
  // Starts failing; flipped to false in the recovery test to simulate the
  // manifest becoming readable again.
  bool failLoad = true;

  @override
  Future<void> loadImagePaths(List<String> imagePaths) async {
    if (failLoad) {
      throw const FileSystemException('cannot read manifest');
    }
    // Recovered: nothing saved yet -> empty list (grid shows add affordance).
  }

  @override
  Future<XFile?> pickImage({required ImageSource source}) async => null;

  @override
  Future<File> saveImagePaths(List<String> imagePaths) async =>
      File('${Directory.systemTemp.path}/flaky-image-paths.txt');

  @override
  Future<void> getImage(String source, List<String> imagePaths) async {}

  @override
  void deleteImage(int index, List<String> imagePaths) {}

  @override
  displayImage(String path, {BoxFit fit = BoxFit.none}) =>
      Image.memory(Uint8List(0), fit: fit, errorBuilder: (_, _, _) {
        return const SizedBox.shrink();
      });

  @override
  Widget getOnlineImage(String url) => const SizedBox.shrink();

  @override
  Future<void> deleteImages() async {}
}

void main() {
  late _FlakyImagePickerService flaky;

  setUp(() {
    registerTestServices();
    // Swap the Noop picker for one that fails the load.
    flaky = _FlakyImagePickerService();
    final getIt = GetIt.instance;
    getIt.unregister<ImagePickerService>();
    getIt.registerSingleton<ImagePickerService>(flaky);
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('Feel Good surfaces a retry when the image load fails',
      (tester) async {
    await pumpWithProviders(tester, const FeelGood());
    await tester.pumpAndSettle();

    // Error contract is reached on the real production path.
    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // The grid is NOT rendered behind the error (the old empty-grid bug).
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('retry recovers once the load stops failing', (tester) async {
    await pumpWithProviders(tester, const FeelGood());
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);

    // Service recovers, user taps retry. The button sits inside the page's
    // scroll view, so bring it into view before tapping.
    flaky.failLoad = false;
    await tester.ensureVisible(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    // Error UI is gone and the grid (with its add affordance) renders.
    expect(find.text('Something went wrong.'), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
  });
}
