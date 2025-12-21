enum MachineStatus { available, inUse, maintenance }

class WashingMachine {
  final String id;
  final String location;
  MachineStatus status;
  String? currentUserId;
  DateTime? currentStartTime;
  final int cycleMinutes;

  WashingMachine({
    required this.id,
    required this.location,
    this.status = MachineStatus.available,
    this.currentUserId,
    this.currentStartTime,
    this.cycleMinutes = 45,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'location': location,
    'status': status.name,
    'currentUserId': currentUserId,
    'currentStartTime': currentStartTime?.toIso8601String(),
    'cycleMinutes': cycleMinutes,
  };

  factory WashingMachine.fromJson(Map<String, dynamic> json) => WashingMachine(
    id: json['id'],
    location: json['location'],
    status: MachineStatus.values.firstWhere((e) => e.name == json['status']),
    currentUserId: json['currentUserId'],
    currentStartTime: json['currentStartTime'] != null ? DateTime.parse(json['currentStartTime']) : null,
    cycleMinutes: json['cycleMinutes'] ?? 45,
  );
}
