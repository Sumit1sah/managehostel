import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class ParentChatView extends StatefulWidget {
  final String parentId;
  final String studentId;

  const ParentChatView({
    Key? key,
    required this.parentId,
    required this.studentId,
  }) : super(key: key);

  @override
  State<ParentChatView> createState() => _ParentChatViewState();
}

class _ParentChatViewState extends State<ParentChatView> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    _messages = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${widget.parentId}');
    
    // Mark all warden messages as read
    bool hasUnread = false;
    for (var msg in _messages) {
      if (msg['from'] == 'warden' && msg['read'] != true) {
        msg['read'] = true;
        hasUnread = true;
      }
    }
    
    if (hasUnread) {
      HiveStorage.saveList(HiveStorage.appStateBox, 'parent_messages_${widget.parentId}', _messages);
    }
    
    setState(() {});
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    _messages.add({
      'from': widget.parentId,
      'to': 'warden',
      'message': _messageController.text,
      'timestamp': DateTime.now().toIso8601String(),
      'studentId': widget.studentId,
    });
    HiveStorage.saveList(HiveStorage.appStateBox, 'parent_messages_${widget.parentId}', _messages);
    _messageController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat with Warden'),
            Text('Hostel Management', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet. Start a conversation!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isParent = msg['from'] == widget.parentId;

                      // Check if we need to show date separator
                      bool showDate = false;
                      if (index == 0) {
                        showDate = true;
                      } else {
                        final prevMsg = _messages[index - 1];
                        final prevDate = DateTime.parse(prevMsg['timestamp']);
                        final currDate = DateTime.parse(msg['timestamp']);
                        if (prevDate.day != currDate.day || prevDate.month != currDate.month || prevDate.year != currDate.year) {
                          showDate = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _formatDate(msg['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Align(
                            alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isParent ? theme.colorScheme.primary : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['message'],
                                    style: TextStyle(color: isParent ? Colors.white : theme.colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(msg['timestamp']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isParent ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.parse(timestamp);
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.parse(timestamp);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
