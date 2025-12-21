import 'package:flutter/material.dart';
import '../models/room_cleaning.dart';
import '../services/cleaning_service.dart';

class CleaningController extends ChangeNotifier {
  final CleaningService _service = CleaningService();

  Stream<List<RoomCleaning>> get cleaningStream => _service.cleaningStream;

  Future<void> scheduleRoomCleaning(String roomNumber, String floor, String studentId) async {
    await _service.scheduleRoomCleaning(roomNumber, floor, studentId);
    notifyListeners();
  }

  Future<void> updateCleaningChecklist(String cleaningId, {bool? bathroom, bool? room, bool? toilet}) async {
    await _service.updateCleaningChecklist(cleaningId, bathroom: bathroom, room: room, toilet: toilet);
    notifyListeners();
  }

  Future<void> markAttendance(String cleaningId, CleaningStatus status) async {
    await _service.markAttendance(cleaningId, status);
    notifyListeners();
  }

  Future<void> verifyRoomCleaning(String cleaningId, String verifierId, String? remarks) async {
    await _service.verifyRoomCleaning(cleaningId, verifierId, remarks);
    notifyListeners();
  }

  List<RoomCleaning> getRoomCleanings(String roomNumber) =>
      _service.getRoomCleanings(roomNumber);

  List<RoomCleaning> getStudentCleanings(String studentId) =>
      _service.getStudentCleanings(studentId);

  Map<String, List<RoomCleaning>> getCleaningsByFloor() =>
      _service.getCleaningsByFloor();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
