class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => !isUser;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
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
    );
  }

  Message copyWith({
    String? id,
    String? role,
    String? text,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
