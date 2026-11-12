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

/// T10 Đang ghi âm (design V5.6, board V56-Recording).
///
/// Nền giấy, đồng hồ to, trượt để kết thúc. Gia sư nhìn màn này trong lúc đang dạy — mọi
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
    final booked = _bookedMin();
    final kicker = [
      widget.target.studentName,
      widget.target.subjectName,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    final underClock = [
      if (booked != null) 'trên $booked phút',
      ?remaining,
    ].join(' · ');
    final controlsOn =
        (state.isActive || state.error != null) && !state.isFinishing;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
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
                // ── Trạng thái · mẹo · thu nhỏ ───────────────────────────
                Row(
                  children: [
                    _StatusChip(paused: paused, error: state.error != null),
                    const Spacer(),
                    CanvasCircleButton(
                      tooltip: 'Mẹo ghi âm',
                      onTap: () =>
                          unawaited(context.push(AppRoutes.tutorRecordingTips)),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: TutorColors.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    CanvasCircleButton(
                      tooltip: 'Thu nhỏ, vẫn tiếp tục ghi',
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(
                        Icons.remove_rounded,
                        size: 20,
                        color: TutorColors.ink,
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Đồng hồ ─────────────────────────────────────
                        const SizedBox(height: 32),
                        if (kicker.isNotEmpty)
                          Text(
                            kicker,
                            textAlign: TextAlign.center,
                            style: TutorType.rowSub(),
                          ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _clock(state.elapsed),
                            textAlign: TextAlign.center,
                            style:
                                TutorType.display(
                                  size: 64,
                                  weight: FontWeight.w600,
                                  height: 1,
                                ).copyWith(
                                  letterSpacing: -1.9,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                        if (underClock.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            underClock,
                            textAlign: TextAlign.center,
                            style: TutorType.rowSub(),
                          ),
                        ],
                        if (booked != null) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                            ),
                            child: _Bar(
                              value: state.elapsed.inSeconds / (booked * 60),
                            ),
                          ),
                        ],

                        // ── Sóng âm ─────────────────────────────────────
                        const SizedBox(height: 36),
                        _Waveform(levels: _levels, paused: paused),
                        const SizedBox(height: 26),

                        // ── Âm thanh · lưu · màn hình tắt ───────────────
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: TutorSurface.card(),
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: sound.quiet
                                    ? Icons.mic_off_outlined
                                    : Icons.mic_none_rounded,
                                text: 'Âm thanh',
                                trailing: sound.label,
                                trailingColor: sound.color,
                                first: true,
                              ),
                              const _InfoRow(
                                icon: Icons.cloud_done_outlined,
                                text: 'Lưu lại mỗi 5 phút',
                              ),
                              const _InfoRow(
                                icon: Icons.phone_android_rounded,
                                text: 'Vẫn ghi khi tắt màn hình',
                              ),
                            ],
                          ),
                        ),

                        // ── Nghe nhỏ: mẹo có bóng đèn ───────────────────
                        if (sound.quiet) ...[
                          const SizedBox(height: 14),
                          _QuietTip(
                            onTips: () => unawaited(
                              context.push(AppRoutes.tutorRecordingTips),
                            ),
                          ),
                        ] else if (state.error == null) ...[
                          const SizedBox(height: 22),
                          const Center(
                            child: CanvasHand('Cứ dạy tự nhiên nhé'),
                          ),
                        ],

                        // ── Lỗi (nếu có) ────────────────────────────────
                        if (state.error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: TutorType.rowSub(color: TutorColors.danger),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Tạm dừng · huỷ ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundAction(
                      icon: paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: paused ? 'Tiếp tục' : 'Tạm dừng',
                      onTap: controlsOn
                          ? () => ref
                                .read(lessonRecordingProvider.notifier)
                                .togglePause()
                          : null,
                    ),
                    const SizedBox(width: 28),
                    _RoundAction(
                      icon: Icons.close_rounded,
                      label: 'Huỷ bản ghi',
                      onTap: state.isFinishing ? null : _confirmDiscard,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Kết thúc: trượt, để không bấm nhầm giữa buổi ─────────
                _SlideToEnd(
                  busy: state.isFinishing,
                  enabled: controlsOn,
                  onEnd: _finish,
                ),
              ],
            ),
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
    if (paused) return const _SoundLevel('Tạm dừng', TutorColors.ink4);
    final recent = levels.sublist(levels.length - 8);
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    if (avg >= 0.18) return const _SoundLevel('Rõ', TutorColors.ink);
    if (avg >= 0.05) {
      return const _SoundLevel('Nhỏ', TutorColors.warning, quiet: true);
    }
    return const _SoundLevel(
      'Không nghe',
      TutorColors.warning,
      quiet: true,
    );
  }

  final String label;
  final Color color;
  final bool quiet;
}

/// Chip trạng thái đầu màn: "Đang ghi âm" (nền sage, chấm mực), "Tạm dừng",
/// "Có lỗi".
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.paused, required this.error});

  final bool paused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final label = error
        ? 'Có lỗi'
        : paused
        ? 'Tạm dừng'
        : 'Đang ghi âm';
    final bg = error
        ? TutorColors.dangerBg
        : paused
        ? TutorColors.surfaceSunken
        : TutorColors.sage;
    final fg = error ? TutorColors.danger : TutorColors.ink;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: paused && !error ? TutorColors.ink4 : fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TutorType.caption(
              color: fg,
            ).copyWith(fontSize: 11.5, height: 1),
          ),
        ],
      ),
    );
  }
}

/// Thanh tiến độ mảnh 4 px (mực trên nền mực 12%).
class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: 4,
      backgroundColor: TutorColors.ink.withValues(alpha: 0.12),
      color: TutorColors.ink,
    ),
  );
}

/// Hàng trong thẻ trạng thái: icon · chữ · nhãn phải.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.trailing,
    this.trailingColor = TutorColors.ink3,
    this.first = false,
  });

  final IconData icon;
  final String text;
  final String? trailing;
  final Color trailingColor;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: Border(top: first ? BorderSide.none : TutorSurface.rule),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: TutorColors.ink),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TutorType.body())),
        if (trailing != null)
          Text(
            trailing!,
            style: TutorType.caption(
              color: trailingColor,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    ),
  );
}

/// Mẹo khi máy nghe nhỏ: bóng đèn + một câu + "Xem mẹo ›".
class _QuietTip extends StatelessWidget {
  const _QuietTip({required this.onTips});

  final VoidCallback onTips;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
    decoration: BoxDecoration(
      color: TutorColors.sage,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: TutorColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đưa điện thoại lại gần học sinh một chút.',
                style: TutorType.rowSub(color: TutorColors.ink),
              ),
              InkWell(
                onTap: onTips,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Xem mẹo', style: TutorType.action()),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: TutorColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Nút tròn 44 px có nhãn bên dưới; chạm cả nút lẫn nhãn.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F7F4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x141F2A24),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: on ? TutorColors.ink : TutorColors.ink4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TutorType.caption(
                  color: on ? TutorColors.ink3 : TutorColors.ink4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vạch biên độ chạy từ phải sang trái: chỉ trả lời "máy còn nghe thấy không".
class _Waveform extends StatelessWidget {
  const _Waveform({required this.levels, required this.paused});

  final List<double> levels;
  final bool paused;

  static const double _maxH = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < levels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 3,
              height: math.max(6, levels[i] * _maxH),
              decoration: BoxDecoration(
                // Mới nhất (bên phải) đậm nhất, cũ dần nhạt về bên trái.
                color: TutorColors.ink.withValues(
                  alpha: paused ? 0.18 : 0.3 + 0.7 * (i + 1) / levels.length,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Trượt để kết thúc buổi học": kéo núm sang phải quá 85% mới kết thúc.
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
  static const double _knob = 46;
  static const double _inset = 5;
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final max = c.maxWidth - _knob - _inset * 2;
        final t = max <= 0 ? 0.0 : (_dx / max).clamp(0.0, 1.0);
        return Semantics(
          button: true,
          label: 'Kết thúc buổi học',
          onTap: widget.enabled ? widget.onEnd : null,
          child: Container(
            height: _h,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? TutorColors.ink
                  : TutorColors.ink.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(_h / 2),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: _knob),
                    child: Opacity(
                      opacity: 1 - t,
                      child: Text(
                        widget.busy
                            ? 'Đang lưu…'
                            : 'Trượt để kết thúc buổi học',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TutorType.action(color: const Color(0xFFC8CEC8)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _inset + _dx,
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
                      height: _knob,
                      decoration: BoxDecoration(
                        color: widget.enabled
                            ? TutorColors.surface
                            : TutorColors.surface.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
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
                              size: 20,
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
