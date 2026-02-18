import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';
import 'issue_management_view.dart';
import 'leave_application_view.dart';
import 'holiday_list_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isWarden = false;
  int _pendingComplaints = 0;

  @override
  void initState() {
    super.initState();
    _checkWardenStatus();
    _loadComplaintStats();
  }

  void _checkWardenStatus() async {
    final isWarden = await AuthService().isWarden();
    setState(() {
      _isWarden = isWarden;
    });
  }

  void _loadComplaintStats() {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    setState(() {
      _pendingComplaints = issues.where((c) => c['status'] == 'pending').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (!_isWarden) _buildQuickIssueSection(),
                const SizedBox(height: 24),
                _buildComplaintCard(),
                const SizedBox(height: 24),
                _buildMetricsRow(),
                const SizedBox(height: 24),
                _buildChartCard(),
                const SizedBox(height: 24),
                _buildDataGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2033).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.dashboard, color: Color(0xFF64FFDA), size: 28),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
              Text('Analytics Overview', style: TextStyle(fontSize: 14, color: Color(0xFFC9CED6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Active Users', '2,847', Icons.people, const Color(0xFF64FFDA))),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Revenue', '\$12.4K', Icons.trending_up, const Color(0xFF40E0D0))),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Orders', '1,234', Icons.shopping_cart, const Color(0xFFB19CD9))),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2033).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFFC9CED6))),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2033).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFFFFE082), size: 24),
              SizedBox(width: 12),
              Text('Performance Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF64FFDA).withOpacity(0.1),
                  const Color(0xFF64FFDA).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Chart Area', style: TextStyle(color: Color(0xFFC9CED6), fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2033).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_chart, color: Color(0xFF40E0D0), size: 24),
              SizedBox(width: 12),
              Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(4, (index) => _buildDataRow('Item ${index + 1}', 'Status Active', const Color(0xFF64FFDA))),
        ],
      ),
    );
  }

  Widget _buildDataRow(String title, String subtitle, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: Color(0xFFC9CED6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard() {
    return GestureDetector(
      onTap: _isWarden 
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueManagementView()))
          : _showIssueForm,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2033).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.report_problem, color: Colors.orange, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isWarden ? 'Student Issues' : 'Submit Issue',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isWarden 
                        ? '$_pendingComplaints pending issues'
                        : 'Report issues or problems',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFC9CED6)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFC9CED6), size: 16),
          ],
        ),
      ),
    );
  }

  void _showIssueForm() async {
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
    // Get student info
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

  Widget _buildQuickIssueSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2033).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem, color: Color(0xFFFF6B6B), size: 24),
              SizedBox(width: 12),
              Text('Quick Issue Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Report issues quickly to the warden',
            style: TextStyle(fontSize: 14, color: Color(0xFFC9CED6)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickIssueButton('Maintenance', Icons.build, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickIssueButton('Cleanliness', Icons.cleaning_services, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickIssueButton('Other', Icons.more_horiz, Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final userId = await AuthService().getUserId();
                    if (userId == null) return;
                    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
                    final userData = users.firstWhere((u) => u['userId'] == userId, orElse: () => {});
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApplicationView(studentId: userId, studentName: userData['name'] ?? userId)));
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Apply for Leave'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF64FFDA),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayListView())),
                  icon: const Icon(Icons.event),
                  label: const Text('Holiday List'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFFB19CD9),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
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

  void _showQuickIssueDialog(String preSelectedCategory) async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report $preSelectedCategory Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                hintText: 'Please provide details about the problem...',
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
}