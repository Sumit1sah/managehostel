import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class IssueManagementView extends StatefulWidget {
  const IssueManagementView({Key? key}) : super(key: key);

  @override
  State<IssueManagementView> createState() => _IssueManagementViewState();
}

class _IssueManagementViewState extends State<IssueManagementView> {
  List<Map<String, dynamic>> _issues = [];
  bool _isWarden = false;

  @override
  void initState() {
    super.initState();
    _checkWardenStatus();
    _loadIssues();
  }

  void _checkWardenStatus() async {
    final isWarden = await AuthService().isWarden();
    setState(() {
      _isWarden = isWarden;
    });
  }

  void _loadIssues() {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    setState(() {
      _issues = issues;
    });
  }

  void _resolveIssue(String issueId) {
    _showActionDialog(issueId, 'resolved', 'Resolve Issue', 'Mark this issue as resolved?');
  }

  void _rejectIssue(String issueId) {
    _showActionDialog(issueId, 'rejected', 'Reject Issue', 'Mark this issue as rejected?');
  }

  void _showActionDialog(String issueId, String status, String title, String message) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: status == 'resolved' ? 'Resolution message (optional)' : 'Rejection reason',
                hintText: status == 'resolved' 
                    ? 'Describe how the issue was resolved...'
                    : 'Explain why this issue is being rejected...',
                border: const OutlineInputBorder(),
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
              if (status == 'rejected' && messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rejection reason is required')),
                );
                return;
              }
              _updateIssueStatus(issueId, status, messageController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'resolved' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'resolved' ? 'Resolve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _updateIssueStatus(String issueId, String status, String message) {
    setState(() {
      for (int i = 0; i < _issues.length; i++) {
        if (_issues[i]['id'] == issueId) {
          _issues[i]['status'] = status;
          _issues[i]['${status}Date'] = DateTime.now().toIso8601String();
          if (message.isNotEmpty) {
            _issues[i]['${status}Message'] = message;
          }
          break;
        }
      }
    });
    
    HiveStorage.saveList(HiveStorage.appStateBox, 'issues', _issues);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Issue ${status} successfully!'),
        backgroundColor: status == 'resolved' ? Colors.green : Colors.red,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
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
    final pendingIssues = _issues.where((c) => c['status'] == 'pending').length;
    final resolvedIssues = _issues.where((c) => c['status'] == 'resolved').length;
    final rejectedIssues = _issues.where((c) => c['status'] == 'rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Management'),
        actions: [
          if (_isWarden)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'WARDEN MODE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                            '$pendingIssues',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Pending'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                            '$resolvedIssues',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Resolved'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$rejectedIssues',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Rejected'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Issues List
          Expanded(
            child: _issues.isEmpty
                ? const Center(child: Text('No issues submitted yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _issues.length,
                    itemBuilder: (context, index) {
                      final issue = _issues[index];
                      final isResolved = issue['status'] == 'resolved';
                      final isRejected = issue['status'] == 'rejected';
                      final isPending = issue['status'] == 'pending';
                      
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
                                    _getCategoryIcon(issue['category']),
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(issue['status']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      issue['category'],
                                      style: TextStyle(
                                        color: _getStatusColor(issue['status']),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(issue['status']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      issue['status'].toUpperCase(),
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
                                issue['studentName'] ?? issue['studentId'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Room: ${issue['room']}',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                issue['description'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Submitted: ${DateTime.parse(issue['submitDate']).day}/${DateTime.parse(issue['submitDate']).month}/${DateTime.parse(issue['submitDate']).year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  if (_isWarden && isPending) ...[
                                    ElevatedButton(
                                      onPressed: () => _resolveIssue(issue['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Resolve'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _rejectIssue(issue['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ],
                              ),
                              if (isResolved && issue['resolvedDate'] != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Resolved: ${DateTime.parse(issue['resolvedDate']).day}/${DateTime.parse(issue['resolvedDate']).month}/${DateTime.parse(issue['resolvedDate']).year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (issue['resolvedMessage'] != null && issue['resolvedMessage'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Resolution: ${issue['resolvedMessage']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.green),
                                    ),
                                  ),
                              ],
                              if (isRejected && issue['rejectedDate'] != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Rejected: ${DateTime.parse(issue['rejectedDate']).day}/${DateTime.parse(issue['rejectedDate']).month}/${DateTime.parse(issue['rejectedDate']).year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (issue['rejectedMessage'] != null && issue['rejectedMessage'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Reason: ${issue['rejectedMessage']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.red),
                                    ),
                                  ),
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
  }
}