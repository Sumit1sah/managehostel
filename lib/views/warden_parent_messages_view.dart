import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class WardenParentMessagesView extends StatefulWidget {
  const WardenParentMessagesView({Key? key}) : super(key: key);

  @override
  State<WardenParentMessagesView> createState() => _WardenParentMessagesViewState();
}

class _WardenParentMessagesViewState extends State<WardenParentMessagesView> {
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _filteredParents = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterMode = 'all'; // 'all' or 'unread'

  @override
  void initState() {
    super.initState();
    _loadParents();
    _searchController.addListener(_filterParents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadParents() {
    final allParents = HiveStorage.loadList(HiveStorage.appStateBox, 'parents');
    // Filter parents who have started communication
    _parents = allParents.where((parent) {
      final messages = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${parent['parentId']}');
      return messages.isNotEmpty;
    }).toList();
    
    // Sort by most recent message timestamp
    _parents.sort((a, b) {
      final messagesA = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${a['parentId']}');
      final messagesB = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${b['parentId']}');
      
      final lastTimeA = messagesA.isNotEmpty ? DateTime.parse(messagesA.last['timestamp']) : DateTime(2000);
      final lastTimeB = messagesB.isNotEmpty ? DateTime.parse(messagesB.last['timestamp']) : DateTime(2000);
      
      return lastTimeB.compareTo(lastTimeA); // Most recent first
    });
    
    _filteredParents = _parents;
    setState(() {});
  }

  void _filterParents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParents = _parents.where((parent) {
        final studentId = (parent['studentId'] ?? '').toLowerCase();
        final matchesSearch = studentId.contains(query);
        
        if (_filterMode == 'unread') {
          final msgs = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${parent['parentId']}');
          final hasUnread = msgs.any((msg) => msg['from'] == parent['parentId'] && msg['read'] != true);
          return matchesSearch && hasUnread;
        }
        
        return matchesSearch;
      }).toList();
    });
  }

  void _openChat(Map<String, dynamic> parent) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WardenParentChatView(
          parentId: parent['parentId'],
          studentId: parent['studentId'],
        ),
      ),
    );
    _loadParents(); // Refresh to update unread status
  }

  List<Map<String, dynamic>> _getUnreadParents() {
    return _filteredParents.where((p) {
      final msgs = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${p['parentId']}');
      return msgs.any((msg) => msg['from'] == p['parentId'] && msg['read'] != true);
    }).toList();
  }

  List<Map<String, dynamic>> _getReadParents() {
    return _filteredParents.where((p) {
      final msgs = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${p['parentId']}');
      return !msgs.any((msg) => msg['from'] == p['parentId'] && msg['read'] != true);
    }).toList();
  }

  int _getItemCount() {
    if (_filterMode == 'unread') {
      return _filteredParents.length;
    }
    final unread = _getUnreadParents();
    final read = _getReadParents();
    int count = unread.length + read.length;
    if (unread.isNotEmpty) count++; // Add header for unread
    if (read.isNotEmpty) count++; // Add header for read
    if (unread.isNotEmpty && read.isNotEmpty) count++; // Add divider
    return count;
  }

  Widget _buildChatCard(Map<String, dynamic> parent, bool hasUnread) {
    final messages = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${parent['parentId']}');
    final lastMsg = messages.isNotEmpty ? messages.last['message'] : 'No messages yet';
    
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    String studentName = parent['studentId'];
    for (var user in users) {
      if (user['userId'] == parent['studentId']) {
        studentName = user['name']?.toString() ?? parent['studentId'];
        break;
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.family_restroom),
        ),
        title: Text(parent['parentId']),
        subtitle: Text('Student: $studentName (${parent['studentId']})\n$lastMsg', maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: hasUnread
            ? Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _openChat(parent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _parents.where((p) {
      final msgs = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${p['parentId']}');
      return msgs.any((msg) => msg['from'] == p['parentId'] && msg['read'] != true);
    }).length;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Chats')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Student ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterMode = 'all';
                        _filterParents();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _filterMode == 'all' ? Colors.blue : Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'All (${_parents.length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _filterMode == 'all' ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterMode = 'unread';
                        _filterParents();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _filterMode == 'unread' ? Colors.blue : Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Unread ($unreadCount)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _filterMode == 'unread' ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredParents.isEmpty
                ? Center(
                    child: Text(_searchController.text.isNotEmpty
                        ? 'No active chats found for Student ID "${_searchController.text}"'
                        : 'No active chats yet'),
                  )
                : ListView.builder(
                    itemCount: _getItemCount(),
                    itemBuilder: (context, index) {
                      final unreadParents = _getUnreadParents();
                      final readParents = _getReadParents();
                      int currentIndex = index;
                      
                      // Skip headers and dividers if in unread mode
                      if (_filterMode == 'unread') {
                        return _buildChatCard(_filteredParents[index], true);
                      }
                      
                      // Unread header
                      if (unreadParents.isNotEmpty && currentIndex == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'UNREAD (${unreadParents.length})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        );
                      }
                      if (unreadParents.isNotEmpty) currentIndex--;
                      
                      // Unread chats
                      if (currentIndex >= 0 && currentIndex < unreadParents.length) {
                        return _buildChatCard(unreadParents[currentIndex], true);
                      }
                      if (unreadParents.isNotEmpty) currentIndex -= unreadParents.length;
                      
                      // Divider
                      if (unreadParents.isNotEmpty && readParents.isNotEmpty && currentIndex == 0) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          height: 1,
                          color: Colors.grey.shade300,
                        );
                      }
                      if (unreadParents.isNotEmpty && readParents.isNotEmpty) currentIndex--;
                      
                      // Read header
                      if (readParents.isNotEmpty && currentIndex == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'READ (${readParents.length})',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                        );
                      }
                      if (readParents.isNotEmpty) currentIndex--;
                      
                      // Read chats
                      if (currentIndex >= 0 && currentIndex < readParents.length) {
                        return _buildChatCard(readParents[currentIndex], false);
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog() {
    final studentIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: TextField(
          controller: studentIdController,
          decoration: const InputDecoration(
            labelText: 'Enter Student ID',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final studentId = studentIdController.text.trim();
              if (studentId.isNotEmpty) {
                Navigator.pop(context);
                _startChatWithParent(studentId);
              }
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _startChatWithParent(String studentId) {
    final allParents = HiveStorage.loadList(HiveStorage.appStateBox, 'parents');
    final parent = allParents.firstWhere(
      (p) => p['studentId'] == studentId,
      orElse: () => {},
    );
    
    if (parent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No parent found for Student ID: $studentId')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WardenParentChatView(
          parentId: parent['parentId'],
          studentId: parent['studentId'],
        ),
      ),
    ).then((_) => _loadParents());
  }
}

class WardenParentChatView extends StatefulWidget {
  final String parentId;
  final String studentId;

  const WardenParentChatView({Key? key, required this.parentId, required this.studentId}) : super(key: key);

  @override
  State<WardenParentChatView> createState() => _WardenParentChatViewState();
}

class _WardenParentChatViewState extends State<WardenParentChatView> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String _studentName = '';

  @override
  void initState() {
    super.initState();
    _loadStudentName();
    _loadMessages();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    bool hasChanges = false;
    for (var msg in _messages) {
      if (msg['from'] == widget.parentId && msg['read'] != true) {
        msg['read'] = true;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      HiveStorage.saveList(HiveStorage.appStateBox, 'parent_messages_${widget.parentId}', _messages);
    }
  }

  void _loadStudentName() {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    for (var user in users) {
      if (user['userId'] == widget.studentId) {
        _studentName = user['name']?.toString() ?? '';
        break;
      }
    }
    if (mounted) setState(() {});
  }

  void _loadMessages() {
    _messages = HiveStorage.loadList(HiveStorage.appStateBox, 'parent_messages_${widget.parentId}');
    setState(() {});
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;
    
    _messages.add({
      'from': 'warden',
      'to': widget.parentId,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.parentId),
            Text('${_studentName.isNotEmpty ? _studentName : widget.studentId} (${widget.studentId})', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isWarden = msg['from'] == 'warden';
                      final isSeen = msg['read'] == true;
                      
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
                            alignment: isWarden ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isWarden 
                                    ? theme.colorScheme.primary 
                                    : (isSeen ? theme.colorScheme.surface : Colors.blue.shade50),
                                borderRadius: BorderRadius.circular(12),
                                border: !isWarden && !isSeen 
                                    ? Border.all(color: Colors.blue.shade200, width: 2)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['message'],
                                    style: TextStyle(
                                      color: isWarden ? Colors.white : theme.colorScheme.onSurface,
                                      fontWeight: !isWarden && !isSeen ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(msg['timestamp']),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isWarden ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                      if (!isWarden && !isSeen)
                                        const SizedBox(width: 4),
                                      if (!isWarden && !isSeen)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
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
