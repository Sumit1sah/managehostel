import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class RoomAvailabilityView extends StatefulWidget {
  const RoomAvailabilityView({Key? key}) : super(key: key);

  @override
  State<RoomAvailabilityView> createState() => _RoomAvailabilityViewState();
}

class _RoomAvailabilityViewState extends State<RoomAvailabilityView> {
  int _roomsPerFloor = 10;
  int _floors = 2;
  int _selectedFloor = 0;
  bool _isWarden = false;
  Map<String, List<String>> _roomBedStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkWardenStatus();
    _syncRoomAllocation();
    _loadRoomStatus();
    // Refresh room status when view becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoomStatus();
    });
  }

  void _loadSettings() {
    final roomsPerFloor = HiveStorage.load<int>(HiveStorage.appStateBox, 'rooms_per_floor');
    final floors = HiveStorage.load<int>(HiveStorage.appStateBox, 'floors');
    setState(() {
      _roomsPerFloor = roomsPerFloor ?? 10;
      _floors = floors ?? 2;
    });
  }

  void _checkWardenStatus() async {
    final isWarden = await AuthService().isWarden();
    setState(() {
      _isWarden = isWarden;
    });
  }

  void _loadRoomStatus() {
    // Load from global storage that all users share
    final savedStatus = HiveStorage.load<Map>(HiveStorage.appStateBox, 'global_room_bed_status');
    if (savedStatus != null) {
      setState(() {
        _roomBedStatus = Map<String, List<String>>.from(
          savedStatus.map((key, value) => MapEntry(key, List<String>.from(value)))
        );
      });
    }
  }

  void _saveRoomStatus() {
    // Save to global storage that all users can access
    HiveStorage.save(HiveStorage.appStateBox, 'global_room_bed_status', _roomBedStatus);
    // Also save timestamp for change tracking
    HiveStorage.save(HiveStorage.appStateBox, 'room_status_last_updated', DateTime.now().toIso8601String());
  }

  void _toggleBedStatus(String roomNumber, int bedIndex) {
    if (!_isWarden) return;
    
    setState(() {
      if (!_roomBedStatus.containsKey(roomNumber)) {
        _roomBedStatus[roomNumber] = ['available', 'available'];
      }
      
      final currentStatus = _roomBedStatus[roomNumber]![bedIndex];
      
      // If trying to make occupied bed available, check if student is assigned
      if (currentStatus == 'occupied') {
        if (_isRoomOccupiedByStudent(roomNumber)) {
          _showOccupiedRoomDialog(roomNumber);
          return;
        }
      }
      
      _roomBedStatus[roomNumber]![bedIndex] = currentStatus == 'occupied' ? 'available' : 'occupied';
    });
    
    _saveRoomStatus();
  }

  List<String> _getBedStatus(String roomNumber) {
    return _roomBedStatus[roomNumber] ?? ['available', 'available'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final floorNames = List.generate(_floors, (index) => 
      index == 0 ? 'Ground Floor' : 'Floor ${index}'
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Availability'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<int>(
              value: _selectedFloor,
              decoration: const InputDecoration(
                labelText: 'Select Floor',
                prefixIcon: Icon(Icons.layers),
                border: OutlineInputBorder(),
              ),
              items: List.generate(_floors, (index) => DropdownMenuItem(
                value: index,
                child: Text(index == 0 ? 'Ground Floor' : 'Floor $index'),
              )),
              onChanged: (value) {
                setState(() {
                  _selectedFloor = value ?? 0;
                });
              },
            ),
          ),
        ),
        actions: [
          if (_isWarden)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'WARDEN MODE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadRoomStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room status refreshed')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFloor == 0 ? 'Ground Floor' : 'Floor $_selectedFloor',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _roomsPerFloor,
                    itemBuilder: (context, roomIndex) {
                      String roomNumber;
                      if (_selectedFloor == 0) {
                        roomNumber = '0A-${(roomIndex + 1).toString().padLeft(2, '0')}';
                      } else {
                        final startNumber = (_roomsPerFloor * _selectedFloor) + 1;
                        roomNumber = '${_selectedFloor}A-${(startNumber + roomIndex).toString().padLeft(2, '0')}';
                      }
                      
                      final bedStatuses = _getBedStatus(roomNumber);
                      
                      return GestureDetector(
                        onTap: _isWarden ? () => _showRoomInfo(roomNumber, bedStatuses) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isWarden ? theme.colorScheme.primary : theme.colorScheme.outline,
                              width: _isWarden ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Room $roomNumber',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      Icons.bed,
                                      color: bedStatuses[0] == 'occupied' ? Colors.red : Colors.green,
                                      size: 18,
                                    ),
                                    Icon(
                                      Icons.bed,
                                      color: bedStatuses[1] == 'occupied' ? Colors.red : Colors.green,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Flexible(
                                  child: Text(
                                    _getRoomStatus(bedStatuses),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_isWarden)
                                  Flexible(
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'View Info',
                                        style: TextStyle(fontSize: 8, color: Colors.blue.shade700),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoomStatus(List<String> bedStatuses) {
    final occupiedCount = bedStatuses.where((status) => status == 'occupied').length;
    if (occupiedCount == 0) return 'Available';
    if (occupiedCount == 2) return 'Occupied';
    return 'Partly Occupied';
  }

  void _showRoomInfo(String roomNumber, List<String> bedStatuses) {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final roomParts = roomNumber.split('A-');
    final floor = roomParts[0];
    final room = roomParts[1];
    final theme = Theme.of(context);
    
    final occupants = users.where((user) => user['floor'] == floor && user['room'] == room).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Room $roomNumber Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status: ${_getRoomStatus(bedStatuses)}'),
            const SizedBox(height: 16),
            if (occupants.isNotEmpty) ...[
              const Text('Occupants:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...occupants.map((user) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        (user['name'] ?? user['userId']!)[0].toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? user['userId']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('ID: ${user['userId']}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ] else ...[
              const Text('No students assigned to this room.'),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Room allocation is managed through Student ID Management only.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: theme.colorScheme.onSecondaryContainer),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isRoomOccupiedByStudent(String roomNumber) {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final roomParts = roomNumber.split('A-');
    final floor = roomParts[0];
    final room = roomParts[1];
    
    return users.any((user) => user['floor'] == floor && user['room'] == room);
  }

  void _showOccupiedRoomDialog(String roomNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning, color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Room Occupied!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Room $roomNumber is currently occupied by a student. Please remove the student first before deallocating.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Got it!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _syncRoomAllocation() {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final Map<String, List<String>> newRoomStatus = {};
    
    // Count students per room
    final Map<String, int> roomOccupancy = {};
    
    for (var user in users) {
      final floor = user['floor'] ?? '0';
      final room = user['room'] ?? '01';
      final roomNumber = '${floor}A-${room.padLeft(2, '0')}';
      
      roomOccupancy[roomNumber] = (roomOccupancy[roomNumber] ?? 0) + 1;
    }
    
    // Set room status based on actual occupancy
    roomOccupancy.forEach((roomNumber, count) {
      if (count == 1) {
        newRoomStatus[roomNumber] = ['occupied', 'available'];
      } else if (count >= 2) {
        newRoomStatus[roomNumber] = ['occupied', 'occupied'];
      }
    });
    
    // Save corrected room status
    HiveStorage.save(HiveStorage.appStateBox, 'global_room_bed_status', newRoomStatus);
  }
}