import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/chat_datasource.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';

// Channel list

class ChannelListState {
  const ChannelListState({
    this.channels = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ChatChannelDto> channels;
  final bool isLoading;
  final String? error;

  ChannelListState copyWith({
    List<ChatChannelDto>? channels,
    bool? isLoading,
    String? error,
  }) => ChannelListState(
    channels: channels ?? this.channels,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ChannelListNotifier extends StateNotifier<ChannelListState> {
  ChannelListNotifier(this._ds) : super(const ChannelListState()) {
    unawaited(load());
  }

  final ChatDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final channels = await _ds.getChannels();
      state = state.copyWith(channels: channels, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Xoá cuộc trò chuyện khỏi danh sách của mình.
  Future<void> deleteChannel(int channelId) async {
    final previous = state.channels;
    state = state.copyWith(
      channels: previous.where((c) => c.channelId != channelId).toList(),
    );
    try {
      await _ds.deleteChannel(channelId);
    } catch (e) {
      state = state.copyWith(channels: previous);
      rethrow;
    }
  }

  /// Cập nhật dòng xem trước khi có tin mới.
  void updateLastMessage(
    int channelId,
    String preview, {
    bool incrementUnread = false,
  }) {
    final updated = state.channels.map((c) {
      if (c.channelId != channelId) return c;
      return c.copyWith(
        lastMessageAt: DateTime.now().toUtc().toIso8601String(),
        lastMessagePreview: preview,
        unreadCount: incrementUnread ? c.unreadCount + 1 : c.unreadCount,
      );
    }).toList()..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    state = state.copyWith(channels: updated);
  }

  /// Đánh dấu đã đọc tại chỗ sau khi mở kênh
  void markChannelRead(int channelId) {
    final updated = state.channels
        .map(
          (c) => c.channelId == channelId ? c.copyWith(unreadCount: 0) : c,
        )
        .toList();
    state = state.copyWith(channels: updated);
  }
}

final channelListProvider =
    StateNotifierProvider<ChannelListNotifier, ChannelListState>((ref) {
      return ChannelListNotifier(ref.watch(chatDatasourceProvider));
    });

/// Tổng tin nhắn chưa đọc
final Provider<int> chatUnreadTotalProvider = Provider<int>((ref) {
  final channels = ref.watch(channelListProvider).channels;
  return channels.fold<int>(0, (sum, c) => sum + c.unreadCount);
});

// Chat room

class ChatRoomState {
  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isTyping = false,
    this.currentUserId = '',
    this.error,
  });

  final List<ChatMessageDto> messages;
  final bool isLoading;
  final bool isSending;
  final bool isTyping;
  final String currentUserId;
  final String? error;

  ChatRoomState copyWith({
    List<ChatMessageDto>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isTyping,
    String? currentUserId,
    String? error,
  }) => ChatRoomState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    isTyping: isTyping ?? this.isTyping,
    currentUserId: currentUserId ?? this.currentUserId,
    error: error,
  );
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  ChatRoomNotifier(
    this._ds,
    this._channelId,
    this._onNewMessage,
    this._onRead,
  ) : super(const ChatRoomState()) {
    unawaited(_init());
  }

  final ChatDatasource _ds;
  final int _channelId;
  final void Function(int channelId, String preview) _onNewMessage;

  /// Gọi sau khi đánh dấu đã đọc để badge tụt ngay, không đợi tải lại.
  final void Function(int channelId) _onRead;
  Timer? _typingTimer;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = await _ds.getCurrentUserId();
      final messages = await _ds.getMessages(_channelId);
      await _ds.markRead(_channelId);
      _onRead(_channelId);
      await _ds.joinChannel(_channelId);

      _ds
        ..onMessageReceived((data) {
          final msg = ChatMessageDto.fromJson(data);
          if (!mounted) return;
          state = state.copyWith(messages: [...state.messages, msg]);
          // Đang mở đúng phòng này nên tin coi như đã đọc — chỉ đổi dòng xem
          // trước, không cộng số chưa đọc.
          _onNewMessage(_channelId, msg.content);
          unawaited(_ds.markRead(_channelId));
        })
        ..onTyping((_) {
          if (mounted) state = state.copyWith(isTyping: true);
        })
        ..onStopTyping((_) {
          if (mounted) state = state.copyWith(isTyping: false);
        });

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        currentUserId: userId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> send(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    state = state.copyWith(isSending: true);
    try {
      // Try SignalR first, fall back to REST
      try {
        await _ds.sendSignalRMessage(_channelId, text);
      } catch (_) {
        final msg = await _ds.sendMessage(_channelId, text);
        if (mounted) {
          state = state.copyWith(messages: [...state.messages, msg]);
          _onNewMessage(_channelId, msg.content);
        }
      }
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    } finally {
      if (mounted) state = state.copyWith(isSending: false);
    }
  }

  void notifyTyping() {
    unawaited(_ds.sendTyping(_channelId));
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      unawaited(_ds.sendStopTyping(_channelId));
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    unawaited(_ds.leaveChannel(_channelId));
    _ds.offAll();
    super.dispose();
  }
}

// Family provider keyed by channelId
final StateNotifierProviderFamily<ChatRoomNotifier, ChatRoomState, int>
chatRoomProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, int>(
      (ref, channelId) {
        final ds = ref.watch(chatDatasourceProvider);
        final channelListNotifier = ref.read(channelListProvider.notifier);
        return ChatRoomNotifier(
          ds,
          channelId,
          channelListNotifier.updateLastMessage,
          channelListNotifier.markChannelRead,
        );
      },
    );
