class SealedLetterModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final DateTime revealAt;
  final bool isRevealed;

  SealedLetterModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.revealAt,
    this.isRevealed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'revealAt': revealAt.toIso8601String(),
      'isRevealed': isRevealed,
    };
  }

  factory SealedLetterModel.fromMap(Map<String, dynamic> map) {
    return SealedLetterModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      revealAt: DateTime.parse(map['revealAt']),
      isRevealed: map['isRevealed'] ?? false,
    );
  }
}

