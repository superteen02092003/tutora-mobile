import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_math_text.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_ui.dart';

/// Tham số mở màn "Trước buổi học".
///
/// [lessonId] là buổi đã ghi gần nhất — kế hoạch (`plan`) của buổi đó dành cho
/// buổi tiếp theo. [nextLessonAt] là giờ buổi tới nếu đã lên lịch.
class BeforeLessonArgs {
  const BeforeLessonArgs({
    required this.lessonId,
    this.studentName = '',
    this.nextLessonAt,
  });

  final String lessonId;
  final String studentName;
  final DateTime? nextLessonAt;
}

/// T9 Trước buổi học: các lỗ hổng đã thấy (Sai / Đúng), rồi 15 phút đầu buổi
/// theo bốn bước Kiểm tra · Bài về nhà · Nhớ lại · Khởi động.
class TopiBeforeLessonScreen extends ConsumerWidget {
  const TopiBeforeLessonScreen({required this.args, super.key});

  final BeforeLessonArgs args;

  static Future<void> open(BuildContext context, BeforeLessonArgs args) =>
      GoRouter.of(context).push(AppRoutes.tutorBeforeLesson, extra: args);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(topiFlagsNowProvider);
    final topi = ref.watch(lessonTopiProvider(args.lessonId));

    final Widget body;
    if (!flags.plan) {
      body = const _Message('Tính năng này chưa bật cho tài khoản của bạn.');
    } else {
      body = topi.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _Message(
          'Không tải được kế hoạch. Chạm để thử lại.',
          onTap: () => ref.invalidate(lessonTopiProvider(args.lessonId)),
        ),
        data: (t) {
          final plan = t?.plan;
          if (plan == null || plan.isEmpty) {
            return const _Message(
              'Chưa có kế hoạch cho buổi tới. Kế hoạch có sau khi buổi '
              'trước được ghi âm và xử lý xong.',
            );
          }
          return _PlanView(plan: plan);
        },
      );
    }

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            CanvasHeader(
              onBack: () => Navigator.of(context).maybePop(),
              right: [
                if (args.studentName.isNotEmpty) args.studentName,
                if (args.nextLessonAt != null) _when(args.nextLessonAt!),
              ].join(' · '),
              title: 'Trước buổi học',
              lead:
                  'Các lỗ hổng thấy trong bản ghi, và kế hoạch cho 15 phút đầu buổi. Sau đó học sinh mang bài của mình ra.',
            ),
            const SizedBox(height: 24),
            Padding(padding: TutorSurface.screenPadding, child: body),
            if (flags.plan && (topi.valueOrNull?.plan?.isEmpty == false))
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  20,
                  TutorSurface.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CanvasCta(
                      label: 'Bắt đầu ghi âm',
                      icon: const Icon(
                        Icons.circle,
                        size: 14,
                        color: TutorColors.ink,
                      ),
                      onPressed: () => context.push(AppRoutes.tutorRecorder),
                    ),
                    const SizedBox(height: 8),
                    CanvasGhostLink(
                      label: 'Mẹo ghi âm',
                      onTap: () => context.push(AppRoutes.tutorRecordingTips),
                    ),
                    Text(
                      'Chỉ ghi âm khi phụ huynh đã đồng ý.',
                      textAlign: TextAlign.center,
                      style: TutorType.rowSub().copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String _when(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${_weekdays[d.weekday - 1]} ${d.day}/${d.month} · '
      '${two(d.hour)}:${two(d.minute)}';
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CanvasRow(
    onTap: onTap,
    lastRule: true,
    child: Text(
      text,
      style: TutorType.rowSub().copyWith(fontSize: 15, height: 1.45),
    ),
  );
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});

  final TopiPlan plan;

  static const _stepOrder = ['check', 'homework', 'memory', 'warmup'];

  @override
  Widget build(BuildContext context) {
    final gaps = [...plan.gaps];
    // Canvas T9: lỗ hổng đang tập trung (khối tối), rồi các lỗ hổng "tiếp theo";
    // lỗ hổng "chỉ theo dõi" gom vào một mục thu gọn để màn không dài.
    int rank(TopiGap g) => switch (g.role) {
      'focus' => 0,
      'next' => 1,
      _ => 2,
    };
    final shown = gaps.where((g) => g.role != 'watch').toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    final watched = gaps.where((g) => g.role == 'watch').toList();
    final steps = [...plan.steps]
      ..sort((a, b) {
        int i(TopiStep s) {
          final k = _stepOrder.indexOf(s.name.replaceAll(RegExp('[-_ ]'), ''));
          return k < 0 ? _stepOrder.length : k;
        }

        return i(a).compareTo(i(b));
      });
    final total = steps.fold<int>(0, (s, x) => s + (x.minutes ?? 0));
    final stepsTitle = total > 0 ? '$total phút đầu buổi' : 'Đầu buổi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gaps.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${gaps.length}', style: TutorType.display(size: 72)),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: CanvasKicker(
                  'lỗ hổng thấy\ntrong các buổi',
                  color: TutorColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < shown.length; i++)
            _GapCard(gap: shown[i], number: i + 1, dark: i == 0),
          if (watched.isNotEmpty)
            CanvasExpander(
              title: 'Chỉ theo dõi',
              badge: '${watched.length}',
              lastRule: true,
              children: [
                for (final g in watched)
                  Text(
                    [
                      g.title ?? g.node ?? '—',
                      if ((g.seenInLessons ?? 0) > 0)
                        'gặp ${g.seenInLessons} buổi',
                    ].join(' · '),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          const CanvasTipBox(
            'Mỗi lần một lỗ hổng: lỗ hổng gặp nhiều nhất. Sửa một thói quen sai cần vài buổi.',
          ),
        ],
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CanvasKicker(
              '$stepsTitle · ${steps.length} bước',
              color: TutorColors.ink,
            ),
          ),
          for (var i = 0; i < steps.length; i++)
            _StepCard(
              step: steps[i],
              number: i + 1,
              last: i == steps.length - 1,
            ),
          const SizedBox(height: 14),
          const CanvasTipBox(
            'Kiểm tra bằng bài mới, không gợi ý. Làm lại bài cũ không chứng minh gì vì học sinh đã thấy đáp án.',
          ),
        ],
        const SizedBox(height: 8),
        const CanvasExpander(
          title: 'Trước khi ghi âm',
          lastRule: true,
          children: [
            Text('Điện thoại đặt giữa bàn, cách mỗi người khoảng 40 cm'),
            Text('Bật Không làm phiền, pin trên 30%'),
            Text('Học online: dùng loa laptop, điện thoại đặt cạnh'),
          ],
        ),
      ],
    );
  }
}

String _roleLabel(String? role, int number) => switch (role) {
  'focus' => 'Lỗ hổng $number · luyện ngay',
  'next' => 'Lỗ hổng $number · tiếp theo',
  'watch' => 'Lỗ hổng $number · chỉ theo dõi',
  _ => 'Lỗ hổng $number',
};

class _GapCard extends StatelessWidget {
  const _GapCard({
    required this.gap,
    required this.number,
    required this.dark,
  });

  final TopiGap gap;
  final int number;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final title = gap.title ?? gap.node ?? '—';
    final head = Row(
      children: [
        Expanded(
          child: CanvasKicker(
            _roleLabel(gap.role, number),
            color: dark ? TutorColors.accent : TutorColors.ink3,
          ),
        ),
        if (gap.level != null) TopiLevelChip(level: gap.level!),
      ],
    );
    final lines = <Widget>[
      if (gap.wrong != null) _Line(ok: false, text: gap.wrong!, dark: dark),
      if (gap.right != null) _Line(ok: true, text: gap.right!, dark: dark),
    ];
    final seen = (gap.seenInLessons ?? 0) > 0
        ? 'Gặp trong ${gap.seenInLessons} buổi'
        : null;
    if (dark) {
      return CanvasDarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            head,
            const SizedBox(height: 6),
            Text(
              title,
              style: TutorType.display(
                size: 22,
                weight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ).copyWith(letterSpacing: -0.5),
            ),
            if (lines.isNotEmpty) ...[const SizedBox(height: 8), ...lines],
            if (seen != null) ...[
              const SizedBox(height: 8),
              Text(
                seen,
                style: const TextStyle(fontSize: 14, color: Color(0xFFDCE8E0)),
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: TutorSurface.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head,
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: TutorColors.ink,
            ),
          ),
          if (lines.isNotEmpty) ...[const SizedBox(height: 8), ...lines],
          if (seen != null) ...[
            const SizedBox(height: 6),
            Text(seen, style: TutorType.rowSub().copyWith(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// "✗ Sai: …" / "✓ Đúng: …" như canvas — đỏ gạch / xanh lá, nhạt hơn trên nền tối.
class _Line extends StatelessWidget {
  const _Line({required this.ok, required this.text, required this.dark});

  final bool ok;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark
        ? (ok ? const Color(0xFFCFEBD9) : const Color(0xFFF6D3C9))
        : (ok ? TutorColors.success : const Color(0xFF9A3B27));
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: ok ? '✓ Đúng: ' : '✗ Sai: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: topiMathText(text)),
          ],
        ),
        style: TextStyle(fontSize: 15, height: 1.5, color: color),
      ),
    );
  }
}

String _stepLabel(String name) =>
    switch (name.replaceAll(RegExp('[-_ ]'), '')) {
      'check' => 'Kiểm tra',
      'homework' => 'Bài về nhà',
      'memory' => 'Nhớ lại',
      'warmup' => 'Khởi động',
      _ => name,
    };

/// Một bước đầu buổi: số phút lớn bên trái, tên bước + câu hỏi bên phải.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.number,
    required this.last,
  });

  final TopiStep step;
  final int number;
  final bool last;

  @override
  Widget build(BuildContext context) => CanvasRow(
    lastRule: last,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: step.minutes == null ? '–' : '${step.minutes}'),
                const TextSpan(
                  text: ' phút',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: TutorColors.ink3,
                  ),
                ),
              ],
            ),
            style: TutorType.display(
              size: 30,
              weight: FontWeight.w300,
              color: TutorColors.ink,
            ).copyWith(letterSpacing: -1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CanvasKicker(
                '$number · ${_stepLabel(step.name)}',
                color: TutorColors.ink,
              ),
              for (final a in step.asks) ...[
                const SizedBox(height: 8),
                _AskBlock(ask: a),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Một câu hỏi: "Hỏi: …", đề bài, và đáp án gập lại cho gia sư.
class _AskBlock extends StatefulWidget {
  const _AskBlock({required this.ask});

  final TopiAsk ask;

  @override
  State<_AskBlock> createState() => _AskBlockState();
}

class _AskBlockState extends State<_AskBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.ask;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (a.say != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Hỏi: ',
                  style: TutorType.rowSub(
                    color: TutorColors.ink,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: topiAskText(a.say!),
                  style: TutorType.rowSub(color: TutorColors.ink2),
                ),
              ],
            ),
          ),
        if (a.problem != null) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: TutorSurface.well(),
            child: Text(
              topiMathText(a.problem!),
              style: TutorType.rowTitle().copyWith(fontSize: 15),
            ),
          ),
        ],
        if (a.answer != null) ...[
          const SizedBox(height: 2),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                children: [
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: TutorColors.ink3,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _open ? 'Ẩn đáp án' : 'Xem đáp án (chỉ gia sư)',
                    style: TutorType.action(color: TutorColors.ink3),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 4),
              child: Text(
                topiMathText(a.answer!),
                style: TutorType.rowTitle(
                  color: TopiLevelColors.standard,
                ).copyWith(fontSize: 14),
              ),
            ),
        ],
      ],
    );
  }
}

/// Buổi đã có báo cáo gần nhất (đã gửi hoặc chờ duyệt) trong danh sách buổi
/// đã ghi, xếp mới nhất trước. Kế hoạch Topi của buổi này dành cho buổi tới.
RecorderLessonDto? latestReportedLesson(Iterable<RecorderLessonDto> recorded) {
  for (final l in recorded) {
    if (l.status == 'sent' || l.status == 'awaiting_approval') return l;
  }
  return null;
}

/// Lối vào "Trước buổi học" khi chỉ biết học sinh (thẻ buổi hôm nay ở trang
/// chủ): tự tìm buổi có báo cáo gần nhất. Không vẽ gì khi chưa có.
class TopiStudentBeforeLessonEntry extends ConsumerWidget {
  const TopiStudentBeforeLessonEntry({
    required this.studentId,
    required this.studentName,
    this.nextLessonAt,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String studentId;
  final String studentName;
  final DateTime? nextLessonAt;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(topiFlagsNowProvider).plan) return const SizedBox.shrink();
    final lessons =
        ref.watch(recorderStudentLessonsProvider(studentId)).valueOrNull ??
        const <RecorderLessonDto>[];
    final now = DateTime.now();
    final recorded = lessons.where((l) => l.status != 'scheduled').toList()
      ..sort((a, b) => (b.when ?? now).compareTo(a.when ?? now));
    final latest = latestReportedLesson(recorded);
    if (latest == null) return const SizedBox.shrink();
    return TopiBeforeLessonEntry(
      args: BeforeLessonArgs(
        lessonId: latest.lessonId,
        studentName: studentName,
        nextLessonAt: nextLessonAt,
      ),
      padding: padding,
    );
  }
}

/// Lối vào màn "Trước buổi học" — đặt ở chi tiết buổi đã ghi, hồ sơ học sinh
/// và thẻ buổi hôm nay. Không vẽ gì khi cờ `plan` tắt hoặc chưa có kế hoạch,
/// nên các màn đó giữ nguyên như trước.
class TopiBeforeLessonEntry extends ConsumerWidget {
  const TopiBeforeLessonEntry({
    required this.args,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final BeforeLessonArgs args;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(topiFlagsNowProvider).plan) return const SizedBox.shrink();
    final plan = ref.watch(lessonTopiProvider(args.lessonId)).valueOrNull?.plan;
    if (plan == null || plan.isEmpty) return const SizedBox.shrink();

    final parts = [
      'Trước buổi học',
      if (plan.gaps.isNotEmpty) '${plan.gaps.length} lỗ hổng',
      if (plan.steps.isNotEmpty) '${plan.steps.length} bước đầu buổi',
    ];
    TopiGap? focus;
    for (final g in plan.gaps) {
      if (g.role == 'focus') focus = g;
    }
    focus ??= plan.gaps.firstOrNull;
    // Canvas T5: khối tối "LỖ HỔNG 1 · LUYỆN NGAY" dẫn sang màn Trước buổi học.
    return Padding(
      padding: padding,
      child: CanvasDarkCard(
        onTap: () => TopiBeforeLessonScreen.open(context, args),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CanvasKicker(parts.join(' · '), color: TutorColors.accent),
                  const SizedBox(height: 6),
                  Text(
                    focus?.title ?? focus?.node ?? 'Kế hoạch 15 phút đầu buổi',
                    style: TutorType.display(
                      size: 22,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ).copyWith(letterSpacing: -0.5),
                  ),
                  if ((focus?.seenInLessons ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Gặp trong ${focus!.seenInLessons} buổi · luyện ngay',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFDCE8E0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const CanvasChevron(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
