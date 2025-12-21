import 'dart:async';
import '../models/room_cleaning.dart';
import 'storage_service.dart';

class CleaningService {
  final _cleaningController = StreamController<List<RoomCleaning>>.broadcast();
  final List<RoomCleaning> _cleanings = [];
  final _storage = StorageService();

  Stream<List<RoomCleaning>> get cleaningStream => _cleaningController.stream;

  CleaningService() {
    _loadData();
  }

  Future<void> _loadData() async {
    _cleanings.addAll(await _storage.loadCleanings());
    _cleaningController.add(_cleanings);
  }

  Future<void> scheduleRoomCleaning(String roomNumber, String floor, String studentId) async {
    final cleaning = RoomCleaning(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomNumber: roomNumber,
      floor: floor,
      studentId: studentId,
      scheduledDate: DateTime.now(),
    );
    _cleanings.add(cleaning);
    await _storage.saveCleanings(_cleanings);
    _cleaningController.add(_cleanings);
  }

  Future<void> updateCleaningChecklist(String cleaningId, {bool? bathroom, bool? room, bool? toilet}) async {
    final cleaning = _cleanings.firstWhere((c) => c.id == cleaningId);
    if (bathroom != null) cleaning.bathroomClean = bathroom;
    if (room != null) cleaning.roomClean = room;
    if (toilet != null) cleaning.toiletClean = toilet;
    await _storage.saveCleanings(_cleanings);
    _cleaningController.add(_cleanings);
  }

  Future<void> markAttendance(String cleaningId, CleaningStatus status) async {
    final cleaning = _cleanings.firstWhere((c) => c.id == cleaningId);
    cleaning.status = status;
    if (status == CleaningStatus.completed) {
      cleaning.completedAt = DateTime.now();
    }
    await _storage.saveCleanings(_cleanings);
    _cleaningController.add(_cleanings);
  }

  Future<void> verifyRoomCleaning(String cleaningId, String verifierId, String? remarks) async {
    final cleaning = _cleanings.firstWhere((c) => c.id == cleaningId);
    cleaning.status = CleaningStatus.verified;
    cleaning.verifiedBy = verifierId;
    cleaning.remarks = remarks;
    await _storage.saveCleanings(_cleanings);
    _cleaningController.add(_cleanings);
  }

  List<RoomCleaning> getRoomCleanings(String roomNumber) =>
      _cleanings.where((c) => c.roomNumber == roomNumber).toList();

  List<RoomCleaning> getStudentCleanings(String studentId) =>
      _cleanings.where((c) => c.studentId == studentId).toList();

  Map<String, List<RoomCleaning>> getCleaningsByFloor() {
    final Map<String, List<RoomCleaning>> floorMap = {};
    for (var cleaning in _cleanings) {
      floorMap.putIfAbsent(cleaning.floor, () => []).add(cleaning);
    }
    return floorMap;
  }

  void dispose() {
    _cleaningController.close();
  }
}
