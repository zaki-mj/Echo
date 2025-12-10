class MoodModel {
  final String userId;
  final String mood; // e.g., 'bat', 'moon', 'rose', 'thorns', etc.
  final DateTime timestamp;
  final DateTime? resetAt;

  MoodModel({
    required this.userId,
    required this.mood,
    required this.timestamp,
    this.resetAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mood': mood,
      'timestamp': timestamp.toIso8601String(),
      'resetAt': resetAt?.toIso8601String(),
    };
  }

  factory MoodModel.fromMap(Map<String, dynamic> map) {
    return MoodModel(
      userId: map['userId'] ?? '',
      mood: map['mood'] ?? 'bat',
      timestamp: DateTime.parse(map['timestamp']),
      resetAt: map['resetAt'] != null
          ? DateTime.parse(map['resetAt'])
          : null,
    );
  }
}

