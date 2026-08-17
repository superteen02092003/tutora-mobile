import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/shared/live_session/live_session_call_screen.dart';
import 'package:tutora/shared/live_session/session_lobby_hub.dart';
import 'package:tutora/shared/live_session/session_lobby_models.dart';
import 'package:tutora/shared/widgets/app_page_header.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Phòng chờ trước khi vào lớp: thử camera/mic, xem ai đã vào, xác nhận đổi giờ.
class SessionLobbyScreen extends ConsumerStatefulWidget {
  const SessionLobbyScreen({
    required this.classSessionId,
    super.key,
    this.tutorName,
  });

  final int classSessionId;
  final String? tutorName;

  @override
  ConsumerState<SessionLobbyScreen> createState() => _SessionLobbyScreenState();
}

class _SessionLobbyScreenState extends ConsumerState<SessionLobbyScreen> {
  late final SessionLobbyHub _hub = ref.read(sessionLobbyHubProvider);

  LobbyPhase _phase = LobbyPhase.connecting;
  LobbyInfo? _info;
  LobbyWaitingState? _waiting;
  ScheduleChangeState? _change;
  SessionScheduleConflict? _conflict;
  String? _error;
  bool _responding = false;

  CameraController? _cam;
  bool _camOn = true;
  bool _micOn = true;
  String? _camError;

  @override
  void initState() {
    super.initState();
    unawaited(_startPreview());
    unawaited(_connect());
  }

  Future<void> _startPreview() async {
    try {
      final granted = await Permission.camera.request();
      if (!granted.isGranted) {
        setState(() => _camError = 'Chưa cấp quyền camera.');
        return;
      }
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _camError = 'Không tìm thấy camera.');
        return;
      }
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _cam = ctrl);
    } catch (_) {
      if (mounted) setState(() => _camError = 'Không mở được camera.');
    }
  }

  Future<void> _connect() async {
    _hub.onInfo = (i) {
      if (mounted) setState(() => _info = i);
    };
    _hub.onWaiting = (w) {
      if (!mounted) return;
      setState(() {
        _waiting = w;
        if (_phase == LobbyPhase.connecting) _phase = LobbyPhase.waiting;
      });
    };
    _hub.onScheduleChange = (st) {
      if (!mounted) return;
      setState(() {
        _change = st;
        _conflict = st.conflict;
        if (st.conflict != null) _phase = LobbyPhase.waiting;
      });
    };
    _hub.onConflict = (c) {
      if (!mounted) return;
      setState(() {
        _conflict = c;
        if (c != null) _phase = LobbyPhase.waiting;
      });
    };
    _hub.onReady = () {
      if (!mounted) return;
      setState(() {
        _phase = LobbyPhase.ready;
        // Vào lại giữa buổi: server báo thẳng ready, không kèm lobbyState.
        _waiting = const LobbyWaitingState(
          tutorWaiting: true,
          studentWaiting: true,
        );
      });
    };
    _hub.onClosed = (reason) {
      if (!mounted) return;
      setState(
        () => _phase = reason == 'ended'
            ? LobbyPhase.ended
            : LobbyPhase.unavailable,
      );
    };
    _hub.onBlocked = () {
      if (mounted) setState(() => _phase = LobbyPhase.blockedPayment);
    };
    _hub.onReconnecting = () {
      if (!mounted) return;
      setState(() {
        if (_phase == LobbyPhase.waiting) _phase = LobbyPhase.connecting;
      });
    };

    try {
      await _hub.connect(widget.classSessionId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _phase = LobbyPhase.error;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_cam?.dispose());
    unawaited(_hub.dispose());
    super.dispose();
  }

  bool get _canEnter =>
      _phase == LobbyPhase.ready &&
      _conflict == null &&
      !(_change?.rescheduleProposalPending ?? false);

  Future<void> _respond({required bool confirmed}) async {
    setState(() => _responding = true);
    try {
      await _hub.respondToScheduleChange(
        widget.classSessionId,
        confirmed: confirmed,
      );
      if (!mounted) return;
      AppToast.show(
        context,
        message: confirmed ? 'Đã đồng ý giờ học mới.' : 'Đã từ chối giờ mới.',
        type: AppToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  void _enter() {
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LiveSessionCallScreen(
            classSessionId: widget.classSessionId,
            tutorName: _info?.tutorName ?? widget.tutorName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppPageHeader(title: 'Phòng chờ'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _PreviewBox(
                    controller: _cam,
                    camOn: _camOn,
                    error: _camError,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ToggleButton(
                        icon: _micOn
                            ? Icons.mic_rounded
                            : Icons.mic_off_rounded,
                        on: _micOn,
                        onTap: () => setState(() => _micOn = !_micOn),
                      ),
                      const SizedBox(width: 14),
                      _ToggleButton(
                        icon: _camOn
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        on: _camOn,
                        onTap: () => setState(() => _camOn = !_camOn),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.ink3,
                    ),
                  ),

                  if (_info != null) ...[
                    const SizedBox(height: 18),
                    _MetaCard(info: _info!),
                  ],

                  if (_conflict != null) ...[
                    const SizedBox(height: 14),
                    _Banner(
                      title: 'Chưa thể bắt đầu vì trùng lịch',
                      message: _conflict!.message,
                    ),
                  ],

                  if (_change?.rescheduleProposalPending ?? false) ...[
                    const SizedBox(height: 14),
                    const _Banner(
                      title: 'Đang có đề xuất đổi lịch',
                      message:
                          'Vui lòng vào chi tiết buổi học để đồng ý hoặc từ chối trước.',
                    ),
                  ],

                  if (_change?.awaitingMyResponse ?? false) ...[
                    const SizedBox(height: 14),
                    _ScheduleChangeCard(
                      state: _change!,
                      busy: _responding,
                      onAccept: () => unawaited(_respond(confirmed: true)),
                      onReject: () => unawaited(_respond(confirmed: false)),
                    ),
                  ],

                  const SizedBox(height: 18),
                  _PresenceRow(
                    info: _info,
                    waiting: _waiting,
                    tutorFallback: widget.tutorName,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _Banner(
                      title: 'Không vào được phòng chờ',
                      message: _error!,
                    ),
                  ],
                ],
              ),
            ),
            _Footer(
              canEnter: _canEnter,
              label: _canEnter ? 'Vào lớp học' : _waitLabel,
              onEnter: _enter,
            ),
          ],
        ),
      ),
    );
  }

  String get _title => switch (_phase) {
    LobbyPhase.ended => 'Buổi học đã kết thúc',
    LobbyPhase.unavailable => 'Buổi học không khả dụng',
    LobbyPhase.blockedPayment => 'Cần thanh toán để học tiếp',
    LobbyPhase.error => 'Không vào được phòng chờ',
    _ => 'Chuẩn bị vào lớp',
  };

  String get _subtitle => switch (_phase) {
    LobbyPhase.ended => 'Gia sư đã kết thúc buổi học này.',
    LobbyPhase.unavailable => 'Buổi học đã huỷ hoặc không còn hiệu lực.',
    LobbyPhase.blockedPayment =>
      'Các buổi tiếp theo mở khi thanh toán phần còn lại.',
    LobbyPhase.error => _error ?? 'Vui lòng thử lại.',
    LobbyPhase.ready => 'Cả hai đã có mặt. Kiểm tra camera/micro rồi vào lớp.',
    // BE chỉ mở phòng khi CẢ HAI cùng đứng ở lobby, không ai vào trước được.
    _ =>
      'Phòng mở khi cả hai cùng vào. Kiểm tra camera và micro trong lúc chờ '
          'gia sư nhé.',
  };

  String get _waitLabel => switch (_phase) {
    LobbyPhase.connecting => 'Đang kết nối…',
    LobbyPhase.ended || LobbyPhase.unavailable => 'Không khả dụng',
    LobbyPhase.blockedPayment => 'Chưa thanh toán',
    LobbyPhase.error => 'Lỗi kết nối',
    _ => 'Đang chờ phía còn lại…',
  };
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({
    required this.controller,
    required this.camOn,
    required this.error,
  });

  final CameraController? controller;
  final bool camOn;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final ready = controller?.value.isInitialized ?? false;
    return AspectRatio(
      // 4:3 thay vì 3:4 — khung dọc quá cao đẩy hết nội dung dưới ra ngoài.
      aspectRatio: 4 / 3,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: !camOn || !ready
            ? Center(
                child: Text(
                  error ?? (camOn ? 'Đang mở camera…' : 'Camera đang tắt'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.cream,
                  ),
                ),
              )
            : FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller!.value.previewSize?.height ?? 1,
                  height: controller!.value.previewSize?.width ?? 1,
                  child: CameraPreview(controller!),
                ),
              ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.on,
    required this.onTap,
  });

  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.paper : AppColors.error,
        border: Border.all(color: on ? AppColors.line : AppColors.error),
      ),
      child: Icon(icon, size: 22, color: on ? AppColors.ink : Colors.white),
    ),
  );
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.info});
  final LobbyInfo info;

  @override
  Widget build(BuildContext context) {
    final s = info.startDt;
    final e = info.endDt;
    final text = s == null || e == null
        ? '—'
        : '${DateFormat('EEEE, dd/MM', 'vi_VN').format(s)} · '
              '${DateFormat('HH:mm').format(s)} – ${DateFormat('HH:mm').format(e)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 20, color: AppColors.ink3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceRow extends StatelessWidget {
  const _PresenceRow({
    required this.info,
    required this.waiting,
    required this.tutorFallback,
  });

  final LobbyInfo? info;
  final LobbyWaitingState? waiting;
  final String? tutorFallback;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    alignment: WrapAlignment.center,
    children: [
      _Chip(
        label: 'Gia sư · ${info?.tutorName ?? tutorFallback ?? 'Gia sư'}',
        active: waiting?.tutorWaiting ?? false,
      ),
      _Chip(
        label: 'Học sinh · ${info?.studentName ?? 'Bạn'}',
        active: waiting?.studentWaiting ?? false,
      ),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE0E7DF) : AppColors.paper,
      border: Border.all(color: active ? AppColors.moss : AppColors.line),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.moss : AppColors.ink4,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.moss : AppColors.ink3,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF3C7),
      border: Border.all(color: const Color(0xFFE6D2B5)),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF92400E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.ink2,
          ),
        ),
      ],
    ),
  );
}

/// Đề xuất học ngoài giờ đã đặt — đồng ý/từ chối ngay trong phòng chờ.
class _ScheduleChangeCard extends StatelessWidget {
  const _ScheduleChangeCard({
    required this.state,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final ScheduleChangeState state;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final s = state.adjustedStartDt;
    final e = state.adjustedEndDt;
    final when = s == null || e == null
        ? null
        : '${DateFormat('dd/MM').format(s)} · '
              '${DateFormat('HH:mm').format(s)} – ${DateFormat('HH:mm').format(e)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xác nhận học ngoài giờ đã đặt',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            when == null
                ? 'Hai bên cần đồng ý để bắt đầu buổi học lúc này.'
                : 'Giờ học mới: $when. Hai bên cần đồng ý để bắt đầu.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: busy ? null : onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'Từ chối',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: busy ? null : onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: busy ? AppColors.line : AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      busy ? 'Đang gửi…' : 'Đồng ý giờ mới',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: busy ? AppColors.ink4 : AppColors.cream,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canEnter,
    required this.label,
    required this.onEnter,
  });

  final bool canEnter;
  final String label;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      MediaQuery.of(context).padding.bottom + 12,
    ),
    decoration: const BoxDecoration(
      color: AppColors.paper,
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    child: GestureDetector(
      onTap: canEnter ? onEnter : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: canEnter ? AppColors.ink : AppColors.line,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: canEnter ? AppColors.cream : AppColors.ink4,
          ),
        ),
      ),
    ),
  );
}
