import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class ComplaintManagementView extends StatefulWidget {
  const ComplaintManagementView({Key? key}) : super(key: key);

  @override
  State<ComplaintManagementView> createState() => _ComplaintManagementViewState();
}

class _ComplaintManagementViewState extends State<ComplaintManagementView> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isWarden = false;

  @override
  void initState() {
    super.initState();
    _checkWardenStatus();
    _loadComplaints();
  }

  void _checkWardenStatus() async {
    final isWarden = await AuthService().isWarden();
    setState(() {
      _isWarden = isWarden;
    });
  }

  void _loadComplaints() {
    final complaints = HiveStorage.loadList(HiveStorage.appStateBox, 'complaints');
    setState(() {
      _complaints = complaints;
    });
  }

  void _resolveComplaint(String complaintId) {
    setState(() {
      for (int i = 0; i < _complaints.length; i++) {
        if (_complaints[i]['id'] == complaintId) {
          _complaints[i]['status'] = 'resolved';
          _complaints[i]['resolvedDate'] = DateTime.now().toIso8601String();
          break;
        }
      }
    });
    
    HiveStorage.saveList(HiveStorage.appStateBox, 'complaints', _complaints);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint resolved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Maintenance':
        return Icons.build;
      case 'Cleanliness':
        return Icons.cleaning_services;
      case 'Noise':
        return Icons.volume_up;
      case 'Security':
        return Icons.security;
      case 'Facilities':
        return Icons.home;
      default:
        return Icons.report_problem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingComplaints = _complaints.where((c) => c['status'] == 'pending').length;
    final resolvedComplaints = _complaints.where((c) => c['status'] == 'resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Management'),
        actions: [
          if (_isWarden)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'WARDEN MODE',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orange.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.pending, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$pendingComplaints',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Pending'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.green.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$resolvedComplaints',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Resolved'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Complaints List
          Expanded(
            child: _complaints.isEmpty
                ? const Center(child: Text('No complaints submitted yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      final isResolved = complaint['status'] == 'resolved';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(complaint['category']),
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(complaint['status']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      complaint['category'],
                                      style: TextStyle(
                                        color: _getStatusColor(complaint['status']),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(complaint['status']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      complaint['status'].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                complaint['studentName'] ?? complaint['studentId'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Room: ${complaint['room']}',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                complaint['description'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Submitted: ${DateTime.parse(complaint['submitDate']).day}/${DateTime.parse(complaint['submitDate']).month}/${DateTime.parse(complaint['submitDate']).year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  if (_isWarden && !isResolved)
                                    ElevatedButton(
                                      onPressed: () => _resolveComplaint(complaint['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Resolve'),
                                    ),
                                ],
                              ),
                              if (isResolved && complaint['resolvedDate'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Resolved: ${DateTime.parse(complaint['resolvedDate']).day}/${DateTime.parse(complaint['resolvedDate']).month}/${DateTime.parse(complaint['resolvedDate']).year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
    );
  }
}