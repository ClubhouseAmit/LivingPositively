import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

/// Feature-local persistence adapter. A Settings reset clears this key through
/// the existing [PersistentMemoryService] reset contract.
final class MoodMedicineStore {
  MoodMedicineStore(this._memoryService);

  static const String snapshotKey = 'mood_medicine.snapshot.v1';

  final PersistentMemoryService _memoryService;

  Future<MoodMedicineSnapshot> load() async {
    final dynamic rawValue = await _memoryService.getItem(
      snapshotKey,
      PersistentMemoryType.String,
    );
    return rawValue is String
        ? MoodMedicineSnapshot.decode(rawValue)
        : const MoodMedicineSnapshot.empty();
  }

  Future<void> save(MoodMedicineSnapshot snapshot) => _memoryService.setItem(
    snapshotKey,
    PersistentMemoryType.String,
    snapshot.encode(),
  );
}
