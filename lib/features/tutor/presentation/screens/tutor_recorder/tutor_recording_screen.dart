import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';

const Color _recDot = Color(0xFFE0514F);

/// Màn đang ghi âm (prototype: "4 · Đang ghi âm").
///
/// Nền tối, đồng hồ to, hai nút. Gia sư nhìn màn này trong lúc đang dạy — mọi
/// thứ không phải "còn đang ghi không" và "dừng thế nào" đều là nhiễu.
///
/// Nút thu nhỏ (và vuốt quay lại) chỉ ĐÓNG MÀN, không dừng ghi: bản ghi chạy
/// trong foreground service; bấm nút mic ở thanh tab để mở lại màn này.
class TutorRecordingScreen extends ConsumerStatefulWidget {
  const TutorRecordingScreen({required this.target, super.key});

  final RecordingTarget target;

  @override
  ConsumerState<TutorRecordingScreen> createState() =>
      _TutorRecordingScreenState();
}

class _TutorRecordingScreenState extends ConsumerState<TutorRecordingScreen> {
  static const int _bars = 20;

  /// Lịch sử biên độ để vẽ sóng chạy từ phải sang trái.
  final List<double> _levels = List.filled(_bars, 0);

  /// Cập nhật dòng "còn khoảng X phút theo lịch" mỗi 30 giây.
  Timer? _clockTick;

  @override
  void initState() {
    super.initState();
    _clockTick = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(lessonRecordingProvider);
      if (state.isRecording) return;
      unawaited(
        ref
            .read(lessonRecordingProvider.notifier)
            .start(
              lessonId: widget.target.lessonId,
              studentName: widget.target.studentName,
              target: widget.target,
            ),
      );
    });
  }

  @override
  void dispose() {
    _clockTick?.cancel();
    super.dispose();
  }

  void _pushLevel(double level) {
    setState(() {
      _levels
        ..removeAt(0)
        ..add(level);
    });
  }

  static String _clock(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String? _remaining() {
    final end = widget.target.scheduledEnd;
    if (end == null) return null;
    final left = end.difference(DateTime.now()).inMinutes;
    if (left > 0) return 'còn khoảng $left phút theo lịch';
    if (left == 0) return 'đến giờ kết thúc theo lịch';
    return 'quá giờ ${-left} phút so với lịch';
  }

  Future<void> _finish() async {
    // Lấy messenger và navigator TRƯỚC khi await: sau khi pop, context của màn
    // này đã tháo, gọi ScaffoldMessenger.of(context) lúc đó là bắt vào cây đã
    // chết và snackbar không bao giờ hiện.
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    final status = await ref.read(lessonRecordingProvider.notifier).finish();
    if (!mounted) return;

    // finish() trả null khi chưa đẩy hết đoạn lên hoặc chưa chốt được với
    // server. Lúc đó KHÔNG rời màn: lỗi đã hiện ngay trên đây, và bản ghi vẫn
    // nằm trên máy để bấm lại khi có mạng.
    if (status == null) return;

    // Sang thẳng màn "Nội dung buổi": AI thường xong trong 1–2 phút, gia sư
    // duyệt ngay tại chỗ trước khi rời nhà học sinh.
    ref.invalidate(recorderPendingReviewsProvider);
    navigator.pop();
    unawaited(
      router.push(
        AppRoutes.tutorReportReview,
        extra: ReportReviewArgs(
          recordingId: status.recordingId,
          studentName: widget.target.studentName,
          subtitle: widget.target.subjectName,
        ),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ bản ghi?'),
        content: const Text(
          'Toàn bộ phần đã ghi của buổi này sẽ bị xoá và không khôi phục được.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục ghi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Huỷ bản ghi',
              style: TextStyle(color: TutorColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(lessonRecordingProvider.notifier).discard();
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LessonRecordingState>(lessonRecordingProvider, (prev, next) {
      if (prev?.level != next.level) _pushLevel(next.level);
    });

    final state = ref.watch(lessonRecordingProvider);
    final paused = state.isPaused;
    final remaining = _remaining();
    final white = TutorColors.surface;
    final muted = white.withValues(alpha: 0.66);

    return Scaffold(
      backgroundColor: TutorColors.heroInk,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              // ── Trạng thái + thu nhỏ ───────────────────────────────
              Row(
                children: [
                  _StatusDot(paused: paused, error: state.error != null),
                  const Spacer(),
                  Semantics(
                    label: 'Thu nhỏ, vẫn tiếp tục ghi',
                    button: true,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Đồng hồ · sóng · buổi học ─────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _clock(state.elapsed),
                      style: TutorType.numeralLarge(color: white).copyWith(
                        fontSize: 56,
                        letterSpacing: -2,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (remaining != null) ...[
                      const SizedBox(height: 10),
                      Text(remaining, style: TutorType.caption(color: muted)),
                    ],
                    const SizedBox(height: 30),
                    _Waveform(levels: _levels, paused: paused),
                    const SizedBox(height: 30),
                    Text(
                      widget.target.studentName,
                      textAlign: TextAlign.center,
                      style: TutorType.numeralLarge(color: white),
                    ),
                    if (widget.target.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.target.subtitle,
                        textAlign: TextAlign.center,
                        style: TutorType.rowTitle(
                          color: white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: TutorColors.accent,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Báo cáo → Phụ huynh',
                            style: TutorType.caption(color: TutorColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Lỗi (nếu có) ──────────────────────────────────────
              if (state.error != null) ...[
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TutorType.rowSub(color: TutorColors.accent),
                ),
                const SizedBox(height: 14),
              ],

              // ── Nút ───────────────────────────────────────────────
              _Controls(
                paused: paused,
                busy: state.isFinishing,
                enabled: state.isActive || state.error != null,
                onTogglePause: () =>
                    ref.read(lessonRecordingProvider.notifier).togglePause(),
                onFinish: _finish,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 13, color: muted),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Vẫn ghi khi tắt màn hình hoặc có cuộc gọi',
                      style: TutorType.caption(color: muted),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: state.isFinishing ? null : _confirmDiscard,
                child: Text(
                  'Huỷ bản ghi',
                  style: TutorType.caption(
                    color: white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.paused, required this.error});

  final bool paused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final label = error
        ? 'KHÔNG GHI ĐƯỢC'
        : paused
        ? 'TẠM DỪNG'
        : 'ĐANG GHI';
    final dot = error
        ? TutorColors.accent
        : paused
        ? TutorColors.surface.withValues(alpha: 0.45)
        : _recDot;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TutorType.caption(color: TutorColors.surface).copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

/// Sóng âm: 20 vạch vàng chạy từ phải sang trái. Chỉ để trả lời "máy có còn
/// nghe thấy tiếng không", không phải để đọc chính xác biên độ.
class _Waveform extends StatelessWidget {
  const _Waveform({required this.levels, required this.paused});

  final List<double> levels;
  final bool paused;

  static const double _maxH = 76;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxH,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < levels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 5,
              height: math.max(8, levels[i] * _maxH),
              decoration: BoxDecoration(
                color: TutorColors.accent.withValues(
                  alpha: paused ? 0.3 : (0.45 + levels[i] * 0.55),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.paused,
    required this.busy,
    required this.enabled,
    required this.onTogglePause,
    required this.onFinish,
  });

  final bool paused;
  final bool busy;
  final bool enabled;
  final VoidCallback onTogglePause;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled && !busy ? onTogglePause : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: TutorColors.surface,
              side: BorderSide(
                color: TutorColors.surface.withValues(alpha: 0.3),
              ),
              shape: shape,
            ),
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 18,
            ),
            label: Text(
              paused ? 'Tiếp tục' : 'Tạm dừng',
              style: TutorType.action(color: TutorColors.surface),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled && !busy ? onFinish : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: TutorColors.accent,
              foregroundColor: TutorColors.heroInk,
              disabledBackgroundColor: TutorColors.accent.withValues(
                alpha: 0.4,
              ),
              shape: shape,
            ),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TutorColors.heroInk,
                    ),
                  )
                : const Icon(Icons.stop_rounded, size: 18),
            label: Text(
              busy ? 'Đang lưu…' : 'Kết thúc',
              style: TutorType.action(color: TutorColors.heroInk),
            ),
          ),
        ),
      ],
    );
  }
}
