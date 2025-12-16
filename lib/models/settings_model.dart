import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female }

class SettingsModel {
  final String pairId;
  final String maleUserId; // Male user's Firebase UID
  final String femaleUserId; // Female user's Firebase UID (can be empty initially)
  final String maleNickname;
  final String femaleNickname;
  final DateTime? maleBirthdate;
  final DateTime? femaleBirthdate;
  final DateTime meetingDate;
  final int accentColorIndex; // 0-7 for 8 gothic options
  final bool isDarkMode;
  final Duration sayHiInterval;
  final Duration moodResetInterval;
  final bool touchOfNightEnabled;
  final bool sealedLettersEnabled;
  final DateTime lastUpdated;
  final String? maleFcmToken;
  final String? femaleFcmToken;
  
  // Legacy support - map to new structure
  String get user1Id => maleUserId;
  String get user2Id => femaleUserId;
  String get user1Nickname => maleNickname;
  String get user2Nickname => femaleNickname;
  DateTime? get user1Birthdate => maleBirthdate;
  DateTime? get user2Birthdate => femaleBirthdate;

  SettingsModel({
    required this.pairId,
    required this.maleUserId,
    this.femaleUserId = '',
    required this.maleNickname,
    required this.femaleNickname,
    this.maleBirthdate,
    this.femaleBirthdate,
    required this.meetingDate,
    this.accentColorIndex = 0,
    this.isDarkMode = true,
    this.sayHiInterval = const Duration(hours: 12),
    this.moodResetInterval = const Duration(days: 1),
    this.touchOfNightEnabled = true,
    this.sealedLettersEnabled = true,
    required this.lastUpdated,
    this.maleFcmToken,
    this.femaleFcmToken,
  });

  // Helper method to get partner ID
  String? getPartnerId(String currentUserId) {
    if (currentUserId == maleUserId) return femaleUserId.isEmpty ? null : femaleUserId;
    if (currentUserId == femaleUserId) return maleUserId;
    return null;
  }

  // Helper method to check if user is part of this pair
  bool isUserInPair(String userId) {
    return userId == maleUserId || userId == femaleUserId;
  }
  
  // Get user's gender based on their ID
  Gender? getUserGender(String userId) {
    if (userId == maleUserId) return Gender.male;
    if (userId == femaleUserId) return Gender.female;
    return null;
  }
  
  // Get partner's gender
  Gender? getPartnerGender(String currentUserId) {
    final partnerId = getPartnerId(currentUserId);
    if (partnerId == null) return null;
    return getUserGender(partnerId);
  }

  Map<String, dynamic> toMap() {
    return {
      'pairId': pairId,
      'maleUserId': maleUserId,
      'femaleUserId': femaleUserId,
      'maleNickname': maleNickname,
      'femaleNickname': femaleNickname,
      'maleBirthdate': maleBirthdate?.toIso8601String(),
      'femaleBirthdate': femaleBirthdate?.toIso8601String(),
      'meetingDate': meetingDate.toIso8601String(),
      'accentColorIndex': accentColorIndex,
      'isDarkMode': isDarkMode,
      'sayHiIntervalHours': sayHiInterval.inHours,
      'moodResetIntervalHours': moodResetInterval.inHours,
      'touchOfNightEnabled': touchOfNightEnabled,
      'sealedLettersEnabled': sealedLettersEnabled,
      'lastUpdated': lastUpdated.toIso8601String(),
      'maleFcmToken': maleFcmToken,
      'femaleFcmToken': femaleFcmToken,
      // Legacy support
      'user1Id': maleUserId,
      'user2Id': femaleUserId,
      'user1Nickname': maleNickname,
      'user2Nickname': femaleNickname,
      'user1Birthdate': maleBirthdate?.toIso8601String(),
      'user2Birthdate': femaleBirthdate?.toIso8601String(),
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    // Support both new and legacy formats
    // Safely parse DateTime fields with error handling
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) {
          return DateTime.parse(value);
        } else if (value is DateTime) {
          return value;
        } else if (value is Timestamp) {
          return value.toDate();
        }
      } catch (e) {
        debugPrint('Error parsing DateTime: $value, error: $e');
      }
      return null;
    }
    
    final meetingDateValue = map['meetingDate'];
    final meetingDate = parseDateTime(meetingDateValue) ?? DateTime.now();
    
    final lastUpdatedValue = map['lastUpdated'];
    final lastUpdated = parseDateTime(lastUpdatedValue) ?? DateTime.now();
    
    return SettingsModel(
      pairId: map['pairId'] ?? '',
      maleUserId: map['maleUserId'] ?? map['user1Id'] ?? '',
      femaleUserId: map['femaleUserId'] ?? map['user2Id'] ?? '',
      maleNickname: map['maleNickname'] ?? map['user1Nickname'] ?? '',
      femaleNickname: map['femaleNickname'] ?? map['user2Nickname'] ?? '',
      maleBirthdate: parseDateTime(map['maleBirthdate'] ?? map['user1Birthdate']),
      femaleBirthdate: parseDateTime(map['femaleBirthdate'] ?? map['user2Birthdate']),
      meetingDate: meetingDate,
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
      lastUpdated: lastUpdated,
      maleFcmToken: map['maleFcmToken'],
      femaleFcmToken: map['femaleFcmToken'],
    );
  }

  SettingsModel copyWith({
    String? pairId,
    String? maleUserId,
    String? femaleUserId,
    String? maleNickname,
    String? femaleNickname,
    DateTime? maleBirthdate,
    DateTime? femaleBirthdate,
    DateTime? meetingDate,
    int? accentColorIndex,
    bool? isDarkMode,
    Duration? sayHiInterval,
    Duration? moodResetInterval,
    bool? touchOfNightEnabled,
    bool? sealedLettersEnabled,
    DateTime? lastUpdated,
    String? maleFcmToken,
    String? femaleFcmToken,
  }) {
    return SettingsModel(
      pairId: pairId ?? this.pairId,
      maleUserId: maleUserId ?? this.maleUserId,
      femaleUserId: femaleUserId ?? this.femaleUserId,
      maleNickname: maleNickname ?? this.maleNickname,
      femaleNickname: femaleNickname ?? this.femaleNickname,
      maleBirthdate: maleBirthdate ?? this.maleBirthdate,
      femaleBirthdate: femaleBirthdate ?? this.femaleBirthdate,
      meetingDate: meetingDate ?? this.meetingDate,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      sayHiInterval: sayHiInterval ?? this.sayHiInterval,
      moodResetInterval: moodResetInterval ?? this.moodResetInterval,
      touchOfNightEnabled: touchOfNightEnabled ?? this.touchOfNightEnabled,
      sealedLettersEnabled: sealedLettersEnabled ?? this.sealedLettersEnabled,
      lastUpdated: lastUpdated ?? DateTime.now(),
      maleFcmToken: maleFcmToken ?? this.maleFcmToken,
      femaleFcmToken: femaleFcmToken ?? this.femaleFcmToken,
    );
  }
}
