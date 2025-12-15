class PokeModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final DateTime timestamp;
  final bool isHandled;

  PokeModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.timestamp,
    this.isHandled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'isHandled': isHandled,
    };
  }

  factory PokeModel.fromMap(Map<String, dynamic> map) {
    return PokeModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isHandled: map['isHandled'] ?? false,
    );
  }
}


