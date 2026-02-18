import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';
import 'issue_management_view.dart';
import 'leave_application_view.dart';
import 'holiday_list_view.dart';
import 'settings_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String? _userId;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final userData = users.firstWhere((u) => u['userId'] == userId, orElse: () => {});
    
    setState(() {
      _userId = userId;
      _userData = userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _userData?['name'] ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsView()),
            ),
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsRow(),
                  const SizedBox(height: 24),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildServicesGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsRow() {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    final myIssues = issues.where((i) => i['studentId'] == _userId && i['status'] == 'pending').length;
    
    final leaves = HiveStorage.loadList(HiveStorage.appStateBox, 'leave_applications');
    final myLeaves = leaves.where((l) => l['studentId'] == _userId).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'My Room',
            '${_userData?['floor']}-${_userData?['room']}',
            Icons.home_outlined,
            const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueManagementView())),
            child: _buildMetricCard(
              'My Issues',
              myIssues.toString(),
              Icons.error_outline,
              const Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Leave Apps',
            myLeaves.toString(),
            Icons.calendar_today_outlined,
            const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Report Issue',
                Icons.bug_report_outlined,
                const Color(0xFFDC2626),
                _showIssueForm,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Apply Leave',
                Icons.calendar_today_outlined,
                const Color(0xFF7C3AED),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApplicationView(studentId: _userId!, studentName: _userData!['name'] ?? _userId!))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildServiceCard(
          'My Issues',
          'View & Track',
          Icons.bug_report_outlined,
          const Color(0xFFDC2626),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueManagementView())),
        ),
        _buildServiceCard(
          'Leave Status',
          'Applications',
          Icons.calendar_today_outlined,
          const Color(0xFF7C3AED),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApplicationView(studentId: _userId!, studentName: _userData!['name'] ?? _userId!))),
        ),
        _buildServiceCard(
          'Holiday List',
          'View Holidays',
          Icons.event_outlined,
          const Color(0xFF059669),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayListView())),
        ),
        _buildServiceCard(
          'Settings',
          'Preferences',
          Icons.settings_outlined,
          const Color(0xFF6B7280),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView())),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueForm() {
    String? selectedCategory;
    final categories = ['Maintenance', 'Cleanliness', 'Noise', 'Security', 'Facilities', 'Other'];
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Issue'),
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
                  hintText: 'Describe the issue...',
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
                  _submitIssue(selectedCategory!, descriptionController.text);
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

  void _submitIssue(String category, String description) {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    
    final issue = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': _userId,
      'studentName': _userData!['name'] ?? _userId,
      'room': '${_userData!['floor']} - ${_userData!['room']}',
      'category': category,
      'description': description,
      'status': 'pending',
      'submitDate': DateTime.now().toIso8601String(),
    };
    
    issues.add(issue);
    HiveStorage.saveList(HiveStorage.appStateBox, 'issues', issues);
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
