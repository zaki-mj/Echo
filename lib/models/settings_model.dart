class SettingsModel {
  final String pairId;
  final String user1Id; // First user's Firebase UID
  final String user2Id; // Second user's Firebase UID (can be empty initially)
  final String user1Nickname;
  final String user2Nickname;
  final DateTime? user1Birthdate;
  final DateTime? user2Birthdate;
  final DateTime meetingDate;
  final int accentColorIndex; // 0-7 for 8 gothic options
  final bool isDarkMode;
  final Duration sayHiInterval;
  final Duration moodResetInterval;
  final bool touchOfNightEnabled;
  final bool sealedLettersEnabled;
  final DateTime lastUpdated;

  SettingsModel({
    required this.pairId,
    required this.user1Id,
    this.user2Id = '',
    required this.user1Nickname,
    required this.user2Nickname,
    this.user1Birthdate,
    this.user2Birthdate,
    required this.meetingDate,
    this.accentColorIndex = 0,
    this.isDarkMode = true,
    this.sayHiInterval = const Duration(hours: 12),
    this.moodResetInterval = const Duration(days: 1),
    this.touchOfNightEnabled = true,
    this.sealedLettersEnabled = true,
    required this.lastUpdated,
  });

  // Helper method to get partner ID
  String? getPartnerId(String currentUserId) {
    if (currentUserId == user1Id) return user2Id.isEmpty ? null : user2Id;
    if (currentUserId == user2Id) return user1Id;
    return null;
  }

  // Helper method to check if user is part of this pair
  bool isUserInPair(String userId) {
    return userId == user1Id || userId == user2Id;
  }

  Map<String, dynamic> toMap() {
    return {
      'pairId': pairId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Nickname': user1Nickname,
      'user2Nickname': user2Nickname,
      'user1Birthdate': user1Birthdate?.toIso8601String(),
      'user2Birthdate': user2Birthdate?.toIso8601String(),
      'meetingDate': meetingDate.toIso8601String(),
      'accentColorIndex': accentColorIndex,
      'isDarkMode': isDarkMode,
      'sayHiIntervalHours': sayHiInterval.inHours,
      'moodResetIntervalHours': moodResetInterval.inHours,
      'touchOfNightEnabled': touchOfNightEnabled,
      'sealedLettersEnabled': sealedLettersEnabled,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      pairId: map['pairId'] ?? '',
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      user1Nickname: map['user1Nickname'] ?? '',
      user2Nickname: map['user2Nickname'] ?? '',
      user1Birthdate: map['user1Birthdate'] != null
          ? DateTime.parse(map['user1Birthdate'])
          : null,
      user2Birthdate: map['user2Birthdate'] != null
          ? DateTime.parse(map['user2Birthdate'])
          : null,
      meetingDate: DateTime.parse(map['meetingDate']),
      accentColorIndex: map['accentColorIndex'] ?? 0,
      isDarkMode: map['isDarkMode'] ?? true,
      sayHiInterval: Duration(
        hours: map['sayHiIntervalHours'] ?? 12,
      ),
      moodResetInterval: Duration(
        hours: map['moodResetIntervalHours'] ?? 24,
      ),
      touchOfNightEnabled: map['touchOfNightEnabled'] ?? true,
      sealedLettersEnabled: map['sealedLettersEnabled'] ?? true,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  SettingsModel copyWith({
    String? pairId,
    String? user1Id,
    String? user2Id,
    String? user1Nickname,
    String? user2Nickname,
    DateTime? user1Birthdate,
    DateTime? user2Birthdate,
    DateTime? meetingDate,
    int? accentColorIndex,
    bool? isDarkMode,
    Duration? sayHiInterval,
    Duration? moodResetInterval,
    bool? touchOfNightEnabled,
    bool? sealedLettersEnabled,
    DateTime? lastUpdated,
  }) {
    return SettingsModel(
      pairId: pairId ?? this.pairId,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      user1Nickname: user1Nickname ?? this.user1Nickname,
      user2Nickname: user2Nickname ?? this.user2Nickname,
      user1Birthdate: user1Birthdate ?? this.user1Birthdate,
      user2Birthdate: user2Birthdate ?? this.user2Birthdate,
      meetingDate: meetingDate ?? this.meetingDate,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      sayHiInterval: sayHiInterval ?? this.sayHiInterval,
      moodResetInterval: moodResetInterval ?? this.moodResetInterval,
      touchOfNightEnabled: touchOfNightEnabled ?? this.touchOfNightEnabled,
      sealedLettersEnabled: sealedLettersEnabled ?? this.sealedLettersEnabled,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

