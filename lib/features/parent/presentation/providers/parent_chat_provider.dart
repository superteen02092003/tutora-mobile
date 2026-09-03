import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/chat_datasource.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';

// Channel list
class ParentChannelListState {
  const ParentChannelListState({
    this.channels = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ChatChannelDto> channels;
  final bool isLoading;
  final String? error;

  ParentChannelListState copyWith({
    List<ChatChannelDto>? channels,
    bool? isLoading,
    String? error,
  }) => ParentChannelListState(
    channels: channels ?? this.channels,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ParentChannelListNotifier extends StateNotifier<ParentChannelListState> {
  ParentChannelListNotifier(this._ds) : super(const ParentChannelListState()) {
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

  /// Xoá cuộc trò chuyện khỏi danh sách của mình. Bỏ khỏi list ngay cho mượt,
  /// trả lại chỗ cũ nếu BE từ chối — tuyệt đối không báo "đã xoá" khi chưa xoá.
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

  void updateLastMessage(int channelId, String preview) {
    final updated = state.channels.map((c) {
      if (c.channelId != channelId) return c;
      return ChatChannelDto(
        channelId: c.channelId,
        bookingId: c.bookingId,
        otherUserId: c.otherUserId,
        otherUserName: c.otherUserName,
        otherUserAvatarUrl: c.otherUserAvatarUrl,
        status: c.status,
        lastMessageAt: DateTime.now().toUtc().toIso8601String(),
        lastMessagePreview: preview,
      );
    }).toList()..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    state = state.copyWith(channels: updated);
  }
}

final parentChannelListProvider =
    StateNotifierProvider<ParentChannelListNotifier, ParentChannelListState>((
      ref,
    ) {
      return ParentChannelListNotifier(ref.watch(chatDatasourceProvider));
    });

// Chat room
class ParentChatRoomState {
  const ParentChatRoomState({
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

  ParentChatRoomState copyWith({
    List<ChatMessageDto>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isTyping,
    String? currentUserId,
    String? error,
  }) => ParentChatRoomState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    isTyping: isTyping ?? this.isTyping,
    currentUserId: currentUserId ?? this.currentUserId,
    error: error,
  );
}

class ParentChatRoomNotifier extends StateNotifier<ParentChatRoomState> {
  ParentChatRoomNotifier(this._ds, this._channelId, this._onNewMessage)
    : super(const ParentChatRoomState()) {
    unawaited(_init());
  }

  final ChatDatasource _ds;
  final int _channelId;
  final void Function(int channelId, String preview) _onNewMessage;
  Timer? _typingTimer;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = await _ds.getCurrentUserId();
      final messages = await _ds.getMessages(_channelId);
      await _ds.markRead(_channelId);
      await _ds.joinChannel(_channelId);

      _ds
        ..onMessageReceived((data) {
          final msg = ChatMessageDto.fromJson(data);
          if (!mounted) return;
          state = state.copyWith(messages: [...state.messages, msg]);
          _onNewMessage(_channelId, msg.content);
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

final StateNotifierProviderFamily<
  ParentChatRoomNotifier,
  ParentChatRoomState,
  int
>
parentChatRoomProvider =
    StateNotifierProvider.family<
      ParentChatRoomNotifier,
      ParentChatRoomState,
      int
    >((ref, channelId) {
      final ds = ref.watch(chatDatasourceProvider);
      final channelListNotifier = ref.read(parentChannelListProvider.notifier);
      return ParentChatRoomNotifier(
        ds,
        channelId,
        channelListNotifier.updateLastMessage,
      );
    });
