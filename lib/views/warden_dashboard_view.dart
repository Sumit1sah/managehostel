import 'package:flutter/material.dart';
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

  void _loadComplaintStats() {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    setState(() {
      _pendingComplaints = issues.where((c) => c['status'] == 'pending').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F111A), const Color(0xFF1C2033), const Color(0xFF2A2A3A)]
              : [const Color(0xFFF5F5F5), const Color(0xFFE8F5E8), const Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsView()),
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(Icons.settings, color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.withOpacity(0.2), Colors.blue.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Warden Control Center',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete Hostel Management System',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Management Cards
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Management Tools',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 0.9,
                              children: [
                              _buildEnhancedCard(
                                context,
                                'Room\nAvailability',
                                Icons.bed,
                                'Manage allocations',
                                Colors.green,
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RoomAvailabilityView()),
                                ),
                              ),
                              _buildEnhancedCard(
                                context,
                                'Room\nCleaning',
                                Icons.cleaning_services,
                                'Schedule & track',
                                Colors.blue,
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RoomCleaningView()),
                                ),
                              ),
                              _buildEnhancedCard(
                                context,
                                'Quick\nAnnouncement',
                                Icons.campaign,
                                'Post to all students',
                                Colors.purple,
                                _showQuickAnnouncementDialog,
                              ),
                              _buildEnhancedCard(
                                context,
                                'Student ID\nManagement',
                                Icons.people,
                                'Create student accounts',
                                Colors.orange,
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const UserManagementView()),
                                ),
                              ),
                              _buildEnhancedCard(
                                context,
                                'Student\nIssues',
                                Icons.report_problem,
                                '$_pendingComplaints pending',
                                Colors.red,
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const IssueManagementView()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    Color accentColor,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.surface, theme.colorScheme.surface.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
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