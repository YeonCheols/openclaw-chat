enum MessageType { user, bot, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isLoading = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      type: _parseType(json['type'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static MessageType _parseType(String? type) {
    switch (type) {
      case 'bot':
      case 'assistant':
        return MessageType.bot;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.user;
    }
  }

  ChatMessage copyWith({bool? isLoading, String? content}) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      type: type,
      createdAt: createdAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
