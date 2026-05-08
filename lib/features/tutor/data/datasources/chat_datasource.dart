import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:tutora/core/network/api_client.dart'
    show apiClientProvider, appBaseUrl;
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';

class ChatDatasource {
  ChatDatasource(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  HubConnection? _hub;
  bool _joining = false;

  // REST
  Future<List<ChatChannelDto>> getChannels() async {
    final res = await _dio.get<Map<String, dynamic>>('/chat/channels');
    final body = res.data ?? {};
    final list = (body['content'] as List<dynamic>?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatChannelDto.fromJson)
        .toList();
  }

  Future<List<ChatMessageDto>> getMessages(
    int channelId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/chat/channels/$channelId/messages',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final body = res.data ?? {};
    final list = (body['content'] as List<dynamic>?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageDto.fromJson)
        .toList();
  }

  Future<ChatMessageDto> sendMessage(int channelId, String content) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/channels/$channelId/messages',
      data: {'content': content, 'messageType': 'text'},
    );
    final body = res.data ?? {};
    final c = body['content'] as Map<String, dynamic>? ?? body;
    return ChatMessageDto.fromJson(c);
  }

  Future<void> markRead(int channelId) async {
    await _dio.put<void>('/chat/channels/$channelId/read');
  }

  // JWT helper
  Future<String> getCurrentUserId() async {
    final token = await _storage.getAccessToken();
    if (token == null) return '';
    final parts = token.split('.');
    if (parts.length != 3) return '';
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final map = json.decode(payload) as Map<String, dynamic>;
    return map['userId'] as String? ??
        map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
            as String? ??
        '';
  }

  // SignalR
  Future<HubConnection> _getHub() async {
    if (_hub != null && _hub!.state == HubConnectionState.Connected) {
      return _hub!;
    }

    final token = await _storage.getAccessToken() ?? '';
    _hub = HubConnectionBuilder()
        .withUrl(
          '$appBaseUrl/hubs/chat',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect()
        .build();

    await _hub!.start();
    return _hub!;
  }

  Future<void> joinChannel(int channelId) async {
    if (_joining) return;
    _joining = true;
    try {
      final hub = await _getHub();
      await hub.invoke('JoinChannel', args: [channelId]);
    } finally {
      _joining = false;
    }
  }

  Future<void> leaveChannel(int channelId) async {
    if (_hub == null || _hub!.state != HubConnectionState.Connected) return;
    await _hub!.invoke('LeaveChannel', args: [channelId]);
  }

  Future<void> sendSignalRMessage(int channelId, String content) async {
    final hub = await _getHub();
    await hub.invoke('SendMessage', args: [channelId, content]);
  }

  Future<void> sendTyping(int channelId) async {
    if (_hub == null || _hub!.state != HubConnectionState.Connected) return;
    await _hub!.invoke('Typing', args: [channelId]);
  }

  Future<void> sendStopTyping(int channelId) async {
    if (_hub == null || _hub!.state != HubConnectionState.Connected) return;
    await _hub!.invoke('StopTyping', args: [channelId]);
  }

  void onMessageReceived(void Function(Map<String, dynamic>) handler) {
    _hub?.on('messageReceived', (args) {
      final data = args?.isNotEmpty ?? false ? args![0] : null;
      if (data is Map<String, dynamic>) handler(data);
    });
  }

  void onTyping(void Function(Map<String, dynamic>) handler) {
    _hub?.on('userTyping', (args) {
      final data = args?.isNotEmpty ?? false ? args![0] : null;
      if (data is Map<String, dynamic>) handler(data);
    });
  }

  void onStopTyping(void Function(Map<String, dynamic>) handler) {
    _hub?.on('userStoppedTyping', (args) {
      final data = args?.isNotEmpty ?? false ? args![0] : null;
      if (data is Map<String, dynamic>) handler(data);
    });
  }

  void offAll() {
    _hub?.off('messageReceived');
    _hub?.off('userTyping');
    _hub?.off('userStoppedTyping');
  }

  Future<void> disconnect() async {
    await _hub?.stop();
    _hub = null;
  }
}

final chatDatasourceProvider = Provider<ChatDatasource>((ref) {
  final dio = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return ChatDatasource(dio, storage);
});
