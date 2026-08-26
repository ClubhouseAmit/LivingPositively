import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../../test_support/contract_persistent_memory_service.dart';

void main() {
  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('loadUserInformation keeps saved locale over device fallback', () async {
    final service = ContractPersistentMemoryService(
      initialValues: <String, Object?>{'localeName': 'en'},
    )..onMissingRead = (_, _) => null;
    GetIt.instance.registerSingleton<PersistentMemoryService>(service);

    final userInfo = UserInformation(service: service);
    await loadUserInformation(userInfo, 'he');

    expect(userInfo.localeName, 'en');
  });
}
