import 'dart:typed_data';

enum ChatRole { user, assistant, system }

ChatRole _roleFromString(String? s) => switch (s) {
  'assistant' => ChatRole.assistant,
  'system' => ChatRole.system,
  _ => ChatRole.user,
};

String roleToString(ChatRole r) => switch (r) {
  ChatRole.assistant => 'assistant',
  ChatRole.system => 'system',
  ChatRole.user => 'user',
};

/// Một phiên giải toán.
class AiChatSession {
  const AiChatSession({
    required this.sessionId,
    required this.sessionType,
    this.title,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AiChatSession.fromJson(Map<String, dynamic> j) => AiChatSession(
    sessionId: j['sessionId'] as String,
    sessionType: j['sessionType'] as String? ?? 'homework',
    title: j['title'] as String?,
    isActive: j['isActive'] as bool? ?? true,
    createdAt: _parseDate(j['createdAt']),
    updatedAt: _parseDate(j['updatedAt']),
  );

  final String sessionId;
  final String sessionType;
  final String? title;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// Một tin nhắn trong phiên.
class AiChatMessage {
  const AiChatMessage({
    required this.messageId,
    required this.role,
    required this.content,
    this.imageUrl,
    this.localImage,
    this.createdAt,
    this.isStreaming = false,
  });

  factory AiChatMessage.fromJson(Map<String, dynamic> j) => AiChatMessage(
    messageId: j['messageId'] as String,
    role: _roleFromString(j['role'] as String?),
    content: j['content'] as String? ?? '',
    imageUrl: j['imageUrl'] as String?,
    createdAt: _parseDate(j['createdAt']),
  );

  final String messageId;
  final ChatRole role;
  final String content;
  final String? imageUrl;

  /// Ảnh vừa chụp (chưa upload)
  final Uint8List? localImage;
  final DateTime? createdAt;

  /// True khi assistant message đang được stream.
  final bool isStreaming;

  bool get isUser => role == ChatRole.user;

  /// Có ảnh để hiển thị.
  bool get hasImage => localImage != null || (imageUrl?.isNotEmpty ?? false);

  AiChatMessage copyWith({String? content, bool? isStreaming}) => AiChatMessage(
    messageId: messageId,
    role: role,
    content: content ?? this.content,
    imageUrl: imageUrl,
    localImage: localImage,
    createdAt: createdAt,
    isStreaming: isStreaming ?? this.isStreaming,
  );
}

DateTime? _parseDate(Object? v) {
  if (v is String) return DateTime.tryParse(v);
  return null;
}
