import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class LeaveView extends StatefulWidget {
  const LeaveView({Key? key}) : super(key: key);

  @override
  State<LeaveView> createState() => _LeaveViewState();
}

class _LeaveViewState extends State<LeaveView> {
  final _reasonController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  List<Map<String, dynamic>> _myLeaves = [];
  String? _studentId;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  void _loadStudentData() async {
    _studentId = await AuthService().getUserId();
    if (_studentId != null) {
      final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
      final userData = users.firstWhere((u) => u['userId'] == _studentId, orElse: () => {});
      _studentName = userData['name'] ?? _studentId;
      _loadLeaves();
    }
  }

  void _loadLeaves() {
    if (_studentId == null) return;
    final allLeaves = HiveStorage.loadList(HiveStorage.appStateBox, 'leave_applications');
    _myLeaves = allLeaves.where((l) => l['studentId'] == _studentId).toList();
    setState(() {});
  }

  void _applyLeave() {
    if (_fromDate == null || _toDate == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final leaves = HiveStorage.loadList(HiveStorage.appStateBox, 'leave_applications');
    leaves.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': _studentId,
      'studentName': _studentName,
      'reason': _reasonController.text,
      'fromDate': _fromDate!.toIso8601String(),
      'toDate': _toDate!.toIso8601String(),
      'appliedDate': DateTime.now().toIso8601String(),
      'parentStatus': 'pending',
      'wardenStatus': 'pending',
    });
    HiveStorage.saveList(HiveStorage.appStateBox, 'leave_applications', leaves);

    _reasonController.clear();
    _fromDate = null;
    _toDate = null;
    _loadLeaves();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leave application submitted'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Leave'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apply for Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _fromDate = date);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_fromDate == null ? 'From Date' : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate: _fromDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _toDate = date);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_toDate == null ? 'To Date' : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _applyLeave,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                    child: const Text('Submit Application'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('My Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            _myLeaves.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No applications yet', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = _myLeaves[index];
                      final isFullyApproved = leave['parentStatus'] == 'approved' && leave['wardenStatus'] == 'approved';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isFullyApproved ? Colors.green.withOpacity(0.1) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(leave['reason'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                  if (isFullyApproved) const Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${_formatDate(leave['fromDate'])} - ${_formatDate(leave['toDate'])}'),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  _buildStatusChip('Parent', leave['parentStatus']),
                                  const SizedBox(width: 8),
                                  _buildStatusChip('Warden', leave['wardenStatus']),
                                ],
                              ),
                              if (leave['parentMessage'] != null && leave['parentMessage'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.family_restroom, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('Parent: ${leave['parentMessage']}', style: const TextStyle(fontSize: 12))),
                                    ],
                                  ),
                                ),
                              ],
                              if (leave['wardenMessage'] != null && leave['wardenMessage'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.admin_panel_settings, size: 16, color: Colors.purple),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('Warden: ${leave['wardenMessage']}', style: const TextStyle(fontSize: 12))),
                                    ],
                                  ),
                                ),
                              ],
                              if (isFullyApproved) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.celebration, color: Colors.green),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('✓ Leave Approved! Enjoy your holiday.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
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
