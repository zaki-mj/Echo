class UserModel {
  final String id;
  final String nickname;
  final DateTime? birthdate;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.nickname,
    this.birthdate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'birthdate': birthdate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      nickname: map['nickname'] ?? '',
      birthdate: map['birthdate'] != null
          ? DateTime.parse(map['birthdate'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

