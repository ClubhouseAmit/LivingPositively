import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

class FakePersistentMemoryService implements PersistentMemoryService {
  FakePersistentMemoryService(this.values);

  final Map<String, dynamic> values;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    return values[key];
  }

  @override
  Future<void> setItem(
      String key, PersistentMemoryType type, dynamic value) async {
    values[key] = value;
  }

  @override
  Future<void> reset() async {
    values.clear();
  }
}

void main() {
  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('loadUserInformation keeps saved locale over device fallback', () async {
    final service = FakePersistentMemoryService({
      'localeName': 'en',
    });
    GetIt.instance.registerSingleton<PersistentMemoryService>(service);

    final userInfo = UserInformation(service: service);
    await loadUserInformation(userInfo, 'he');

    expect(userInfo.localeName, 'en');
  });
}
