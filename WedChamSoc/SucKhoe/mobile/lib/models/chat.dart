enum MessageType { user, assistant }

MessageType messageTypeFromString(String value) {
  switch (value) {
    case 'user':
      return MessageType.user;
    case 'assistant':
      return MessageType.assistant;
    default:
      return MessageType.user;
  }
}

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.user:
      return 'user';
    case MessageType.assistant:
      return 'assistant';
  }
}

class ChatMessageModel {
  final int id;
  final int sessionId;
  final MessageType messageType;
  final String content;
  final String timestamp;

  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.messageType,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        id: json['id'] as int,
        sessionId: json['session_id'] as int,
        messageType: messageTypeFromString(json['message_type'] as String? ?? ''),
        content: json['content'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'message_type': messageTypeToString(messageType),
        'content': content,
        'timestamp': timestamp,
      };
}

class ChatSessionModel {
  final int id;
  final int userId;
  final String sessionId;
  final String startedAt;
  final String? endedAt;
  final bool isActive;
  final List<ChatMessageModel>? messages;

  const ChatSessionModel({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
    this.messages,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) => ChatSessionModel(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        sessionId: json['session_id'] as String? ?? '',
        startedAt: json['started_at'] as String? ?? '',
        endedAt: json['ended_at'] as String?,
        isActive: json['is_active'] as bool? ?? false,
        messages: (json['messages'] as List?)
            ?.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'session_id': sessionId,
        'started_at': startedAt,
        'ended_at': endedAt,
        'is_active': isActive,
        'messages': messages?.map((e) => e.toJson()).toList(),
      };
}

class ChatResponseModel {
  final ChatMessageModel message;
  final ChatSessionModel session;

  const ChatResponseModel({required this.message, required this.session});

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) => ChatResponseModel(
        message: ChatMessageModel.fromJson(json['message'] as Map<String, dynamic>),
        session: ChatSessionModel.fromJson(json['session'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'message': message.toJson(),
        'session': session.toJson(),
      };
}


