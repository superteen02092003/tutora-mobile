class ChatChannelDto {
  const ChatChannelDto({
    required this.channelId,
    required this.bookingId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    required this.status,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    this.unreadCount = 0,
  });

  factory ChatChannelDto.fromJson(Map<String, dynamic> j) => ChatChannelDto(
    channelId: j['channelId'] as int? ?? 0,
    bookingId: j['bookingId'] as int? ?? 0,
    otherUserId: j['otherUserId'] as String? ?? '',
    otherUserName: j['otherUserName'] as String? ?? 'Người dùng',
    otherUserAvatarUrl: j['otherUserAvatarUrl'] as String? ?? '',
    status: j['status'] as String? ?? '',
    lastMessageAt: j['lastMessageAt'] as String? ?? '',
    lastMessagePreview: j['lastMessagePreview'] as String? ?? '',
    unreadCount: j['unreadCount'] as int? ?? 0,
  );

  final int channelId;
  final int bookingId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatarUrl;
  final String status;
  final String lastMessageAt;
  final String lastMessagePreview;

  /// Tin nhắn chưa đọc của riêng kênh này.
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  ChatChannelDto copyWith({
    String? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
  }) => ChatChannelDto(
    channelId: channelId,
    bookingId: bookingId,
    otherUserId: otherUserId,
    otherUserName: otherUserName,
    otherUserAvatarUrl: otherUserAvatarUrl,
    status: status,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  String get displayPreview {
    final p = lastMessagePreview;
    if (p.isEmpty) return 'Chưa có tin nhắn';
    if (p.startsWith('http') &&
        (p.contains('supabase.co/storage') ||
            RegExp(
              r'\.(jpeg|jpg|gif|png)$',
              caseSensitive: false,
            ).hasMatch(p))) {
      return '[Hình ảnh]';
    }
    return p;
  }

  String get formattedTime {
    if (lastMessageAt.isEmpty) return '';
    final safe = lastMessageAt.contains('Z') || lastMessageAt.contains('+')
        ? lastMessageAt
        : '${lastMessageAt}Z';
    final dt = DateTime.tryParse(safe)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dt.day}/${dt.month}';
  }
}

class ChatMessageDto {
  const ChatMessageDto({
    required this.messageId,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> j) => ChatMessageDto(
    messageId: j['messageId'] as int? ?? 0,
    channelId: j['channelId'] as int? ?? 0,
    senderId: j['senderId'] as String? ?? '',
    senderName: j['senderName'] as String? ?? '',
    content: j['content'] as String? ?? '',
    messageType: j['messageType'] as String? ?? 'text',
    createdAt: j['createdAt'] as String? ?? '',
    isRead: j['isRead'] as bool? ?? false,
  );

  final int messageId;
  final int channelId;
  final String senderId;
  final String senderName;
  final String content;
  final String messageType;
  final String createdAt;
  final bool isRead;

  bool get isImage =>
      messageType == 'image' ||
      (content.startsWith('http') &&
          RegExp(
            r'\.(jpeg|jpg|gif|png)$',
            caseSensitive: false,
          ).hasMatch(content));

  String get formattedTime {
    if (createdAt.isEmpty) return '';
    final safe = createdAt.contains('Z') || createdAt.contains('+')
        ? createdAt
        : '${createdAt}Z';
    final dt = DateTime.tryParse(safe)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
