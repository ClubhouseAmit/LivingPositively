@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery.dart';
import 'package:mazilon/util/logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('deliverMoodMedicineReport', () {
    if (Platform.isLinux) {
      test(
        'should return unavailable without accessing native share channels on Linux',
        () async {
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
            return null;
          });
          messenger.setMockMethodCallHandler(shareChannel, (
            MethodCall call,
          ) async {
            shareCall = call;
            return null;
          });
          addTearDown(() {
            messenger.setMockMethodCallHandler(pathProviderChannel, null);
            messenger.setMockMethodCallHandler(shareChannel, null);
          });

          final MoodMedicineReportDelivery delivery =
              await deliverMoodMedicineReport(
                incidentLoggerService: const _NoopIncidentLoggerService(),
                bytes: Uint8List.fromList(<int>[1, 2, 3]),
                fileName: 'mood-report.pdf',
                mimeType: 'application/pdf',
                shareText: '  Mood report  ',
              );

          expect(delivery.status, MoodMedicineReportDeliveryStatus.unavailable);
          expect(pathProviderCall, isNull);
          expect(shareCall, isNull);
        },
      );
    } else {
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
                incidentLoggerService: const _NoopIncidentLoggerService(),
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
    }
  });
}

final class _NoopIncidentLoggerService implements IncidentLoggerService {
  const _NoopIncidentLoggerService();

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {}

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}
