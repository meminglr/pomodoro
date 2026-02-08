class UserStats {
  final String userId;
  final String username; // Display name
  final int weeklyFocusSeconds;
  final int monthlyFocusSeconds;
  final int totalFocusSeconds;
  final DateTime lastUpdated;

  UserStats({
    required this.userId,
    required this.username,
    this.weeklyFocusSeconds = 0,
    this.monthlyFocusSeconds = 0,
    this.totalFocusSeconds = 0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'weeklyFocusSeconds': weeklyFocusSeconds,
      'monthlyFocusSeconds': monthlyFocusSeconds,
      'totalFocusSeconds': totalFocusSeconds,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      userId: map['userId'],
      username: map['username'],
      weeklyFocusSeconds: map['weeklyFocusSeconds'] ?? 0,
      monthlyFocusSeconds: map['monthlyFocusSeconds'] ?? 0,
      totalFocusSeconds: map['totalFocusSeconds'] ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  UserStats copyWith({
    String? username,
    int? weeklyFocusSeconds,
    int? monthlyFocusSeconds,
    int? totalFocusSeconds,
    DateTime? lastUpdated,
  }) {
    return UserStats(
      userId: userId,
      username: username ?? this.username,
      weeklyFocusSeconds: weeklyFocusSeconds ?? this.weeklyFocusSeconds,
      monthlyFocusSeconds: monthlyFocusSeconds ?? this.monthlyFocusSeconds,
      totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
