enum CleaningStatus { pending, inProgress, completed, verified }

class RoomCleaning {
  final String id;
  final String roomNumber;
  final String floor;
  final String studentId;
  CleaningStatus status;
  final DateTime scheduledDate;
  DateTime? completedAt;
  String? verifiedBy;
  String? remarks;
  bool bathroomClean;
  bool roomClean;
  bool toiletClean;

  RoomCleaning({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.studentId,
    this.status = CleaningStatus.pending,
    required this.scheduledDate,
    this.completedAt,
    this.verifiedBy,
    this.remarks,
    this.bathroomClean = false,
    this.roomClean = false,
    this.toiletClean = false,
  });

  bool get isFullyClean => roomClean && (bathroomClean || toiletClean);

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomNumber': roomNumber,
    'floor': floor,
    'studentId': studentId,
    'status': status.name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'verifiedBy': verifiedBy,
    'remarks': remarks,
    'bathroomClean': bathroomClean,
    'roomClean': roomClean,
    'toiletClean': toiletClean,
  };

  factory RoomCleaning.fromJson(Map<String, dynamic> json) => RoomCleaning(
    id: json['id'],
    roomNumber: json['roomNumber'],
    floor: json['floor'],
    studentId: json['studentId'],
    status: CleaningStatus.values.firstWhere((e) => e.name == json['status']),
    scheduledDate: DateTime.parse(json['scheduledDate']),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    verifiedBy: json['verifiedBy'],
    remarks: json['remarks'],
    bathroomClean: json['bathroomClean'] ?? false,
    roomClean: json['roomClean'] ?? false,
    toiletClean: json['toiletClean'] ?? false,
  );
}
