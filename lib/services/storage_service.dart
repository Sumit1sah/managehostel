import '../core/storage/hive_storage.dart';
import '../models/room_cleaning.dart';
import '../models/queue_entry.dart';
import '../models/washing_machine.dart';

class StorageService {
  static const _keyCleanings = 'cleanings_data';
  static const _keyQueue = 'queue_data';
  static const _keyMachines = 'machines_data';
  static const _keyFloors = 'floors_data';

  Future<void> saveCleanings(List<RoomCleaning> cleanings) async {
    final data = cleanings.map((c) => c.toJson()).toList();
    await HiveStorage.saveList(HiveStorage.cleaningsBox, _keyCleanings, data);
  }

  Future<List<RoomCleaning>> loadCleanings() async {
    final data = HiveStorage.loadList(HiveStorage.cleaningsBox, _keyCleanings);
    return data.map((json) => RoomCleaning.fromJson(json)).toList();
  }

  Future<void> saveQueue(List<QueueEntry> queue) async {
    final data = queue.map((q) => q.toJson()).toList();
    await HiveStorage.saveList(HiveStorage.queueBox, _keyQueue, data);
  }

  Future<List<QueueEntry>> loadQueue() async {
    final data = HiveStorage.loadList(HiveStorage.queueBox, _keyQueue);
    return data.map((json) => QueueEntry.fromJson(json)).toList();
  }

  Future<void> saveMachines(List<WashingMachine> machines) async {
    final data = machines.map((m) => m.toJson()).toList();
    await HiveStorage.saveList(HiveStorage.machinesBox, _keyMachines, data);
  }

  Future<List<WashingMachine>> loadMachines() async {
    final data = HiveStorage.loadList(HiveStorage.machinesBox, _keyMachines);
    return data.map((json) => WashingMachine.fromJson(json)).toList();
  }

  Future<void> saveFloors(List<String> floors) async {
    await HiveStorage.save(HiveStorage.floorsBox, _keyFloors, floors);
  }

  Future<List<String>> loadFloors() async {
    final data = HiveStorage.load<List>(HiveStorage.floorsBox, _keyFloors);
    if (data == null || data.isEmpty) {
      return ['Ground Floor', 'First Floor', 'Second Floor', 'Third Floor'];
    }
    return List<String>.from(data);
  }
}
