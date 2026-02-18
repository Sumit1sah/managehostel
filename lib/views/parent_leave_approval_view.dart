import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class ParentLeaveApprovalView extends StatefulWidget {
  final String studentId;

  const ParentLeaveApprovalView({Key? key, required this.studentId}) : super(key: key);

  @override
  State<ParentLeaveApprovalView> createState() => _ParentLeaveApprovalViewState();
}

class _ParentLeaveApprovalViewState extends State<ParentLeaveApprovalView> {
  List<Map<String, dynamic>> _pendingLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    final allLeaves = HiveStorage.loadList(HiveStorage.appStateBox, 'leave_applications');
    final now = DateTime.now();
    
    _pendingLeaves = allLeaves.where((l) {
      if (l['studentId'] != widget.studentId) return false;
      if (l['parentStatus'] != 'pending') return false;
      
      // Check if leave is within 48 hours of application
      if (l['appliedDate'] != null) {
        final appliedDate = DateTime.parse(l['appliedDate']);
        final hoursSinceApplied = now.difference(appliedDate).inHours;
        if (hoursSinceApplied > 48) return false;
      }
      
      return true;
    }).toList();
    setState(() {});
  }

  void _updateStatus(int index, String status) {
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
              final allLeaves = HiveStorage.loadList(HiveStorage.appStateBox, 'leave_applications');
              final leaveId = _pendingLeaves[index]['id'];
              
              for (var leave in allLeaves) {
                if (leave['id'] == leaveId) {
                  leave['parentStatus'] = status;
                  leave['parentMessage'] = messageController.text;
                  leave['parentApprovalDate'] = DateTime.now().toIso8601String();
                  break;
                }
              }
              
              HiveStorage.saveList(HiveStorage.appStateBox, 'leave_applications', allLeaves);
              Navigator.pop(context);
              _loadLeaves();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Approve Leave')),
      body: _pendingLeaves.isEmpty
          ? const Center(child: Text('No pending leave applications'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingLeaves.length,
              itemBuilder: (context, index) {
                final leave = _pendingLeaves[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(leave['reason'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('From: ${_formatDate(leave['fromDate'])}'),
                        Text('To: ${_formatDate(leave['toDate'])}'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus(index, 'approved'),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus(index, 'rejected'),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    final d = DateTime.parse(date);
    return '${d.day}/${d.month}/${d.year}';
  }
}
