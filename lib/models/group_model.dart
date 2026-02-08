class Group {
  final String id;
  final String name;
  final String code;
  final String ownerId;
  final List<String> memberIds;
  final int totalSeconds; // Using seconds for consistency
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.memberIds,
    this.totalSeconds = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'totalSeconds': totalSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      ownerId: map['ownerId'],
      memberIds: List<String>.from(map['memberIds']),
      totalSeconds: map['totalSeconds'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
