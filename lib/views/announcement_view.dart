import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    final now = DateTime.now();
    
    // Filter out announcements older than 48 hours
    final validAnnouncements = announcements.where((announcement) {
      final announcementDate = DateTime.parse(announcement['date']);
      final hoursDifference = now.difference(announcementDate).inHours;
      return hoursDifference <= 48;
    }).toList();
    
    // Save filtered announcements back to storage
    if (validAnnouncements.length != announcements.length) {
      HiveStorage.saveList(HiveStorage.appStateBox, 'announcements', validAnnouncements);
    }
    
    setState(() {
      _announcements = validAnnouncements.cast<Map<String, dynamic>>();
      _announcements.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    });
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String priority = 'Normal';
    String? attachmentPath;
    String? attachmentType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Announcement'),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAttachment('image', setDialogState, (path, type) {
                          attachmentPath = path;
                          attachmentType = type;
                        }),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAttachment('pdf', setDialogState, (path, type) {
                          attachmentPath = path;
                          attachmentType = type;
                        }),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Add PDF'),
                      ),
                    ),
                  ],
                ),
                if (attachmentPath != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(attachmentType == 'image' ? Icons.image : Icons.picture_as_pdf),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            attachmentPath!.split('/').last,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              attachmentPath = null;
                              attachmentType = null;
                            });
                          },
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                  _addAnnouncement(titleController.text, messageController.text, priority, attachmentPath, attachmentType);
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

  void _addAnnouncement(String title, String message, String priority, String? attachmentPath, String? attachmentType) {
    final announcement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'priority': priority,
      'date': DateTime.now().toIso8601String(),
      'author': 'Warden',
      'attachmentPath': attachmentPath,
      'attachmentType': attachmentType,
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

  Future<void> _pickAttachment(String type, StateSetter setDialogState, Function(String?, String?) onPicked) async {
    try {
      if (type == 'image') {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      setDialogState(() {
                        onPicked(pickedFile.path, 'image');
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setDialogState(() {
                        onPicked(pickedFile.path, 'image');
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      } else if (type == 'pdf') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF picker not implemented yet')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
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
                  child: InkWell(
                    onTap: () => _showAnnouncementDetails(announcement),
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
                          Text(
                            announcement['message'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (announcement['attachmentPath'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    announcement['attachmentType'] == 'image' ? Icons.image : Icons.picture_as_pdf,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Attachment',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTime(date),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${date.day}/${date.month}/${date.year}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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

  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    final date = DateTime.parse(announcement['date']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
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
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement['title'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                announcement['message'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    announcement['author'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }
}