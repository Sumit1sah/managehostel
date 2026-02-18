import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class LeaveApplicationView extends StatefulWidget {
  final String studentId;
  final String studentName;

  const LeaveApplicationView({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<LeaveApplicationView> createState() => _LeaveApplicationViewState();
}

class _LeaveApplicationViewState extends State<LeaveApplicationView> {
  final _reasonController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  List<Map<String, dynamic>> _myLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    final allLeaves = HiveStorage.loadList(HiveStorage.appStateBox, 'leave_applications');
    _myLeaves = allLeaves.where((l) => l['studentId'] == widget.studentId).toList();
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
      'studentId': widget.studentId,
      'studentName': widget.studentName,
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(leave['reason'], style: const TextStyle(fontWeight: FontWeight.bold)),
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
