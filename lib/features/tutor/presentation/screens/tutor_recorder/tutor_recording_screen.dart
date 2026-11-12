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
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recorded_well_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

const Color _recDot = Color(0xFFFF9C80);

/// T10 Đang ghi âm (canvas H3-Recording).
///
/// Nền mực, đồng hồ to, trượt để kết thúc. Gia sư nhìn màn này trong lúc đang dạy — mọi
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
  final List<double> _levels = List.filled(_bars, 0, growable: true);

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
      unawaited(_begin());
    });
  }

  /// Giải thích vì sao cần micro TRƯỚC khi hệ thống hỏi quyền (Google Play
  /// yêu cầu "prominent disclosure" cho dữ liệu nhạy cảm như âm thanh).
  Future<void> _begin() async {
    final notifier = ref.read(lessonRecordingProvider.notifier);
    if (!await notifier.hasMicPermission()) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Cho phép TopTutor dùng micro'),
          content: const Text(
            'TopTutor cần quyền micro để ghi âm buổi học. Ứng dụng chỉ ghi khi '
            'bạn bấm ghi âm, và vẫn ghi khi màn hình tắt cho tới khi bạn kết '
            'thúc buổi.\n\n'
            'Bản ghi được tải lên kho lưu trữ riêng tư của TopTutor, xử lý bằng '
            'AI (Google Gemini) để soạn báo cáo gửi phụ huynh qua Zalo, và tự '
            'động xoá sau 90 ngày.\n\n'
            'Chỉ ghi âm khi phụ huynh đã đồng ý.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) {
        unawaited(Navigator.of(context).maybePop());
        return;
      }
    }
    await notifier.start(
      lessonId: widget.target.lessonId,
      studentName: widget.target.studentName,
      target: widget.target,
    );
  }

  @override
  void dispose() {
    _clockTick?.cancel();
    super.dispose();
  }

  /// Đếm mẫu biên độ khi đang ghi, để T11 báo tỉ lệ thời gian máy nghe nhỏ.
  int _samples = 0;
  int _quietSamples = 0;

  void _pushLevel(double level) {
    setState(() {
      _levels
        ..removeAt(0)
        ..add(level);
    });
    // "Nhỏ" = cả cửa sổ gần đây đều nhỏ (không tính một lúc im lặng ngắn khi
    // học sinh đang nghĩ). Ngưỡng ước lượng, chưa đo trên buổi thật.
    final paused = ref.read(lessonRecordingProvider).isPaused;
    if (!paused) {
      _samples++;
      if (_SoundLevel.of(_levels, paused: false).quiet) _quietSamples++;
    }
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
    final elapsed = ref.read(lessonRecordingProvider).elapsed;

    final status = await ref.read(lessonRecordingProvider.notifier).finish();
    if (!mounted) return;

    // finish() trả null khi chưa đẩy hết đoạn lên hoặc chưa chốt được với
    // server. Lúc đó KHÔNG rời màn: lỗi đã hiện ngay trên đây, và bản ghi vẫn
    // nằm trên máy để bấm lại khi có mạng.
    if (status == null) return;

    // Sang T11 "Ghi âm tốt", rồi từ đó mở bản nháp: AI thường xong trong vài
    // phút, gia sư duyệt ngay tại chỗ trước khi rời nhà học sinh.
    ref.invalidate(recorderPendingReviewsProvider);
    navigator.pop();
    unawaited(
      router.push(
        AppRoutes.tutorRecordedWell,
        extra: RecordedWellArgs(
          review: ReportReviewArgs(
            recordingId: status.recordingId,
            studentName: widget.target.studentName,
            subtitle: widget.target.subjectName,
          ),
          recordedMin: (elapsed.inSeconds / 60).round(),
          bookedMin: _bookedMin(),
          quietShare: _samples == 0 ? 0 : _quietSamples / _samples,
        ),
      ),
    );
  }

  /// Số phút theo lịch từ "19:00" – "20:30"; null nếu không đọc được.
  int? _bookedMin() {
    int? m(String s) {
      final p = s.trim().split(':');
      if (p.length < 2) return null;
      final h = int.tryParse(p[0]);
      final mi = int.tryParse(p[1]);
      return h == null || mi == null ? null : h * 60 + mi;
    }

    final a = m(widget.target.timeStart);
    final b = m(widget.target.timeEnd);
    if (a == null || b == null || b <= a) return null;
    return b - a;
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
    final sound = _SoundLevel.of(_levels, paused: paused);
    const white = TutorColors.surface;
    final muted = white.withValues(alpha: 0.66);
    final kicker = [
      widget.target.studentName,
      widget.target.subjectName,
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: TutorColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            16,
            TutorSurface.gutter,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Buổi học · trạng thái · thu nhỏ ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: CanvasKicker(
                      kicker,
                      color: white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusDot(paused: paused, error: state.error != null),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'Thu nhỏ, vẫn tiếp tục ghi',
                    button: true,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            TutorSurface.radius,
                          ),
                          border: Border.all(
                            color: white.withValues(alpha: 0.35),
                            width: TutorSurface.ruleWidth,
                          ),
                        ),
                        child: const Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Đồng hồ ──────────────────────────────────────────────
              const Spacer(),
              Text(
                _clock(state.elapsed),
                style:
                    TutorType.display(
                      size: 84,
                      weight: FontWeight.w300,
                      color: white,
                    ).copyWith(
                      letterSpacing: -3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  'Lưu lại mỗi 5 phút',
                  ?remaining,
                ].join(' · '),
                style: TutorType.rowSub(color: muted).copyWith(fontSize: 15),
              ),
              const Spacer(),

              // ── Âm thanh ─────────────────────────────────────────────
              _VoiceRow(
                label: 'Âm thanh',
                status: sound.label,
                statusColor: sound.color,
                child: _Waveform(levels: _levels, paused: paused),
              ),
              if (sound.quiet)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: white.withValues(alpha: 0.35),
                        width: TutorSurface.ruleWidth,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đưa điện thoại lại gần học sinh một chút.',
                        style: TutorType.rowTitle(
                          color: white,
                        ).copyWith(fontSize: 16, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => unawaited(
                          context.push(AppRoutes.tutorRecordingTips),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Xem mẹo →',
                            style: TutorType.action(
                              color: TutorColors.accent,
                            ).copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                height: TutorSurface.ruleWidth,
                color: white.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 14),

              // ── Lỗi (nếu có) ─────────────────────────────────────────
              if (state.error != null) ...[
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TutorType.rowSub(color: TutorColors.accent),
                ),
                const SizedBox(height: 12),
              ],

              // ── Kết thúc: trượt, để không bấm nhầm giữa buổi ─────────
              _SlideToEnd(
                busy: state.isFinishing,
                enabled:
                    (state.isActive || state.error != null) &&
                    !state.isFinishing,
                onEnd: _finish,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed:
                      (state.isActive || state.error != null) &&
                          !state.isFinishing
                      ? () => ref
                            .read(lessonRecordingProvider.notifier)
                            .togglePause()
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: white,
                    side: BorderSide(
                      color: white.withValues(alpha: 0.5),
                      width: TutorSurface.ruleWidth,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TutorSurface.radius),
                    ),
                  ),
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 18,
                  ),
                  label: Text(
                    paused ? 'Tiếp tục' : 'Tạm dừng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Vẫn ghi khi tắt màn hình',
                      style: TutorType.caption(color: muted),
                    ),
                  ),
                  TextButton(
                    onPressed: state.isFinishing ? null : _confirmDiscard,
                    child: Text(
                      'Huỷ bản ghi',
                      style: TutorType.caption(
                        color: white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mức âm thanh chung (app chưa tách giọng gia sư / học sinh): trung bình
/// biên độ gần đây → Rõ / Nhỏ / Không nghe thấy.
class _SoundLevel {
  const _SoundLevel(this.label, this.color, {this.quiet = false});

  factory _SoundLevel.of(List<double> levels, {required bool paused}) {
    if (paused) {
      return _SoundLevel('Tạm dừng', TutorColors.surface.withValues(alpha: .6));
    }
    final recent = levels.sublist(levels.length - 8);
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    if (avg >= 0.18) return const _SoundLevel('Rõ', TutorColors.accent);
    if (avg >= 0.05) {
      return const _SoundLevel('Nhỏ', Color(0xFFFF9C80), quiet: true);
    }
    return const _SoundLevel('Không nghe', Color(0xFFFF9C80), quiet: true);
  }

  final String label;
  final Color color;
  final bool quiet;
}

class _VoiceRow extends StatelessWidget {
  const _VoiceRow({
    required this.label,
    required this.status,
    required this.statusColor,
    required this.child,
  });

  final String label;
  final String status;
  final Color statusColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: TutorColors.surface.withValues(alpha: 0.35),
          width: TutorSurface.ruleWidth,
        ),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: TutorColors.surface,
            ),
          ),
        ),
        Expanded(child: child),
        SizedBox(
          width: 84,
          child: Text(
            status,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.paused, required this.error});

  final bool paused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final label = error
        ? 'LỖI'
        : paused
        ? 'DỪNG'
        : 'GHI';
    final dot = error
        ? TutorColors.accent
        : paused
        ? TutorColors.surface.withValues(alpha: 0.45)
        : _recDot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TutorType.kicker(color: TutorColors.surface)),
      ],
    );
  }
}

/// Vạch biên độ chạy từ phải sang trái: chỉ trả lời "máy còn nghe thấy không".
class _Waveform extends StatelessWidget {
  const _Waveform({required this.levels, required this.paused});

  final List<double> levels;
  final bool paused;

  static const double _maxH = 28;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxH,
      child: Row(
        children: [
          for (var i = 0; i < levels.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: math.max(4, levels[i] * _maxH),
                decoration: BoxDecoration(
                  color: TutorColors.accent.withValues(
                    alpha: paused ? 0.3 : (0.45 + levels[i] * 0.55),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Trượt để kết thúc buổi": kéo núm đồng sang phải quá 85% mới kết thúc.
class _SlideToEnd extends StatefulWidget {
  const _SlideToEnd({
    required this.busy,
    required this.enabled,
    required this.onEnd,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onEnd;

  @override
  State<_SlideToEnd> createState() => _SlideToEndState();
}

class _SlideToEndState extends State<_SlideToEnd> {
  static const double _h = 56;
  static const double _knob = 52;
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final max = c.maxWidth - _knob - 4;
        final t = max <= 0 ? 0.0 : (_dx / max).clamp(0.0, 1.0);
        return Semantics(
          button: true,
          label: 'Kết thúc buổi học',
          onTap: widget.enabled ? widget.onEnd : null,
          child: Container(
            height: _h,
            decoration: BoxDecoration(
              color: TutorColors.surface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(TutorSurface.radius),
              border: Border.all(
                color: TutorColors.surface.withValues(alpha: 0.35),
                width: TutorSurface.ruleWidth,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Opacity(
                    opacity: 1 - t,
                    child: Text(
                      widget.busy ? 'Đang lưu…' : 'Trượt để kết thúc buổi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TutorColors.surface,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 2 + _dx,
                  child: GestureDetector(
                    onHorizontalDragUpdate: widget.enabled
                        ? (d) => setState(
                            () => _dx = (_dx + d.delta.dx).clamp(0.0, max),
                          )
                        : null,
                    onHorizontalDragEnd: widget.enabled
                        ? (_) {
                            final done = t > 0.85;
                            setState(() => _dx = 0);
                            if (done) widget.onEnd();
                          }
                        : null,
                    child: Container(
                      width: _knob,
                      height: _knob - 4,
                      decoration: BoxDecoration(
                        color: widget.enabled
                            ? TutorColors.accent
                            : TutorColors.accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(
                          TutorSurface.radius - 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: widget.busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TutorColors.ink,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: TutorColors.ink,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
