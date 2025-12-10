class WhisperModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? voiceUrl;
  final DateTime timestamp;
  final bool isDelivered;
  final bool isRead;

  WhisperModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.voiceUrl,
    required this.timestamp,
    this.isDelivered = false,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'voiceUrl': voiceUrl,
      'timestamp': timestamp.toIso8601String(),
      'isDelivered': isDelivered,
      'isRead': isRead,
    };
  }

  factory WhisperModel.fromMap(Map<String, dynamic> map) {
    return WhisperModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      voiceUrl: map['voiceUrl'],
      timestamp: DateTime.parse(map['timestamp']),
      isDelivered: map['isDelivered'] ?? false,
      isRead: map['isRead'] ?? false,
    );
  }
}

