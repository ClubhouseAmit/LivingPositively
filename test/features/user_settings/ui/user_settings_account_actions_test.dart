import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/user_settings/ui/user_settings_account_actions.dart';
import 'package:mazilon/util/userInformation.dart';

import '../../../helpers/widget_test_scaffold.dart';

final class _FailingAccountActivationMemory
    extends FakePersistentMemoryService {
  _FailingAccountActivationMemory() {
    onPersist = (key, _, _) {
      if (key == 'notificationPreferences') {
        throw StateError('notification storage unavailable');
      }
    };
  }
}

void main() {
  group('UserSettingsAccountActions', () {
    late TestServiceLocators services;
    late UserSettingsAccountActions actions;
    late UserInformation user;

    setUp(() {
      services = registerTestServices(locale: 'en');
      actions = UserSettingsAccountActions(
        imagePickerService: services.picker,
        invalidatePendingWrites: () {},
        resetPhoneData: () {},
      );
      user = UserInformation(
        service: _FailingAccountActivationMemory(),
        loggedIn: true,
        userId: 'account-a',
        localeName: 'en',
      );
    });

    tearDown(resetTestServices);

    test(
      'should return null when account activation cannot be persisted',
      () async {
        expect(await actions.signOut(user), isNull);
        await Future<void>.delayed(Duration.zero);

        expect(user.loggedIn, isTrue);
        expect(
          services.logger.captured,
          contains(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'notification storage unavailable',
            ),
          ),
        );
      },
    );

    test(
      'should report and rethrow account activation failure on reset',
      () async {
        await expectLater(
          actions.resetData(user),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'notification storage unavailable',
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(user.loggedIn, isTrue);
        expect(services.logger.captured, hasLength(1));
      },
    );
  });
}
