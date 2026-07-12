import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/data/models/agora_room_models.dart';

/// Live video-call screen for a class session, backed by Agora RTC.
class AgoraCallScreen extends StatefulWidget {
  const AgoraCallScreen({required this.room, this.tutorName, super.key});

  final AgoraRoomDto room;
  final String? tutorName;

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState extends State<AgoraCallScreen> {
  RtcEngine? _engine;
  bool _joined = false;
  bool _muted = false;
  bool _camOff = false;
  int? _remoteUid;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    // Mic + camera permission are required before joining.
    final statuses = await [Permission.microphone, Permission.camera].request();
    final granted = statuses.values.every((s) => s.isGranted);
    if (!granted) {
      if (mounted) {
        setState(() => _error = 'Cần quyền micro và camera để vào phòng học.');
      }
      return;
    }

    try {
      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: widget.room.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (mounted) setState(() => _joined = true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (mounted) setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (mounted) setState(() => _remoteUid = null);
          },
          onError: (err, msg) {
            if (mounted) setState(() => _error = 'Lỗi kết nối: $msg');
          },
        ),
      );

      await engine.enableVideo();
      await engine.startPreview();

      await engine.joinChannelWithUserAccount(
        token: widget.room.token,
        channelId: widget.room.channel,
        userAccount: widget.room.uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine = engine;
    } catch (e) {
      if (mounted) setState(() => _error = 'Không khởi tạo được cuộc gọi: $e');
    }
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

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> _leave() async {
    await _engine?.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    unawaited(_disposeEngine());
    super.dispose();
  }

  Future<void> _disposeEngine() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildRemoteView(),
          _buildLocalPreview(),
          _buildTopBar(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildRemoteView() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final engine = _engine;
    if (engine != null && _remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.room.channel),
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
            _joined
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
    if (engine == null || !_joined || _camOff) return const SizedBox.shrink();
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
                  color: _joined ? const Color(0xFF34D399) : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.tutorName ?? 'Phòng học',
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
