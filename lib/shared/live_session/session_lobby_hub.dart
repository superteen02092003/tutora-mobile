import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/shared/live_session/session_lobby_models.dart';

/// Kết nối hub `session-lobby` — trạng thái chờ 2 bên + đổi lịch nhanh.
class SessionLobbyHub {
  SessionLobbyHub(this._storage);

  final SecureStorageService _storage;
  HubConnection? _hub;

  void Function(LobbyInfo)? onInfo;
  void Function(LobbyWaitingState)? onWaiting;
  void Function(ScheduleChangeState)? onScheduleChange;
  void Function(SessionScheduleConflict?)? onConflict;
  void Function()? onReady;
  void Function(String reason)? onClosed;
  void Function()? onBlocked;
  void Function()? onReconnecting;

  Map<String, dynamic>? _arg(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final a = args.first;
    return a is Map ? Map<String, dynamic>.from(a) : null;
  }

  Future<void> connect(int classSessionId) async {
    final hub = HubConnectionBuilder()
        .withUrl(
          '$appBaseUrl/hubs/session-lobby',
          options: HttpConnectionOptions(
            // Đọc lại token mỗi lần kết nối — xem chú thích ở chat hub.
            accessTokenFactory: () async =>
                await _storage.getAccessToken() ?? '',
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect()
        .build();
    _hub = hub;

    hub
      ..on('lobbyInfo', (a) {
        final m = _arg(a);
        if (m != null) onInfo?.call(LobbyInfo.fromJson(m));
      })
      ..on('lobbyState', (a) {
        final m = _arg(a);
        if (m != null) onWaiting?.call(LobbyWaitingState.fromJson(m));
      })
      ..on('scheduleChangeState', (a) {
        final m = _arg(a);
        if (m != null) onScheduleChange?.call(ScheduleChangeState.fromJson(m));
      })
      ..on('scheduleConflict', (a) {
        final m = _arg(a);
        if (m != null) onConflict?.call(SessionScheduleConflict.fromJson(m));
      })
      ..on('scheduleConflictCleared', (_) => onConflict?.call(null))
      ..on('sessionReady', (_) => onReady?.call())
      ..on('lobbyClosed', (a) {
        onClosed?.call(_arg(a)?['reason'] as String? ?? '');
      })
      ..on('lobbyBlocked', (_) => onBlocked?.call())
      ..onreconnecting(({error}) => onReconnecting?.call());

    await hub.start();
    await hub.invoke('JoinLobby', args: [classSessionId]);
  }

  Future<void> respondToScheduleChange(
    int classSessionId, {
    required bool confirmed,
  }) async {
    await _hub?.invoke(
      'RespondToScheduleChange',
      args: [classSessionId, confirmed],
    );
  }

  Future<void> refresh() async {
    try {
      await _hub?.invoke('RefreshState');
    } catch (_) {
      // Hub chưa sẵn sàng — bỏ qua, event sẽ tự đến khi nối lại.
    }
  }

  Future<void> dispose() async {
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      await hub.invoke('LeaveLobby');
    } catch (_) {
      // Đang rớt kết nối thì server tự dọn.
    }
    await hub.stop();
  }
}

final sessionLobbyHubProvider = Provider<SessionLobbyHub>(
  (ref) => SessionLobbyHub(ref.read(secureStorageProvider)),
);
