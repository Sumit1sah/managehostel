class QueueEntry {
  final String id;
  final String studentId;
  final String studentName;
  final String machineId;
  final DateTime timestamp;
  int position;

  QueueEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.machineId,
    required this.timestamp,
    required this.position,
  });

  int get estimatedWaitMinutes => position * 45;

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'machineId': machineId,
    'timestamp': timestamp.toIso8601String(),
    'position': position,
  };

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
    id: json['id'],
    studentId: json['studentId'],
    studentName: json['studentName'],
    machineId: json['machineId'],
    timestamp: DateTime.parse(json['timestamp']),
    position: json['position'],
  );
}
