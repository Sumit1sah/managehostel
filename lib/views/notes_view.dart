import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class NotesView extends StatefulWidget {
  const NotesView({Key? key}) : super(key: key);

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  List<Map<String, String>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final data = HiveStorage.loadList(HiveStorage.appStateBox, 'notes_list');
    setState(() {
      notes = data.map((e) => Map<String, String>.from(e)).toList();
    });
  }

  Future<void> _saveNotes() async {
    await HiveStorage.saveList(HiveStorage.appStateBox, 'notes_list', notes);
  }

  void _addNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('New Note'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      notes.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'title': titleController.text,
                        'content': contentController.text,
                        'date': DateTime.now().toString(),
                      });
                    });
                    _saveNotes();
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Start writing...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editNote(int index) {
    final note = notes[index];
    final titleController = TextEditingController(text: note['title']);
    final contentController = TextEditingController(text: note['content']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Edit Note'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      notes[index] = {
                        'id': note['id']!,
                        'title': titleController.text,
                        'content': contentController.text,
                        'date': note['date']!,
                      };
                    });
                    _saveNotes();
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Start writing...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewNote(Map<String, String> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(note['title']!)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(note['content']!, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() => notes.removeAt(index));
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNote),
        ],
      ),
      body: notes.isEmpty
          ? const Center(child: Text('No notes yet. Tap + to add one!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final date = DateTime.parse(note['date']!);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.note, color: Colors.teal),
                    title: Text(note['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editNote(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(index),
                        ),
                      ],
                    ),
                    onTap: () => _viewNote(note),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
