import 'dart:async';
import '../models/washing_machine.dart';
import '../models/queue_entry.dart';
import 'storage_service.dart';

class WashingService {
  final _machinesController = StreamController<List<WashingMachine>>.broadcast();
  final _queueController = StreamController<List<QueueEntry>>.broadcast();
  
  final List<WashingMachine> _machines = [];
  final List<QueueEntry> _queue = [];
  final _storage = StorageService();

  Stream<List<WashingMachine>> get machinesStream => _machinesController.stream;
  Stream<List<QueueEntry>> get queueStream => _queueController.stream;

  WashingService() {
    _initMachines();
  }

  void _initMachines() async {
    final loaded = await _storage.loadMachines();
    if (loaded.isEmpty) {
      _machines.addAll([
        WashingMachine(id: 'WM1', location: 'Ground Floor'),
        WashingMachine(id: 'WM2', location: 'Ground Floor'),
        WashingMachine(id: 'WM3', location: 'First Floor'),
      ]);
      await _storage.saveMachines(_machines);
    } else {
      _machines.addAll(loaded);
    }
    _queue.addAll(await _storage.loadQueue());
  }

  List<WashingMachine> getMachines() => _machines;
  List<QueueEntry> getQueue() => _queue;

  Future<void> joinQueue(String studentId, String studentName, String machineId) async {
    final entry = QueueEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: studentId,
      studentName: studentName,
      machineId: machineId,
      timestamp: DateTime.now(),
      position: _queue.where((e) => e.machineId == machineId).length + 1,
    );
    _queue.add(entry);
    await _storage.saveQueue(_queue);
    _queueController.add(_queue);
  }

  Future<void> startWashing(String machineId) async {
    final machine = _machines.firstWhere((m) => m.id == machineId);
    final queueEntry = _queue.firstWhere((q) => q.machineId == machineId && q.position == 1);
    
    machine.status = MachineStatus.inUse;
    machine.currentUserId = queueEntry.studentId;
    machine.currentStartTime = DateTime.now();
    
    _queue.remove(queueEntry);
    _updateQueuePositions(machineId);
    
    await _storage.saveMachines(_machines);
    await _storage.saveQueue(_queue);
    
    _machinesController.add(_machines);
    _queueController.add(_queue);

    Future.delayed(Duration(minutes: machine.cycleMinutes), () => _completeWashing(machineId));
  }

  void _completeWashing(String machineId) async {
    final machine = _machines.firstWhere((m) => m.id == machineId);
    machine.status = MachineStatus.available;
    machine.currentUserId = null;
    machine.currentStartTime = null;
    await _storage.saveMachines(_machines);
    _machinesController.add(_machines);
  }

  void _updateQueuePositions(String machineId) {
    final entries = _queue.where((e) => e.machineId == machineId).toList();
    for (int i = 0; i < entries.length; i++) {
      entries[i].position = i + 1;
    }
  }

  List<QueueEntry> getQueueForMachine(String machineId) =>
      _queue.where((e) => e.machineId == machineId).toList();

  QueueEntry? getStudentQueue(String studentId) =>
      _queue.where((e) => e.studentId == studentId).firstOrNull;

  void dispose() {
    _machinesController.close();
    _queueController.close();
  }
}
