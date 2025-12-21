import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';

class AnnouncementView extends StatefulWidget {
  const AnnouncementView({Key? key}) : super(key: key);

  @override
  State<AnnouncementView> createState() => _AnnouncementViewState();
}

class _AnnouncementViewState extends State<AnnouncementView> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isWarden = false;

  @override
  void initState() {
    super.initState();
    _checkWardenStatus();
    _loadAnnouncements();
  }

  void _checkWardenStatus() async {
    final isWarden = await AuthService().isWarden();
    setState(() {
      _isWarden = isWarden;
    });
  }

  void _loadAnnouncements() {
    final announcements = HiveStorage.loadList(HiveStorage.appStateBox, 'announcements');
    setState(() {
      _announcements = announcements.cast<Map<String, dynamic>>();
      _announcements.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    });
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String priority = 'Normal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['Normal', 'Important', 'Urgent'].map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    priority = value ?? 'Normal';
                  });
                },
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
                if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                  _addAnnouncement(titleController.text, messageController.text, priority);
                  Navigator.pop(context);
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  void _addAnnouncement(String title, String message, String priority) {
    final announcement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'priority': priority,
      'date': DateTime.now().toIso8601String(),
      'author': 'Warden',
    };

    _announcements.insert(0, announcement);
    HiveStorage.saveList(HiveStorage.appStateBox, 'announcements', _announcements);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Announcement posted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteAnnouncement(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _announcements.removeWhere((a) => a['id'] == id);
              HiveStorage.saveList(HiveStorage.appStateBox, 'announcements', _announcements);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'Important':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          if (_isWarden)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddAnnouncementDialog,
            ),
        ],
      ),
      body: _announcements.isEmpty
          ? const Center(child: Text('No announcements yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                final date = DateTime.parse(announcement['date']);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(announcement['priority']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                announcement['priority'],
                                style: TextStyle(
                                  color: _getPriorityColor(announcement['priority']),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (_isWarden)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteAnnouncement(announcement['id']),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          announcement['title'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(announcement['message']),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              announcement['author'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const Spacer(),
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _isWarden
          ? FloatingActionButton(
              onPressed: _showAddAnnouncementDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}