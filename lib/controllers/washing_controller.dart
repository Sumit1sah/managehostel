import 'package:flutter/material.dart';
import '../models/washing_machine.dart';
import '../models/queue_entry.dart';
import '../services/washing_service.dart';

class WashingController extends ChangeNotifier {
  final WashingService _service = WashingService();

  List<WashingMachine> get machines => _service.getMachines();
  List<QueueEntry> get queue => _service.getQueue();
  
  Stream<List<WashingMachine>> get machinesStream => _service.machinesStream;
  Stream<List<QueueEntry>> get queueStream => _service.queueStream;

  Future<void> joinQueue(String studentId, String studentName, String machineId) async {
    await _service.joinQueue(studentId, studentName, machineId);
    notifyListeners();
  }

  Future<void> startWashing(String machineId) async {
    await _service.startWashing(machineId);
    notifyListeners();
  }

  List<QueueEntry> getQueueForMachine(String machineId) =>
      _service.getQueueForMachine(machineId);

  QueueEntry? getStudentQueue(String studentId) =>
      _service.getStudentQueue(studentId);

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
