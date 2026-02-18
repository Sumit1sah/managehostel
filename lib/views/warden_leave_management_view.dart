import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class WardenLeaveManagementView extends StatefulWidget {
  const WardenLeaveManagementView({Key? key}) : super(key: key);

  @override
  State<WardenLeaveManagementView> createState() => _WardenLeaveManagementViewState();
}

class _WardenLeaveManagementViewState extends State<WardenLeaveManagementView> {
  List<Map<String, dynamic>> _allLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    _allLeaves = HiveStorage.loadList(HiveStorage.appStateBox, 'leave_applications');
    
    // Enrich with student room info
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    for (var leave in _allLeaves) {
      final student = users.firstWhere(
        (u) => u['userId']?.toString() == leave['studentId']?.toString(), 
        orElse: () => <String, dynamic>{}
      );
      if (student.isNotEmpty) {
        leave['floor'] = student['floor']?.toString() ?? 'N/A';
        leave['room'] = student['room']?.toString() ?? 'N/A';
      } else {
        leave['floor'] = 'N/A';
        leave['room'] = 'N/A';
      }
    }
    
    setState(() {});
  }

  void _updateWardenStatus(int index, String status) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status == 'approved' ? 'Approve' : 'Reject'} Leave'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message to student',
            hintText: 'Add a message...',
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
              _allLeaves[index]['wardenStatus'] = status;
              _allLeaves[index]['wardenMessage'] = messageController.text;
              _allLeaves[index]['wardenApprovalDate'] = DateTime.now().toIso8601String();
              HiveStorage.saveList(HiveStorage.appStateBox, 'leave_applications', _allLeaves);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Leave $status'), backgroundColor: status == 'approved' ? Colors.green : Colors.red),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Management')),
      body: _allLeaves.isEmpty
          ? const Center(child: Text('No leave applications'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allLeaves.length,
              itemBuilder: (context, index) {
                final leave = _allLeaves[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(leave['studentName'][0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(leave['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(leave['studentId'], style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                                  Row(
                                    children: [
                                      Icon(Icons.room, size: 14, color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text('Floor ${leave['floor'] ?? 'N/A'} - Room ${leave['room'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(leave['reason'], style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                        Text('${_formatDate(leave['fromDate'])} - ${_formatDate(leave['toDate'])}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusChip('Parent', leave['parentStatus']),
                            const SizedBox(width: 8),
                            _buildStatusChip('Warden', leave['wardenStatus']),
                          ],
                        ),
                        if (leave['parentStatus'] == 'approved' && leave['wardenStatus'] == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _updateWardenStatus(index, 'approved'),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _updateWardenStatus(index, 'rejected'),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(String label, String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Chip(
      label: Text('$label: ${status.toUpperCase()}', style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    final d = DateTime.parse(date);
    return '${d.day}/${d.month}/${d.year}';
  }
}
