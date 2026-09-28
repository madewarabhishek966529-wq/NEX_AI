class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;
  final String? imageBase64;

  const Message({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.imageBase64,
  });

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => !isUser;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'image_base64': ?imageBase64,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id']?.toString() ?? map['message_id']?.toString() ?? '',
      role: map['role']?.toString() ?? 'assistant',
      text: map['text']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      imageBase64: map['image_base64']?.toString(),
    );
  }

  Message copyWith({
    String? id,
    String? role,
    String? text,
    DateTime? timestamp,
    String? imageBase64,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
