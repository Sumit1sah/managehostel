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
  List<Map<String, dynamic>> _filteredIssues = [];
  bool _isWarden = false;
  String _selectedFilter = 'pending';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    final roomSwapRequests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    
    // Convert room swap requests to issue format
    final convertedRequests = roomSwapRequests.map((request) => {
      'id': request['id'],
      'studentId': request['studentId'],
      'studentName': request['studentName'],
      'room': '${request['currentFloor']} - ${request['currentRoom']}',
      'category': 'Room Swap',
      'description': 'From Floor ${request['currentFloor']}-${request['currentRoom']} to Floor ${request['preferredFloor']}-${request['preferredRoom']}. Reason: ${request['reason']}',
      'status': request['status'],
      'submitDate': request['requestDate'],
      'isRoomSwap': true,
      'originalRequest': request,
    }).toList();
    
    setState(() {
      _issues = [...issues, ...convertedRequests];
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_issues);
    
    // Filter by status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((issue) => issue['status'] == _selectedFilter).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((issue) {
        final studentName = (issue['studentName'] ?? '').toString().toLowerCase();
        final studentId = (issue['studentId'] ?? '').toString().toLowerCase();
        final category = (issue['category'] ?? '').toString().toLowerCase();
        final description = (issue['description'] ?? '').toString().toLowerCase();
        final room = (issue['room'] ?? '').toString().toLowerCase();
        
        return studentName.contains(_searchQuery.toLowerCase()) ||
               studentId.contains(_searchQuery.toLowerCase()) ||
               category.contains(_searchQuery.toLowerCase()) ||
               description.contains(_searchQuery.toLowerCase()) ||
               room.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Sort by date (newest first)
    filtered.sort((a, b) => (b['submitDate'] ?? '').compareTo(a['submitDate'] ?? ''));
    
    setState(() {
      _filteredIssues = filtered;
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
    final issue = _issues.firstWhere((i) => i['id'] == issueId);
    
    if (issue['isRoomSwap'] == true) {
      // Handle room swap request
      final requests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
      for (int i = 0; i < requests.length; i++) {
        if (requests[i]['id'] == issueId) {
          requests[i]['status'] = status == 'resolved' ? 'approved' : status;
          requests[i]['processedDate'] = DateTime.now().toIso8601String();
          if (message.isNotEmpty) {
            requests[i]['${status == 'resolved' ? 'approved' : status}Message'] = message;
          }
          break;
        }
      }
      HiveStorage.saveList(HiveStorage.appStateBox, 'room_swap_requests', requests);
    } else {
      // Handle regular issue
      final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
      for (int i = 0; i < issues.length; i++) {
        if (issues[i]['id'] == issueId) {
          issues[i]['status'] = status;
          issues[i]['${status}Date'] = DateTime.now().toIso8601String();
          if (message.isNotEmpty) {
            issues[i]['${status}Message'] = message;
          }
          break;
        }
      }
      HiveStorage.saveList(HiveStorage.appStateBox, 'issues', issues);
    }
    
    _loadIssues(); // Reload to refresh the combined list
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${issue['isRoomSwap'] == true ? 'Room swap request' : 'Issue'} ${status == 'resolved' && issue['isRoomSwap'] == true ? 'approved' : status} successfully!'),
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
                  child: GestureDetector(
                    onTap: () => _setFilter('pending'),
                    child: Card(
                      color: _selectedFilter == 'pending' ? Colors.orange : Colors.orange.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.pending, color: _selectedFilter == 'pending' ? Colors.white : Colors.orange, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '$pendingIssues',
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: _selectedFilter == 'pending' ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Pending',
                              style: TextStyle(
                                color: _selectedFilter == 'pending' ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setFilter('resolved'),
                    child: Card(
                      color: _selectedFilter == 'resolved' ? Colors.green : Colors.green.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, color: _selectedFilter == 'resolved' ? Colors.white : Colors.green, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '$resolvedIssues',
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: _selectedFilter == 'resolved' ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Resolved',
                              style: TextStyle(
                                color: _selectedFilter == 'resolved' ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setFilter('rejected'),
                    child: Card(
                      color: _selectedFilter == 'rejected' ? Colors.red : Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.cancel, color: _selectedFilter == 'rejected' ? Colors.white : Colors.red, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '$rejectedIssues',
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: _selectedFilter == 'rejected' ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Rejected',
                              style: TextStyle(
                                color: _selectedFilter == 'rejected' ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name, ID, category, or room...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(height: 16),
          // Issues List
          Expanded(
            child: _filteredIssues.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'No issues found matching "$_searchQuery"'
                              : 'No ${_selectedFilter} issues',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredIssues.length,
                    itemBuilder: (context, index) {
                      final issue = _filteredIssues[index];
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
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Student ID: ${issue['studentId']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          'Submitted: ${DateTime.parse(issue['submitDate']).day}/${DateTime.parse(issue['submitDate']).month}/${DateTime.parse(issue['submitDate']).year}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isWarden && isPending) ...[
                                    ElevatedButton(
                                      onPressed: () => _resolveIssue(issue['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 32),
                                      ),
                                      child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _rejectIssue(issue['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 32),
                                      ),
                                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                  if (_isWarden && !isPending)
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.info_outline),
                                      tooltip: 'View Details',
                                    ),
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

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}