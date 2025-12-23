import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class IssueView extends StatefulWidget {
  const IssueView({Key? key}) : super(key: key);

  @override
  State<IssueView> createState() => _IssueViewState();
}

class _IssueViewState extends State<IssueView> {
  @override
  void initState() {
    super.initState();
    _cleanupOldCompletedIssues();
  }

  void _cleanupOldCompletedIssues() {
    final now = DateTime.now();
    
    // Clean up old issues
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    final filteredIssues = issues.where((issue) {
      final status = issue['status'] ?? 'pending';
      if (status == 'resolved' || status == 'rejected') {
        final completedDateStr = issue['${status}Date'];
        if (completedDateStr != null) {
          final completedDate = DateTime.parse(completedDateStr);
          return now.difference(completedDate).inHours < 24;
        }
      }
      return true;
    }).toList();
    
    if (filteredIssues.length != issues.length) {
      HiveStorage.saveList(HiveStorage.appStateBox, 'issues', filteredIssues);
    }
    
    // Clean up old room swap requests
    final requests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    final filteredRequests = requests.where((request) {
      final status = request['status'] ?? 'pending';
      if (status == 'approved' || status == 'rejected') {
        final processedDateStr = request['processedDate'];
        if (processedDateStr != null) {
          final processedDate = DateTime.parse(processedDateStr);
          return now.difference(processedDate).inHours < 24;
        }
      }
      return true;
    }).toList();
    
    if (filteredRequests.length != requests.length) {
      HiveStorage.saveList(HiveStorage.appStateBox, 'room_swap_requests', filteredRequests);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Issue'),
        actions: [
          IconButton(
            onPressed: _createTestIssue,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Create Test Issue',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildQuickIssueSection(),
            const SizedBox(height: 24),
            _buildDetailedIssueButton(),
            const SizedBox(height: 24),
            Expanded(child: _buildMyIssuesSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickIssueSection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text('Quick Issue Report', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Report common issues quickly',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildQuickIssueButton('Maintenance', Icons.build, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickIssueButton('Cleanliness', Icons.cleaning_services, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildQuickIssueButton('Room Swap', Icons.swap_horiz, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickIssueButton('Other', Icons.more_horiz, Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickIssueButton(String category, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _showQuickIssueDialog(category),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedIssueButton() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _showDetailedIssueForm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Submit Detailed Issue',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickIssueDialog(String preSelectedCategory) async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    if (preSelectedCategory == 'Room Swap') {
      _showRoomSwapRequest();
      return;
    }
    
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report $preSelectedCategory Issue'),
        content: TextField(
          controller: descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Describe the issue',
            hintText: 'Please provide details about the problem...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descriptionController.text.isNotEmpty) {
                _submitIssue(userId, preSelectedCategory, descriptionController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showDetailedIssueForm() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    String? selectedCategory;
    final categories = ['Maintenance', 'Cleanliness', 'Noise', 'Security', 'Facilities', 'Other'];
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Issue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Please describe the issue in detail...',
                  border: OutlineInputBorder(),
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
                if (selectedCategory != null && descriptionController.text.isNotEmpty) {
                  _submitIssue(userId, selectedCategory!, descriptionController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitIssue(String userId, String category, String description) async {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final userData = users.firstWhere(
      (user) => user['userId'] == userId,
      orElse: () => <String, dynamic>{},
    );
    
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    
    final issue = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': userId,
      'studentName': userData['name'] ?? userId,
      'room': '${userData['floor'] ?? '0'} - ${userData['room'] ?? '01'}',
      'category': category,
      'description': description,
      'status': 'pending',
      'submitDate': DateTime.now().toIso8601String(),
    };
    
    issues.add(issue);
    HiveStorage.saveList(HiveStorage.appStateBox, 'issues', issues);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRoomSwapRequest() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final userData = users.firstWhere(
      (user) => user['userId'] == userId,
      orElse: () => <String, dynamic>{},
    );
    
    final floors = HiveStorage.load<int>(HiveStorage.appStateBox, 'floors', defaultValue: 2) ?? 2;
    final floorOptions = List.generate(floors, (index) => index.toString());
    
    String? selectedFloor;
    String? selectedRoom;
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Room Swap Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Room: Floor ${userData['floor'] ?? '0'} - Room ${userData['room'] ?? '01'}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFloor,
                decoration: const InputDecoration(
                  labelText: 'Preferred Floor',
                  prefixIcon: Icon(Icons.layers),
                ),
                items: floorOptions.map((floor) => DropdownMenuItem(
                  value: floor,
                  child: Text('Floor $floor'),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedFloor = value;
                    selectedRoom = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (selectedFloor != null)
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Room',
                    prefixIcon: Icon(Icons.room),
                  ),
                  items: _getAvailableRooms(selectedFloor!).map((room) => DropdownMenuItem(
                    value: room,
                    child: Text('Room $room'),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRoom = value;
                    });
                  },
                ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for swap',
                  hintText: 'Please explain why you need a room change...',
                  border: OutlineInputBorder(),
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
                if (selectedFloor != null && selectedRoom != null && reasonController.text.isNotEmpty) {
                  _submitRoomSwapRequest(userId, userData, selectedFloor!, selectedRoom!, reasonController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitRoomSwapRequest(String userId, Map userData, String preferredFloor, String preferredRoom, String reason) {
    final requests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    
    final request = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': userId,
      'studentName': userData['name'] ?? userId,
      'currentFloor': userData['floor'] ?? '0',
      'currentRoom': userData['room'] ?? '01',
      'preferredFloor': preferredFloor,
      'preferredRoom': preferredRoom,
      'reason': reason,
      'status': 'pending',
      'requestDate': DateTime.now().toIso8601String(),
    };
    
    requests.add(request);
    HiveStorage.saveList(HiveStorage.appStateBox, 'room_swap_requests', requests);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room swap request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
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
      
      if (bedStatuses.contains('available')) {
        availableRooms.add(roomNumber);
      }
    }
    
    return availableRooms;
  }

  Widget _buildMyIssuesSection() {
    final theme = Theme.of(context);
    return FutureBuilder<String?>(
      future: AuthService().getUserId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final userId = snapshot.data!;
        final allIssues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
        final allRequests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
        
        final myIssues = allIssues.where((issue) => issue['studentId'] == userId).toList();
        final myRequests = allRequests.where((request) => request['studentId'] == userId).toList();
        
        final allMyItems = [...myIssues, ...myRequests];
        allMyItems.sort((a, b) => (b['submitDate'] ?? b['requestDate'] ?? '').compareTo(a['submitDate'] ?? a['requestDate'] ?? ''));
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('My Submissions', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: allMyItems.isEmpty
                    ? const Center(child: Text('No submissions yet'))
                    : ListView.builder(
                        itemCount: allMyItems.length,
                        itemBuilder: (context, index) {
                          final item = allMyItems[index];
                          final isRoomSwap = item.containsKey('preferredFloor');
                          final status = item['status'] ?? 'pending';
                          
                          Color statusColor;
                          switch (status) {
                            case 'resolved':
                            case 'approved':
                              statusColor = Colors.green;
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = Colors.orange;
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isRoomSwap ? Colors.blue.shade100 : Colors.purple.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isRoomSwap ? 'Room Swap' : item['category'] ?? 'Issue',
                                          style: TextStyle(
                                            color: isRoomSwap ? Colors.blue.shade700 : Colors.purple.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (status == 'pending' || status == 'resolved' || status == 'rejected') ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _deleteSubmission(item, isRoomSwap),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.delete, color: Colors.red, size: 16),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (isRoomSwap) ...[
                                    Text('From: Floor ${item['currentFloor']} - Room ${item['currentRoom']}'),
                                    Text('To: Floor ${item['preferredFloor']} - Room ${item['preferredRoom']}'),
                                    const SizedBox(height: 4),
                                    Text('Reason: ${item['reason']}', style: theme.textTheme.bodySmall),
                                  ] else ...[
                                    Text(item['description'] ?? '', style: theme.textTheme.bodySmall),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteSubmission(Map item, bool isRoomSwap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isRoomSwap ? 'Room Swap Request' : 'Issue'}'),
        content: const Text('Are you sure you want to delete this submission?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isRoomSwap) {
                final requests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
                requests.removeWhere((request) => request['id'] == item['id']);
                HiveStorage.saveList(HiveStorage.appStateBox, 'room_swap_requests', requests);
              } else {
                final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
                issues.removeWhere((issue) => issue['id'] == item['id']);
                HiveStorage.saveList(HiveStorage.appStateBox, 'issues', issues);
              }
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${isRoomSwap ? 'Room swap request' : 'Issue'} deleted successfully!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createTestIssue() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final userData = users.firstWhere(
      (user) => user['userId'] == userId,
      orElse: () => <String, dynamic>{},
    );
    
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    
    final testIssue = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': userId,
      'studentName': userData['name'] ?? 'Test Student',
      'room': '${userData['floor'] ?? '1'} - ${userData['room'] ?? '01'}',
      'category': 'Maintenance',
      'description': 'Test issue: AC not working properly in room. Please check and repair.',
      'status': 'pending',
      'submitDate': DateTime.now().toIso8601String(),
    };
    
    issues.add(testIssue);
    HiveStorage.saveList(HiveStorage.appStateBox, 'issues', issues);
    
    setState(() {}); // Refresh the UI
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test issue created! Check warden dashboard.'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}