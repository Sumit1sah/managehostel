import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cleaning_controller.dart';
import '../models/room_cleaning.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class RoomCleaningView extends StatefulWidget {
  const RoomCleaningView({Key? key}) : super(key: key);

  @override
  State<RoomCleaningView> createState() => _RoomCleaningViewState();
}

class _RoomCleaningViewState extends State<RoomCleaningView> {
  final String studentId = 'S001';
  String selectedFloor = 'Ground Floor';
  List<String> floors = [];


  @override
  void initState() {
    super.initState();
    _loadFloors();
    _scheduleMidnightCleanup();
  }

  void _scheduleMidnightCleanup() {
    final now = DateTime.now();
    final cleanupTime = DateTime(now.year, now.month, now.day, 0, 50, 0);
    final targetTime = cleanupTime.isBefore(now) 
        ? DateTime(now.year, now.month, now.day + 1, 0, 50, 0)
        : cleanupTime;
    final duration = targetTime.difference(now);
    
    Future.delayed(duration, () async {
      await HiveStorage.clearBox(HiveStorage.cleaningsBox);
      // Clear floor completion status
      for (var floor in floors) {
        await HiveStorage.save(HiveStorage.appStateBox, 'floor_completed_$floor', false);
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room cleaning history cleared at 00:50 AM')),
        );
      }
      // Schedule next cleanup
      _scheduleMidnightCleanup();
    });
  }

  Future<void> _loadFloors() async {
    final data = HiveStorage.load<List>(HiveStorage.floorsBox, 'floors_data');
    final loaded = data != null && data.isNotEmpty 
        ? List<String>.from(data) 
        : ['Ground Floor', 'First Floor', 'Second Floor', 'Third Floor'];
    setState(() {
      floors = ['Not Selected', ...loaded];
      selectedFloor = 'Not Selected';
    });
    _initializeRoomsForFloors();
  }

  Future<void> _initializeRoomsForFloors() async {
    // Rooms are now generated on-the-fly when viewing each floor
  }

  bool _isFloorCompleted(String floor) {
    return HiveStorage.load<bool>(HiveStorage.appStateBox, 'floor_completed_$floor', defaultValue: false) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Cleaning')),
      body: ChangeNotifierProvider(
        create: (_) => CleaningController(),
        child: Consumer<CleaningController>(
          builder: (context, controller, _) {
            final floorCleanings = controller.getCleaningsByFloor();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedFloor,
                          isExpanded: true,
                          items: floors.map((floor) => DropdownMenuItem(value: floor, child: Text(floor))).toList(),
                          onChanged: (value) async {
                            if (value != null && value != 'Not Selected') {
                              final isCompleted = HiveStorage.load<bool>(HiveStorage.appStateBox, 'floor_completed_$value', defaultValue: false);
                              if (isCompleted!) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('✅ The floor cleaning is completed', style: TextStyle(fontSize: 16)),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(milliseconds: 500),
                                  ),
                                );
                                return;
                              }
                            }
                            setState(() => selectedFloor = value ?? 'Not Selected');
                          },
                        ),
                      ),


                    ],
                  ),
                ),
                Expanded(
                  child: selectedFloor.isEmpty || selectedFloor == 'Not Selected'
                      ? const Center(child: Text('Please select a floor to view rooms'))
                      : _isFloorCompleted(selectedFloor)
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                                  SizedBox(height: 20),
                                  Text('Floor Cleaning Completed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          : _buildFloorRooms(floorCleanings[selectedFloor] ?? [], controller),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloorRooms(List<RoomCleaning> cleanings, CleaningController controller) {
    return FutureBuilder<String?>(
      future: AuthService().getUserId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final userId = snapshot.data!;
        final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
        final userData = users.firstWhere(
          (user) => user['userId'] == userId,
          orElse: () => <String, dynamic>{},
        );
        
        if (userData.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text('Student data not found', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }
        
        final studentFloor = userData['floor'] ?? '0';
        final studentRoom = userData['room'] ?? '01';
        final studentRoomNumber = '${studentFloor}A-${studentRoom.padLeft(2, '0')}';
        
        // Check if selected floor matches student's floor
        final floorIndex = floors.indexOf(selectedFloor);
        final expectedFloorIndex = int.parse(studentFloor);
        
        if (floorIndex != expectedFloorIndex) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text('No rooms assigned to you on this floor', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }
        
        // Only show the student's assigned room
        final existingCleaning = cleanings.where((c) => c.roomNumber == studentRoomNumber).firstOrNull;
        final cleaning = existingCleaning ?? RoomCleaning(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          roomNumber: studentRoomNumber,
          floor: selectedFloor,
          studentId: userId,
          scheduledDate: DateTime.now(),
        );
        final isExisting = existingCleaning != null;
        
        return Column(
          children: [
            if (cleaning.status == CleaningStatus.completed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'ROOM CLEANING COMPLETED ✓',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: cleaning.status == CleaningStatus.completed
                        ? ListTile(
                            title: Text('Room ${cleaning.roomNumber}'),
                            subtitle: const Text('Status: Submitted ✓'),
                            trailing: const Icon(Icons.check_circle, color: Colors.green),
                          )
                        : ExpansionTile(
                            title: Text('Room ${cleaning.roomNumber}'),
                            subtitle: Text('Status: ${cleaning.status.name}'),
                            trailing: cleaning.isFullyClean
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.pending, color: Colors.orange),
                            children: [
                        CheckboxListTile(
                          title: const Text('Bathroom Clean'),
                          value: cleaning.bathroomClean,
                          onChanged: cleaning.status == CleaningStatus.completed
                              ? null
                              : (val) async {
                                  if (!isExisting) {
                                    await controller.scheduleRoomCleaning(studentRoomNumber, selectedFloor, userId);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                  }
                                  final savedCleaning = controller.getRoomCleanings(studentRoomNumber).first;
                                  await controller.updateCleaningChecklist(savedCleaning.id, bathroom: val);
                                },
                        ),
                        CheckboxListTile(
                          title: const Text('Room Clean'),
                          value: cleaning.roomClean,
                          onChanged: cleaning.status == CleaningStatus.completed
                              ? null
                              : (val) async {
                                  if (!isExisting) {
                                    await controller.scheduleRoomCleaning(studentRoomNumber, selectedFloor, userId);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                  }
                                  final savedCleaning = controller.getRoomCleanings(studentRoomNumber).first;
                                  await controller.updateCleaningChecklist(savedCleaning.id, room: val);
                                },
                        ),
                        CheckboxListTile(
                          title: const Text('Toilet Clean'),
                          value: cleaning.toiletClean,
                          onChanged: cleaning.status == CleaningStatus.completed
                              ? null
                              : (val) async {
                                  if (!isExisting) {
                                    await controller.scheduleRoomCleaning(studentRoomNumber, selectedFloor, userId);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                  }
                                  final savedCleaning = controller.getRoomCleanings(studentRoomNumber).first;
                                  await controller.updateCleaningChecklist(savedCleaning.id, toilet: val);
                                },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: cleaning.status == CleaningStatus.completed
                              ? const Text('✓ Submitted', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold))
                              : ElevatedButton(
                                  onPressed: cleaning.isFullyClean
                                      ? () {
                                          controller.markAttendance(cleaning.id, CleaningStatus.completed);
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              title: Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                                                  const SizedBox(width: 10),
                                                  const Text('Success!'),
                                                ],
                                              ),
                                              content: Text(
                                                '🎉 Thank You!\n\nRoom ${cleaning.roomNumber} cleaning submitted successfully.\n\n✅ Your effort is appreciated!',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              actions: [
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Done'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              title: Row(
                                                children: [
                                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
                                                  const SizedBox(width: 10),
                                                  const Text('Incomplete!'),
                                                ],
                                              ),
                                              content: Text(
                                                !cleaning.roomClean
                                                    ? '🧹 Room Clean is mandatory!\n\nPlease clean the room first.'
                                                    : '✓ Room Clean done!\n\nPlease check at least one more item:\n• Bathroom Clean\n• Toilet Clean',
                                              ),
                                              actions: [
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  child: const Text('SUBMIT'),
                                ),
                        ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

}
