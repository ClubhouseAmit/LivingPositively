@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('deliverMoodMedicineReport', () {
    test(
      'should dispatch through SharePlus and materialize the byte-backed report',
      () async {
        final Directory temporaryDirectory = await Directory.systemTemp
            .createTemp('mood_medicine_delivery_facade_');
        final TestDefaultBinaryMessenger messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const MethodChannel pathProviderChannel = MethodChannel(
          'plugins.flutter.io/path_provider',
        );
        const MethodChannel shareChannel = MethodChannel(
          'dev.fluttercommunity.plus/share',
        );
        MethodCall? pathProviderCall;
        MethodCall? shareCall;

        messenger.setMockMethodCallHandler(pathProviderChannel, (
          MethodCall call,
        ) async {
          pathProviderCall = call;
          if (call.method == 'getTemporaryDirectory') {
            return temporaryDirectory.path;
          }
          return null;
        });
        messenger.setMockMethodCallHandler(shareChannel, (
          MethodCall call,
        ) async {
          shareCall = call;
          return 'com.example.share.target';
        });
        addTearDown(() async {
          messenger.setMockMethodCallHandler(pathProviderChannel, null);
          messenger.setMockMethodCallHandler(shareChannel, null);
          await temporaryDirectory.delete(recursive: true);
        });

        final MoodMedicineReportDelivery delivery =
            await deliverMoodMedicineReport(
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              fileName: 'mood-report.pdf',
              mimeType: 'application/pdf',
              shareText: '  Mood report  ',
            );

        expect(delivery.status, MoodMedicineReportDeliveryStatus.delivered);
        expect(pathProviderCall?.method, 'getTemporaryDirectory');
        expect(shareCall?.method, 'share');

        final Map<String, dynamic> arguments = Map<String, dynamic>.from(
          shareCall!.arguments as Map<dynamic, dynamic>,
        );
        final List<dynamic> paths = arguments['paths']! as List<dynamic>;
        final File sharedFile = File(paths.single as String);

        expect(
          sharedFile.parent.parent.absolute.path,
          temporaryDirectory.absolute.path,
        );
        expect(sharedFile.uri.pathSegments.last, 'mood-report.pdf');
        expect(await sharedFile.readAsBytes(), <int>[1, 2, 3]);
        expect(arguments['mimeTypes'], <String>['application/pdf']);
        expect(arguments['text'], 'Mood report');
        expect(arguments['title'], 'mood-report.pdf');
        expect(arguments['subject'], 'mood-report.pdf');
      },
    );
  });
}
