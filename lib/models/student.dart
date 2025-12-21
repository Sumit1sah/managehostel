class Student {
  final String id;
  final String name;
  final String roomNumber;
  final String hostelBlock;

  Student({
    required this.id,
    required this.name,
    required this.roomNumber,
    required this.hostelBlock,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'roomNumber': roomNumber,
    'hostelBlock': hostelBlock,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'],
    name: json['name'],
    roomNumber: json['roomNumber'],
    hostelBlock: json['hostelBlock'],
  );
}
