import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class RoomCleaningView extends StatefulWidget {
  const RoomCleaningView({Key? key}) : super(key: key);

  @override
  State<RoomCleaningView> createState() => _RoomCleaningViewState();
}

class _RoomCleaningViewState extends State<RoomCleaningView> {
  bool _isWarden = false;
  bool _roomCleaning = false;
  bool _toiletCleaning = false;
  bool _corridorCleaning = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() async {
    final isWarden = await AuthService().isWarden();
    setState(() {
      _isWarden = isWarden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Cleaning'),
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
                'WARDEN',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          if (_isWarden)
            IconButton(
              onPressed: _resetAllCleaningData,
              icon: const Icon(Icons.refresh, color: Colors.red),
              tooltip: 'Reset All Cleaning Data',
            ),
        ],
      ),
      body: _isWarden ? _buildWardenView() : _buildStudentView(),
    );
  }

  Widget _buildStudentView() {
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
        
        final floor = userData['floor']?.toString() ?? '0';
        final room = userData['room']?.toString() ?? '01';
        final roomNumber = '${floor}A-${room.padLeft(2, '0')}';
        
        // Check if already submitted today
        final cleaningData = HiveStorage.loadList(HiveStorage.appStateBox, 'room_cleaning_submissions');
        final today = DateTime.now().toIso8601String().split('T')[0];
        final todaySubmission = cleaningData.firstWhere(
          (submission) => submission['roomNumber'] == roomNumber && 
                         submission['date'] == today,
          orElse: () => <String, dynamic>{},
        );
        
        final isSubmitted = todaySubmission.isNotEmpty;
        
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.home,
                        size: 60,
                        color: isSubmitted ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Room: $roomNumber',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Floor ${floor == '0' ? 'Ground' : floor}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSubmitted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSubmitted ? Icons.check_circle : Icons.pending,
                              color: isSubmitted ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSubmitted ? 'Cleaning Submitted Today' : 'Cleaning Pending',
                              style: TextStyle(
                                color: isSubmitted ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSubmitted) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Submitted at: ${todaySubmission['time']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!isSubmitted)
                _buildCleaningOptions(roomNumber, userId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWardenView() {
    final theme = Theme.of(context);
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users')
        .where((user) => user['role'] != 'warden')
        .toList();
    
    final cleaningData = HiveStorage.loadList(HiveStorage.appStateBox, 'room_cleaning_submissions');
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    print('DEBUG: Total cleaning submissions: ${cleaningData.length}');
    print('DEBUG: Today: $today');
    
    // Group by floor
    Map<String, List<Map<String, dynamic>>> floorData = {};
    
    for (var user in users) {
      final floor = user['floor']?.toString() ?? '0';
      final room = user['room']?.toString() ?? '01';
      final roomNumber = '${floor}A-${room.padLeft(2, '0')}';
      
      final todaySubmission = cleaningData.firstWhere(
        (submission) => submission['roomNumber'] == roomNumber && 
                       submission['date'] == today,
        orElse: () => <String, dynamic>{},
      );
      
      print('DEBUG: Room $roomNumber - Submission found: ${todaySubmission.isNotEmpty}');
      
      final roomInfo = {
        'studentName': user['name'] ?? user['userId'],
        'studentId': user['userId'],
        'floor': floor,
        'room': room,
        'roomNumber': roomNumber,
        'isCompleted': todaySubmission.isNotEmpty,
        'submissionTime': todaySubmission['time'] ?? '',
      };
      
      final floorName = floor == '0' ? 'Ground Floor' : 'Floor $floor';
      if (!floorData.containsKey(floorName)) {
        floorData[floorName] = [];
      }
      floorData[floorName]!.add(roomInfo);
    }
    
    // Sort rooms within each floor
    floorData.forEach((floor, rooms) {
      rooms.sort((a, b) => a['roomNumber'].compareTo(b['roomNumber']));
    });
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Cleaning Status - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: floorData.isEmpty
                ? Center(
                    child: Text(
                      'No rooms found',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: floorData.keys.length,
                    itemBuilder: (context, index) {
                      final floorName = floorData.keys.elementAt(index);
                      final rooms = floorData[floorName]!;
                      final completedCount = rooms.where((room) => room['isCompleted']).length;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: theme.colorScheme.surface,
                        child: ExpansionTile(
                          iconColor: theme.colorScheme.primary,
                          collapsedIconColor: theme.colorScheme.onSurface.withOpacity(0.6),
                          title: GestureDetector(
                            onTap: () => _showFloorTable(floorName, rooms),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.layers,
                                  color: completedCount == rooms.length 
                                      ? Colors.green 
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  floorName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: completedCount == rooms.length 
                                        ? Colors.green.withOpacity(0.1)
                                        : theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$completedCount/${rooms.length}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: completedCount == rooms.length 
                                          ? Colors.green 
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Student Name')),
                                  DataColumn(label: Text('Room No')),
                                  DataColumn(label: Text('Status')),
                                ],
                                rows: rooms.map((room) => DataRow(
                                  cells: [
                                    DataCell(Text(room['studentName'] ?? 'N/A')),
                                    DataCell(Text(room['roomNumber'])),
                                    DataCell(
                                      GestureDetector(
                                        onTap: () => _showRoomDetails(room['roomNumber'], room['isCompleted'], room['studentName']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: room['isCompleted'] 
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            room['isCompleted'] ? 'Done' : 'Pending',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: room['isCompleted'] ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningOptions(String roomNumber, String userId) {
    bool canSubmit() {
      if (!_roomCleaning) return false; // Room cleaning is mandatory
      int checkedCount = [_roomCleaning, _toiletCleaning, _corridorCleaning].where((x) => x).length;
      return checkedCount >= 2; // At least 2 options must be checked
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Cleaning Activities:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Room Cleaning'),
              subtitle: const Text('Required', style: TextStyle(color: Colors.red, fontSize: 12)),
              value: _roomCleaning,
              onChanged: (value) {
                setState(() {
                  _roomCleaning = value ?? false;
                });
              },
              activeColor: Colors.green,
            ),
            CheckboxListTile(
              title: const Text('Toilet Cleaning'),
              value: _toiletCleaning,
              onChanged: (value) {
                setState(() {
                  _toiletCleaning = value ?? false;
                });
              },
              activeColor: Colors.green,
            ),
            CheckboxListTile(
              title: const Text('Corridor Cleaning'),
              value: _corridorCleaning,
              onChanged: (value) {
                setState(() {
                  _corridorCleaning = value ?? false;
                });
              },
              activeColor: Colors.green,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Room cleaning is mandatory. Select at least 2 activities to submit.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit() 
                    ? () => _submitCleaningWithOptions(roomNumber, userId, {
                        'roomCleaning': _roomCleaning,
                        'toiletCleaning': _toiletCleaning,
                        'corridorCleaning': _corridorCleaning,
                      })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit() ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'SUBMIT CLEANING',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitCleaningWithOptions(String roomNumber, String userId, Map<String, bool> options) {
    if (!options['roomCleaning']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room cleaning is mandatory!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final selectedActivities = <String>[];
    if (options['roomCleaning']!) selectedActivities.add('Room swept and mopped');
    if (options['toiletCleaning']!) selectedActivities.add('Toilet sanitized');
    if (options['corridorCleaning']!) selectedActivities.add('Corridor cleaned');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Cleaning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room: $roomNumber'),
            const SizedBox(height: 8),
            const Text('Selected activities:'),
            ...selectedActivities.map((activity) => Text('• $activity')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveCleaningSubmissionWithOptions(roomNumber, userId, selectedActivities);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _saveCleaningSubmissionWithOptions(String roomNumber, String userId, List<String> activities) {
    final cleaningData = HiveStorage.loadList(HiveStorage.appStateBox, 'room_cleaning_submissions');
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final submission = {
      'roomNumber': roomNumber,
      'studentId': userId,
      'date': today,
      'time': time,
      'timestamp': now.toIso8601String(),
      'activities': activities,
    };
    
    cleaningData.add(submission);
    HiveStorage.saveList(HiveStorage.appStateBox, 'room_cleaning_submissions', cleaningData);
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cleaning activities submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showFloorTable(String floorName, List<Map<String, dynamic>> rooms) {
    final theme = Theme.of(context);
    final cleaningData = HiveStorage.loadList(HiveStorage.appStateBox, 'room_cleaning_submissions');
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          '$floorName - Cleaning Status',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Student Name')),
                DataColumn(label: Text('Room No')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Time')),
              ],
              rows: rooms.map((room) {
                final submission = cleaningData.firstWhere(
                  (s) => s['roomNumber'] == room['roomNumber'] && s['date'] == today,
                  orElse: () => <String, dynamic>{},
                );
                
                return DataRow(
                  cells: [
                    DataCell(Text(room['studentName'] ?? 'N/A')),
                    DataCell(Text(room['roomNumber'])),
                    DataCell(
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showRoomDetails(room['roomNumber'], room['isCompleted'], room['studentName']);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: room['isCompleted'] 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            room['isCompleted'] ? 'Done' : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: room['isCompleted'] ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(submission['time'] ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomDetails(String roomNumber, bool isCompleted, String? studentName) {
    final theme = Theme.of(context);
    final cleaningData = HiveStorage.loadList(HiveStorage.appStateBox, 'room_cleaning_submissions');
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final submission = cleaningData.firstWhere(
      (s) => s['roomNumber'] == roomNumber && s['date'] == today,
      orElse: () => <String, dynamic>{},
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.pending,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Room $roomNumber Details',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Student: ${studentName ?? 'Unknown'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.schedule,
                    color: isCompleted ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted ? 'Cleaning Completed' : 'Cleaning Pending',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(height: 16),
              Text(
                'Submitted at: ${submission['time']}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Activities Completed:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...((submission['activities'] as List<dynamic>?) ?? []).map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _resetAllCleaningData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Cleaning Data'),
        content: const Text('Are you sure you want to reset all cleaning data for today? This will clear all student submissions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final cleaningData = HiveStorage.loadList(HiveStorage.appStateBox, 'room_cleaning_submissions');
              final today = DateTime.now().toIso8601String().split('T')[0];
              
              // Remove today's submissions
              cleaningData.removeWhere((submission) => submission['date'] == today);
              HiveStorage.saveList(HiveStorage.appStateBox, 'room_cleaning_submissions', cleaningData);
              
              setState(() {});
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All cleaning data reset successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}