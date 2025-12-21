import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class TimetableView extends StatefulWidget {
  const TimetableView({Key? key}) : super(key: key);

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> {
  final _rollController = TextEditingController();
  String? _section;
  Map<String, List<Map<String, String>>>? _timetable;

  // Sample timetable data
  final Map<String, Map<String, List<Map<String, String>>>> _timetableData = {
    'A': {
      'Monday': [
        {'time': '9:00-10:00', 'subject': 'Mathematics', 'room': 'R101'},
        {'time': '10:00-11:00', 'subject': 'Physics', 'room': 'R102'},
        {'time': '11:30-12:30', 'subject': 'Chemistry', 'room': 'R103'},
        {'time': '2:00-3:00', 'subject': 'English', 'room': 'R104'},
      ],
      'Tuesday': [
        {'time': '9:00-10:00', 'subject': 'Physics', 'room': 'R102'},
        {'time': '10:00-11:00', 'subject': 'Mathematics', 'room': 'R101'},
        {'time': '11:30-12:30', 'subject': 'Computer', 'room': 'Lab1'},
        {'time': '2:00-3:00', 'subject': 'Chemistry', 'room': 'R103'},
      ],
      'Wednesday': [
        {'time': '9:00-10:00', 'subject': 'English', 'room': 'R104'},
        {'time': '10:00-11:00', 'subject': 'Chemistry', 'room': 'R103'},
        {'time': '11:30-12:30', 'subject': 'Mathematics', 'room': 'R101'},
        {'time': '2:00-3:00', 'subject': 'Physics', 'room': 'R102'},
      ],
      'Thursday': [
        {'time': '9:00-10:00', 'subject': 'Computer', 'room': 'Lab1'},
        {'time': '10:00-11:00', 'subject': 'English', 'room': 'R104'},
        {'time': '11:30-12:30', 'subject': 'Physics', 'room': 'R102'},
        {'time': '2:00-3:00', 'subject': 'Mathematics', 'room': 'R101'},
      ],
      'Friday': [
        {'time': '9:00-10:00', 'subject': 'Chemistry', 'room': 'R103'},
        {'time': '10:00-11:00', 'subject': 'Computer', 'room': 'Lab1'},
        {'time': '11:30-12:30', 'subject': 'English', 'room': 'R104'},
        {'time': '2:00-3:00', 'subject': 'Physics', 'room': 'R102'},
      ],
    },
    'B': {
      'Monday': [
        {'time': '9:00-10:00', 'subject': 'Physics', 'room': 'R105'},
        {'time': '10:00-11:00', 'subject': 'Mathematics', 'room': 'R106'},
        {'time': '11:30-12:30', 'subject': 'English', 'room': 'R107'},
        {'time': '2:00-3:00', 'subject': 'Chemistry', 'room': 'R108'},
      ],
      'Tuesday': [
        {'time': '9:00-10:00', 'subject': 'Mathematics', 'room': 'R106'},
        {'time': '10:00-11:00', 'subject': 'Chemistry', 'room': 'R108'},
        {'time': '11:30-12:30', 'subject': 'Physics', 'room': 'R105'},
        {'time': '2:00-3:00', 'subject': 'Computer', 'room': 'Lab2'},
      ],
      'Wednesday': [
        {'time': '9:00-10:00', 'subject': 'Chemistry', 'room': 'R108'},
        {'time': '10:00-11:00', 'subject': 'English', 'room': 'R107'},
        {'time': '11:30-12:30', 'subject': 'Computer', 'room': 'Lab2'},
        {'time': '2:00-3:00', 'subject': 'Mathematics', 'room': 'R106'},
      ],
      'Thursday': [
        {'time': '9:00-10:00', 'subject': 'English', 'room': 'R107'},
        {'time': '10:00-11:00', 'subject': 'Physics', 'room': 'R105'},
        {'time': '11:30-12:30', 'subject': 'Mathematics', 'room': 'R106'},
        {'time': '2:00-3:00', 'subject': 'Chemistry', 'room': 'R108'},
      ],
      'Friday': [
        {'time': '9:00-10:00', 'subject': 'Computer', 'room': 'Lab2'},
        {'time': '10:00-11:00', 'subject': 'Chemistry', 'room': 'R108'},
        {'time': '11:30-12:30', 'subject': 'Physics', 'room': 'R105'},
        {'time': '2:00-3:00', 'subject': 'English', 'room': 'R107'},
      ],
    },
  };

  String _getSectionFromRoll(String rollNo) {
    if (rollNo.isEmpty) return 'A';
    final lastDigit = int.tryParse(rollNo.substring(rollNo.length - 1)) ?? 0;
    return lastDigit % 2 == 0 ? 'A' : 'B';
  }

  void _loadTimetable() {
    if (_rollController.text.isNotEmpty) {
      setState(() {
        _section = _getSectionFromRoll(_rollController.text);
        _timetable = _timetableData[_section!];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Timetable'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rollController,
                    decoration: const InputDecoration(
                      labelText: 'Roll Number',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loadTimetable,
                  child: const Text('Get Timetable'),
                ),
              ],
            ),
          ),
          if (_section != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Section: $_section',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_timetable != null)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _timetable!.entries.map((day) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.key,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...day.value.map((period) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      period['time']!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      period['subject']!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    period['room']!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}