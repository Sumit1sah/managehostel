import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({Key? key}) : super(key: key);

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  List<Map<String, String>> _users = [];
  List<Map<String, String>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    setState(() {
      _users = users.map((user) => Map<String, String>.from(user)).toList();
      _filteredUsers = _users;
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final userId = (user['userId'] ?? '').toLowerCase();
        return userId.contains(query);
      }).toList();
    });
  }

  void _saveUsers() {
    HiveStorage.saveList(HiveStorage.appStateBox, 'authorized_users', _users);
  }

  void _createUser() {
    final nameController = TextEditingController();
    final userIdController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final roomController = TextEditingController();
    String? selectedFloor;
    
    final floors = HiveStorage.load<int>(HiveStorage.appStateBox, 'floors', defaultValue: 2) ?? 2;
    final floorOptions = List.generate(floors, (index) => index.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Create New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFloor,
                decoration: const InputDecoration(
                  labelText: 'Floor',
                  prefixIcon: Icon(Icons.layers),
                ),
                items: floorOptions.map((floor) => DropdownMenuItem(
                  value: floor,
                  child: Text('Floor $floor'),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedFloor = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (selectedFloor != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Available Room',
                    prefixIcon: Icon(Icons.room),
                  ),
                  items: _getAvailableRooms(selectedFloor!).map((room) => DropdownMenuItem(
                    value: room,
                    child: Text('Room $room'),
                  )).toList(),
                  onChanged: (value) {
                    roomController.text = value ?? '';
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  userIdController.text.isNotEmpty && 
                  passwordController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty &&
                  selectedFloor != null &&
                  roomController.text.isNotEmpty) {
                setState(() {
                  _users.add({
                    'name': nameController.text,
                    'userId': userIdController.text,
                    'password': passwordController.text,
                    'phone': phoneController.text,
                    'floor': selectedFloor!,
                    'room': roomController.text,
                  });
                });
                _saveUsers();
                _occupyRoomBed(selectedFloor!, roomController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Student ${userIdController.text} created successfully')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
        ),
      ),
    );
  }

  void _deleteUser(int index) {
    final wardenPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Warden Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter warden password to delete student "${_users[index]['userId']}":'),
            const SizedBox(height: 16),
            TextField(
              controller: wardenPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Warden Password',
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (wardenPasswordController.text == 'warden123') {
                Navigator.pop(context);
                _confirmDeleteUser(index);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid warden password')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete student "${_users[index]['userId']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final user = _users[index];
              setState(() {
                _users.removeAt(index);
              });
              _saveUsers();
              _vacateRoomBed(user['floor'] ?? '0', user['room'] ?? '01');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createUser,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Student ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(_searchController.text.isNotEmpty 
                        ? 'No students found matching "${_searchController.text}"'
                        : 'No students created yet.\nTap + to create a new student.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        (user['name'] ?? user['userId']!)[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      user['name'] ?? user['userId']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('ID: ${user['userId']!}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Phone: ${user['phone'] ?? 'N/A'}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _showPasswordDialog(user['password'] ?? 'N/A'),
                            child: Row(
                              children: [
                                const Icon(Icons.lock, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Password: ${'*' * (user['password']?.length ?? 3)}'),
                                const SizedBox(width: 8),
                                const Icon(Icons.visibility, size: 14, color: Colors.blue),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.layers, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Floor: ${user['floor'] ?? 'N/A'}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.room, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Room: ${user['room'] ?? 'N/A'}'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                          onPressed: () => _showRoomSwapDialog(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(index),
                        ),
                      ],
                    ),
                  ),
                );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPasswordDialog(String password) {
    final wardenPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Warden Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter warden password to view student password:'),
            const SizedBox(height: 16),
            TextField(
              controller: wardenPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Warden Password',
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (wardenPasswordController.text == 'warden123') {
                Navigator.pop(context);
                _showStudentPassword(password);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid warden password')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showStudentPassword(String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Student Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_open, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    password,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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

  void _occupyRoomBed(String floor, String room) {
    final roomNumber = '${floor}A-${room.padLeft(2, '0')}';
    final roomBedStatus = HiveStorage.load<Map>(HiveStorage.appStateBox, 'global_room_bed_status') ?? {};
    final bedStatuses = List<String>.from(roomBedStatus[roomNumber] ?? ['available', 'available']);
    
    // Occupy first available bed
    for (int i = 0; i < bedStatuses.length; i++) {
      if (bedStatuses[i] == 'available') {
        bedStatuses[i] = 'occupied';
        break;
      }
    }
    
    roomBedStatus[roomNumber] = bedStatuses;
    HiveStorage.save(HiveStorage.appStateBox, 'global_room_bed_status', roomBedStatus);
  }

  void _vacateRoomBed(String floor, String room) {
    final roomNumber = '${floor}A-${room.padLeft(2, '0')}';
    final roomBedStatus = HiveStorage.load<Map>(HiveStorage.appStateBox, 'global_room_bed_status') ?? {};
    final bedStatuses = List<String>.from(roomBedStatus[roomNumber] ?? ['available', 'available']);
    
    // Vacate first occupied bed
    for (int i = 0; i < bedStatuses.length; i++) {
      if (bedStatuses[i] == 'occupied') {
        bedStatuses[i] = 'available';
        break;
      }
    }
    
    roomBedStatus[roomNumber] = bedStatuses;
    HiveStorage.save(HiveStorage.appStateBox, 'global_room_bed_status', roomBedStatus);
  }

  List<String> _getAvailableRooms(String floor) {
    final roomsPerFloor = HiveStorage.load<int>(HiveStorage.appStateBox, 'rooms_per_floor') ?? 10;
    final roomBedStatus = HiveStorage.load<Map>(HiveStorage.appStateBox, 'global_room_bed_status') ?? {};
    final availableRooms = <String>[];
    
    final floorNum = int.parse(floor);
    final startRoom = floorNum == 0 ? 1 : (floorNum * roomsPerFloor) + 1;
    
    for (int i = 0; i < roomsPerFloor; i++) {
      final roomNumber = (startRoom + i).toString().padLeft(2, '0');
      final fullRoomNumber = '${floor}A-$roomNumber';
      final bedStatuses = List<String>.from(roomBedStatus[fullRoomNumber] ?? ['available', 'available']);
      
      // Check if room has at least one available bed
      if (bedStatuses.contains('available')) {
        availableRooms.add(roomNumber);
      }
    }
    
    return availableRooms;
  }

  void _showRoomSwapDialog(int userIndex) {
    final user = _users[userIndex];
    String? selectedFloor = user['floor'];
    final roomController = TextEditingController(text: user['room']);
    
    final floors = HiveStorage.load<int>(HiveStorage.appStateBox, 'floors', defaultValue: 2) ?? 2;
    final floorOptions = List.generate(floors, (index) => index.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_horiz, color: Colors.blue.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Room Swap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${user['name'] ?? user['userId']!}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Current: Floor ${user['floor']} - Room ${user['room']}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFloor,
                decoration: const InputDecoration(
                  labelText: 'New Floor',
                  prefixIcon: Icon(Icons.layers),
                ),
                items: floorOptions.map((floor) => DropdownMenuItem(
                  value: floor,
                  child: Text('Floor $floor'),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedFloor = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (selectedFloor != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Available Room',
                    prefixIcon: Icon(Icons.room),
                  ),
                  items: _getAvailableRooms(selectedFloor!).map((room) => DropdownMenuItem(
                    value: room,
                    child: Text('Room $room'),
                  )).toList(),
                  onChanged: (value) {
                    roomController.text = value ?? '';
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedFloor != null && roomController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _verifyWardenForSwap(userIndex, selectedFloor!, roomController.text);
                }
              },
              child: const Text('Swap Room'),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyWardenForSwap(int userIndex, String newFloor, String newRoom) {
    final wardenPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Warden Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter warden password to confirm room swap:'),
            const SizedBox(height: 16),
            TextField(
              controller: wardenPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Warden Password',
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (wardenPasswordController.text == 'warden123') {
                Navigator.pop(context);
                _swapStudentRoom(userIndex, newFloor, newRoom);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid warden password')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _swapStudentRoom(int userIndex, String newFloor, String newRoom) {
    final user = _users[userIndex];
    final oldFloor = user['floor'] ?? '0';
    final oldRoom = user['room'] ?? '01';
    
    // Check if new room is full
    final newRoomNumber = '${newFloor}A-${newRoom.padLeft(2, '0')}';
    final roomBedStatus = HiveStorage.load<Map>(HiveStorage.appStateBox, 'global_room_bed_status') ?? {};
    final bedStatuses = List<String>.from(roomBedStatus[newRoomNumber] ?? ['available', 'available']);
    
    final availableBeds = bedStatuses.where((status) => status == 'available').length;
    
    if (availableBeds == 0) {
      _showRoomFullDialog(newRoomNumber);
      return;
    }
    
    // Vacate old room
    _vacateRoomBed(oldFloor, oldRoom);
    
    // Update user data
    setState(() {
      _users[userIndex]['floor'] = newFloor;
      _users[userIndex]['room'] = newRoom;
    });
    _saveUsers();
    
    // Occupy new room
    _occupyRoomBed(newFloor, newRoom);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user['name'] ?? user['userId']} moved to Floor $newFloor - Room $newRoom'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRoomFullDialog(String roomNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.block, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Room Full!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Room $roomNumber is fully occupied. Please select a different room with available beds.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Understood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}