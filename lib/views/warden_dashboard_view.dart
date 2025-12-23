import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'room_availability_view.dart';
import 'room_cleaning_view.dart';
import 'user_management_view.dart';
import 'settings_view.dart';
import 'complaint_management_view.dart';
import 'issue_management_view.dart';
import '../core/storage/hive_storage.dart';

class WardenDashboardView extends StatefulWidget {
  const WardenDashboardView({Key? key}) : super(key: key);

  @override
  State<WardenDashboardView> createState() => _WardenDashboardViewState();
}

class _WardenDashboardViewState extends State<WardenDashboardView> {
  int _pendingComplaints = 0;

  @override
  void initState() {
    super.initState();
    _loadComplaintStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadComplaintStats(); // Refresh when returning to dashboard
    _debugPrintIssues(); // Debug: Print current issues
  }

  void _loadComplaintStats() {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    final roomSwapRequests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    
    final pendingIssues = issues.where((c) => c['status'] == 'pending').length;
    final pendingRoomSwaps = roomSwapRequests.where((r) => r['status'] == 'pending').length;
    
    setState(() {
      _pendingComplaints = pendingIssues + pendingRoomSwaps;
    });
  }

  void _debugPrintIssues() {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    final roomSwapRequests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    
    print('DEBUG: Total issues in storage: ${issues.length}');
    print('DEBUG: Total room swap requests in storage: ${roomSwapRequests.length}');
    
    for (var issue in issues) {
      print('Issue: ${issue['studentName']} - ${issue['category']} - ${issue['status']}');
    }
    
    for (var request in roomSwapRequests) {
      print('Room Swap: ${request['studentName']} - ${request['status']}');
    }
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
                  'Warden Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Management Console',
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
      body: SingleChildScrollView(
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
              'Management Tools',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildManagementGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users')
        .where((user) => user['role'] != 'warden')
        .length;
    
    // Calculate occupancy based on students vs total beds
    final occupiedBeds = users;
    final totalBeds = 100; // Assuming 100 total beds in hostel
    final occupancyRate = totalBeds > 0 ? ((occupiedBeds / totalBeds) * 100).round() : 0;
    
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showActiveIssues,
            child: _buildMetricCard(
              'Active Issues',
              _pendingComplaints.toString(),
              Icons.error_outline,
              const Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _showStudentList,
            child: _buildMetricCard(
              'Total Students',
              users.toString(),
              Icons.people_outline,
              const Color(0xFF059669),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Occupancy',
            '${occupancyRate}%',
            Icons.home_outlined,
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
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'New Announcement',
            Icons.campaign_outlined,
            const Color(0xFF7C3AED),
            _showQuickAnnouncementDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'View Issues',
            Icons.bug_report_outlined,
            const Color(0xFFDC2626),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueManagementView())),
          ),
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
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildManagementCard(
          'Room Management',
          'Availability & Allocation',
          Icons.hotel_outlined,
          const Color(0xFF059669),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomAvailabilityView())),
        ),
        _buildManagementCard(
          'Student Accounts',
          'User Management',
          Icons.people_outline,
          const Color(0xFF2563EB),
          () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementView()));
            setState(() {}); // Refresh dashboard after returning
          },
        ),
        _buildManagementCard(
          'Room Cleaning',
          'Room Maintenance',
          Icons.cleaning_services_outlined,
          const Color(0xFFD97706),
          () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomCleaningView()));
            setState(() {}); // Refresh to show updated cleaning status
          },
        ),
        _buildManagementCard(
          'System Settings',
          'Configuration',
          Icons.settings_outlined,
          const Color(0xFF6B7280),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView())),
        ),
      ],
    );
  }

  Widget _buildManagementCard(
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

  void _showActiveIssues() {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues')
        .where((issue) => issue['status'] == 'pending')
        .toList();
    
    final roomSwapRequests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests')
        .where((request) => request['status'] == 'pending')
        .toList();
    
    // Convert room swap requests to issue format for display
    final convertedRequests = roomSwapRequests.map((request) => {
      'studentName': request['studentName'],
      'studentId': request['studentId'],
      'room': '${request['currentFloor']} - ${request['currentRoom']}',
      'category': 'Room Swap',
      'description': 'From Floor ${request['currentFloor']}-${request['currentRoom']} to Floor ${request['preferredFloor']}-${request['preferredRoom']}. Reason: ${request['reason']}',
      'submitDate': request['requestDate'],
    }).toList();
    
    final allActiveIssues = [...issues, ...convertedRequests];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Active Issues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () => _exportToExcel(allActiveIssues),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: allActiveIssues.isEmpty
                ? const Center(
                    child: Text(
                      'No active issues',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Table(
                        border: TableBorder.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(3),
                          4: FlexColumnWidth(1.5),
                        },
                        children: [
                          // Header Row
                          const TableRow(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9FAFB),
                            ),
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Student Name',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Roll No',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Room No',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Complaint',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Data Rows
                          ...allActiveIssues.map((issue) => TableRow(
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    issue['studentName'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    issue['studentId'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    issue['room'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '${issue['category']}: ${issue['description']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF111827),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _formatDate(issue['submitDate']),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )).toList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _exportToExcel(List<dynamic> issues) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Active Issues Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Student Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Roll No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Room No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...issues.map((issue) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(issue['studentName'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(issue['studentId'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(issue['room'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${issue['category']}: ${issue['description']}' ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_formatDate(issue['submitDate'])),
                      ),
                    ],
                  )).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/active_issues_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles([XFile(file.path)], text: 'Active Issues Report');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF exported and ready to share!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
  void _showStudentList() {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users')
        .where((user) => user['role'] != 'warden')
        .toList();

    // Sort by floor first, then alphabetically by name
    users.sort((a, b) {
      final floorA = int.tryParse(a['floor']?.toString() ?? '0') ?? 0;
      final floorB = int.tryParse(b['floor']?.toString() ?? '0') ?? 0;
      
      if (floorA != floorB) {
        return floorA.compareTo(floorB);
      }
      
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Student List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: users.isEmpty
                ? const Center(
                    child: Text(
                      'No students found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Table(
                        border: TableBorder.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1.5),
                          4: FlexColumnWidth(2),
                        },
                        children: [
                          // Header Row
                          const TableRow(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9FAFB),
                            ),
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Student Name',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Roll No',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Floor',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Room No',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Contact',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Data Rows
                          ...users.map((user) => TableRow(
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    user['name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    user['userId'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    user['floor']?.toString() ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    user['room']?.toString() ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    user['phone'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )).toList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showQuickAnnouncementDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Announcement'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message to all students',
            hintText: 'This will be shown to students on login...',
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
              if (messageController.text.isNotEmpty) {
                _postQuickAnnouncement(messageController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _postQuickAnnouncement(String message) {
    final announcements = HiveStorage.loadList(HiveStorage.appStateBox, 'announcements');
    
    final announcement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Important Notice',
      'message': message,
      'priority': 'Important',
      'date': DateTime.now().toIso8601String(),
      'author': 'Warden',
      'showOnLogin': true,
    };
    
    announcements.insert(0, announcement);
    HiveStorage.saveList(HiveStorage.appStateBox, 'announcements', announcements);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Announcement posted! Students will see it on login.'),
        backgroundColor: Colors.green,
      ),
    );
  }


}