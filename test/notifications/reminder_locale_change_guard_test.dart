import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServiceLocators services;
  late UserInformation userInformation;

  setUp(() {
    services = registerTestServices(locale: 'en');
    userInformation = UserInformation();
  });

  tearDown(() {
    resetTestServices();
  });

  test(
    'updating locale only affects locale state and does not alter notification settings',
    () async {
      final persistentMemory = services.memory;
      final localeService = services.localeService;

      // Set initial state
      localeService.setLocale('en');
      userInformation.updateLocaleName('en');
      expect(userInformation.localeName, 'en');
      expect(localeService.getLocale(), 'en');

      // Perform locale change
      localeService.setLocale('he');
      await persistentMemory.setItem(
        'localeName',
        PersistentMemoryType.String,
        'he',
      );
      userInformation.updateLocaleName('he');

      // Verify locale updated
      expect(localeService.getLocale(), 'he');
      expect(userInformation.localeName, 'he');
      expect(
        await persistentMemory.getItem(
          'localeName',
          PersistentMemoryType.String,
        ),
        'he',
      );

      // Verify no reminder/notification keys were written or altered in persistent memory
      expect(persistentMemory.store.containsKey('notificationHour'), isFalse);
      expect(persistentMemory.store.containsKey('notificationMinute'), isFalse);
      expect(
        persistentMemory.store.containsKey('notificationMessage'),
        isFalse,
      );
    },
  );
}
