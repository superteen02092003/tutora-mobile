import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/shared/live_session/live_session_datasource.dart';
import 'package:tutora/shared/live_session/live_session_identity.dart';
import 'package:tutora/shared/live_session/live_session_models.dart';

/// Màn video buổi học trực tiếp (Agora RTC) — dùng chung, role-agnostic.
///
/// Tự lo toàn bộ vòng đời lease: join → gia hạn token 120s → heartbeat 20s →
/// leave. Xử lý xung đột thiết bị (takeover) và phòng bị đóng / chặn thanh toán.
class LiveSessionCallScreen extends ConsumerStatefulWidget {
  const LiveSessionCallScreen({
    required this.classSessionId,
    this.tutorName,
    super.key,
  });

  final int classSessionId;
  final String? tutorName;

  @override
  ConsumerState<LiveSessionCallScreen> createState() =>
      _LiveSessionCallScreenState();
}

enum _Phase { connecting, joined, error, closed }

class _LiveSessionCallScreenState extends ConsumerState<LiveSessionCallScreen> {
  RtcEngine? _engine;
  LiveSessionRoom? _room;

  _Phase _phase = _Phase.connecting;
  String? _error;
  bool _muted = false;
  bool _camOff = false;
  int? _remoteUid;
  bool _leaving = false;

  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    unawaited(_teardown());
    super.dispose();
  }

  LiveSessionDatasource get _ds => ref.read(liveSessionDatasourceProvider);

  Future<void> _start() async {
    final granted = await _ensurePermissions();
    if (!granted) {
      _fail('Cần quyền micro và camera để vào phòng học.');
      return;
    }
    await _joinAndConnect(takeover: null);
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  /// Gọi join (hoặc takeover), khởi tạo engine nếu chưa có, rồi vào kênh.
  Future<void> _joinAndConnect({required String? takeover}) async {
    try {
      final identity = await ref
          .read(liveSessionIdentityFactoryProvider)
          .build();
      final room = takeover == null
          ? await _ds.join(widget.classSessionId, identity)
          : await _ds.takeover(widget.classSessionId, identity, takeover);

      if (!room.isValid) {
        _fail('Phòng học chưa sẵn sàng, vui lòng thử lại.');
        return;
      }
      if (!mounted) return;
      _room = room;
      await _ensureEngine(room.appId);
      await _joinChannel(room);
      _startHeartbeat();
    } on SessionActiveOnAnotherDeviceException catch (e) {
      if (!mounted) return;
      await _promptTakeover(e.conflict);
    } on SessionLeaseRevokedException {
      _fail('Phiên học đã được mở trên thiết bị khác.');
    } on LiveSessionException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Không vào được phòng học: $e');
    }
  }

  Future<void> _ensureEngine(String appId) async {
    if (_engine != null) return;
    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _phase = _Phase.joined);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) setState(() => _remoteUid = null);
        },
        // Token sắp hết hạn (TTL ~120s): join lại để lấy token mới rồi renew.
        onTokenPrivilegeWillExpire: (connection, token) {
          unawaited(_renewToken());
        },
        onError: (err, msg) {
          if (mounted && _phase != _Phase.joined) {
            setState(() {
              _phase = _Phase.error;
              _error = 'Lỗi kết nối: $msg';
            });
          }
        },
      ),
    );
    await engine.enableVideo();
    await engine.startPreview();
    _engine = engine;
  }

  Future<void> _joinChannel(LiveSessionRoom room) async {
    await _engine?.joinChannelWithUserAccount(
      token: room.token,
      channelId: room.channel,
      userAccount: room.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  /// Lấy token mới bằng cách join lại lease (idempotent) rồi renewToken.
  Future<void> _renewToken() async {
    try {
      final identity = await ref
          .read(liveSessionIdentityFactoryProvider)
          .build();
      final refreshed = await _ds.join(widget.classSessionId, identity);
      if (!mounted || !refreshed.isValid) return;
      _room = refreshed;
      await _engine?.renewToken(refreshed.token);
    } catch (_) {
      // Nếu gia hạn thất bại, heartbeat/roomClosed sẽ xử lý việc rời phòng.
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_beat()),
    );
  }

  Future<void> _beat() async {
    final room = _room;
    if (room == null) return;
    try {
      final presence = await _ds.heartbeat(widget.classSessionId, room);
      if (!mounted) return;
      if (presence.roomClosed) {
        _closeRoom('Buổi học đã kết thúc.');
      } else if (presence.blockedByPayment) {
        _closeRoom(
          'Phòng học tạm khóa do chưa thanh toán các buổi còn lại.',
        );
      }
    } catch (_) {
      // Bỏ qua lỗi heartbeat lẻ — nhịp sau sẽ thử lại.
    }
  }

  Future<void> _promptTakeover(ActiveSessionConflict conflict) async {
    final label = conflict.activeDeviceLabel;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(
          'Đang mở trên thiết bị khác',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          label != null && label.isNotEmpty
              ? 'Phiên học đang mở trên "$label". Chuyển sang thiết bị này?'
              : 'Phiên học đang mở trên một thiết bị khác. Chuyển sang thiết bị này?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.oxblood),
            child: const Text('Chuyển sang đây'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed ?? false) {
      setState(() => _phase = _Phase.connecting);
      await _joinAndConnect(takeover: conflict.activeLeaseId);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _error = message;
    });
  }

  void _closeRoom(String message) {
    if (!mounted || _phase == _Phase.closed) return;
    _heartbeatTimer?.cancel();
    setState(() {
      _phase = _Phase.closed;
      _error = message;
    });
    unawaited(_teardown());
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    await _engine?.muteLocalAudioStream(next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _toggleCam() async {
    final next = !_camOff;
    await _engine?.muteLocalVideoStream(next);
    if (mounted) setState(() => _camOff = next);
  }

  Future<void> _switchCamera() async => _engine?.switchCamera();

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _teardown();
    if (mounted) Navigator.of(context).pop();
  }

  /// Rời kênh + báo backend leave + release engine. An toàn gọi nhiều lần.
  Future<void> _teardown() async {
    _heartbeatTimer?.cancel();
    final room = _room;
    if (room != null) {
      await _ds.leave(widget.classSessionId, room);
    }
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    _room = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildStage(),
          _buildLocalPreview(),
          _buildTopBar(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildStage() {
    if (_phase == _Phase.error || _phase == _Phase.closed) {
      return _MessageStage(
        icon: _phase == _Phase.closed
            ? Icons.event_available_rounded
            : Icons.videocam_off_rounded,
        message: _error ?? 'Đã có lỗi xảy ra.',
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
      );
    }

    final engine = _engine;
    if (engine != null && _remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _room?.channel),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white24),
          const SizedBox(height: 20),
          Text(
            _phase == _Phase.joined
                ? 'Đang chờ ${widget.tutorName ?? 'gia sư'} vào phòng…'
                : 'Đang kết nối…',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPreview() {
    final engine = _engine;
    if (engine == null || _phase != _Phase.joined || _camOff) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 56,
      right: 16,
      width: 108,
      height: 156,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    if (_phase == _Phase.error || _phase == _Phase.closed) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 12,
      left: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _phase == _Phase.joined
                      ? const Color(0xFF34D399)
                      : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.tutorName ?? _room?.tutorName ?? 'Phòng học',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_phase == _Phase.error || _phase == _Phase.closed) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleBtn(
                icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                bg: _muted ? Colors.white : Colors.white24,
                fg: _muted ? Colors.black : Colors.white,
                onTap: _toggleMute,
              ),
              const SizedBox(width: 16),
              _CircleBtn(
                icon: _camOff
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                bg: _camOff ? Colors.white : Colors.white24,
                fg: _camOff ? Colors.black : Colors.white,
                onTap: _toggleCam,
              ),
              const SizedBox(width: 16),
              _CircleBtn(
                icon: Icons.cameraswitch_rounded,
                bg: Colors.white24,
                fg: Colors.white,
                onTap: _switchCamera,
              ),
              const SizedBox(width: 16),
              _CircleBtn(
                icon: Icons.call_end_rounded,
                bg: AppColors.oxblood,
                fg: Colors.white,
                onTap: _leave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageStage extends StatelessWidget {
  const _MessageStage({
    required this.icon,
    required this.message,
    required this.showBack,
    required this.onBack,
  });
  final IconData icon;
  final String message;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            if (showBack) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Quay lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: 24),
      ),
    );
  }
}
