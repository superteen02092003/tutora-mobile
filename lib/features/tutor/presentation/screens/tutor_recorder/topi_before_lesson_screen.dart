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

/// V5.6 "Chuẩn bị buổi học": lỗ hổng đang luyện (thẻ sage, Sai / Đúng), rồi
/// 15 phút đầu buổi theo bốn bước Kiểm tra · Bài về nhà · Nhớ lại · Khởi động
/// trên một đường thời gian. Mọi khối do Topi soạn mang nhãn "Nháp AI".
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
    final hasPlan = flags.plan && (topi.valueOrNull?.plan?.isEmpty == false);

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    CanvasHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      right: args.nextLessonAt == null
                          ? null
                          : _when(args.nextLessonAt!),
                      left: [
                        'Trước buổi học',
                        if (args.studentName.isNotEmpty) args.studentName,
                      ].join(' · '),
                      title: 'Chuẩn bị buổi học',
                    ),
                    const SizedBox(height: 16),
                    Padding(padding: TutorSurface.screenPadding, child: body),
                  ],
                ),
              ),
              if (hasPlan) const _BottomBar(),
            ],
          ),
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

/// Chân màn: mẹo ghi âm (bóng đèn), nút "Bắt đầu ghi âm", nhắc đồng ý.
class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      8,
      TutorSurface.gutter,
      14,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Mẹo ghi âm',
          child: InkWell(
            onTap: () => context.push(AppRoutes.tutorRecordingTips),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: TutorColors.ink,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Điện thoại giữa bàn · Không làm phiền · pin trên 30%',
                      style: TutorType.rowSub(color: TutorColors.ink),
                    ),
                  ),
                  const CanvasChevron(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CanvasCta(
          label: 'Bắt đầu ghi âm',
          icon: const Icon(Icons.mic_none_rounded, size: 18),
          onPressed: () => context.push(AppRoutes.tutorRecorder),
        ),
        const SizedBox(height: 10),
        Text(
          'Chỉ ghi âm khi phụ huynh đã đồng ý.',
          textAlign: TextAlign.center,
          style: TutorType.caption(color: TutorColors.ink3),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CanvasRow(
    onTap: onTap,
    lastRule: true,
    child: Text(text, style: TutorType.rowSub().copyWith(fontSize: 15)),
  );
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});

  final TopiPlan plan;

  static const _stepOrder = ['check', 'homework', 'memory', 'warmup'];

  @override
  Widget build(BuildContext context) {
    final gaps = [...plan.gaps];
    // Lỗ hổng đang luyện (thẻ sage) trước, rồi các lỗ hổng "tiếp theo"; lỗ
    // hổng "chỉ theo dõi" gom vào một mục thu gọn để màn không dài.
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
    final stepsTitle = total > 0 ? '$total phút đầu' : 'Đầu buổi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gaps.isNotEmpty) ...[
          if (shown.isNotEmpty) _FocusGapCard(gap: shown.first),
          if (shown.length > 1) ...[
            const SizedBox(height: 18),
            const _SectionHead('Lỗ hổng tiếp theo'),
            const SizedBox(height: 2),
            for (var i = 1; i < shown.length; i++)
              _GapRow(gap: shown[i], number: i + 1, first: i == 1),
          ],
          if (watched.isNotEmpty) ...[
            const SizedBox(height: 8),
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
          ],
          const SizedBox(height: 14),
          const CanvasTipBox(
            'Mỗi lần một lỗ hổng: lỗ hổng gặp nhiều nhất. Sửa một thói quen sai cần vài buổi.',
          ),
        ],
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionHead(stepsTitle),
          const SizedBox(height: 8),
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              step: steps[i],
              first: i == 0,
              last: i == steps.length - 1,
            ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CanvasHand(
                'Chỉ là gợi ý, cứ đổi tự do',
                size: 17,
                swash: false,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const CanvasTipBox(
            'Kiểm tra bằng bài mới, không gợi ý. Làm lại bài cũ không chứng minh gì vì học sinh đã thấy đáp án.',
          ),
        ],
      ],
    );
  }
}

/// Tiêu đề nhóm + nhãn "Nháp AI" bên phải (khối do Topi soạn).
class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: TutorType.sectionTitle())),
      const CanvasAiDraftTag(),
    ],
  );
}

String _roleLabel(String? role, int number) => switch (role) {
  'focus' => 'Lỗ hổng $number · luyện ngay',
  'next' => 'Lỗ hổng $number · tiếp theo',
  'watch' => 'Lỗ hổng $number · chỉ theo dõi',
  _ => 'Lỗ hổng $number',
};

/// Thẻ sage nổi: lỗ hổng số 1, Sai / Đúng trong ô sáng, số buổi đã gặp.
class _FocusGapCard extends StatelessWidget {
  const _FocusGapCard({required this.gap});

  final TopiGap gap;

  @override
  Widget build(BuildContext context) {
    final seen = (gap.seenInLessons ?? 0) > 0
        ? 'Gặp trong ${gap.seenInLessons} buổi'
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: TutorSurface.sage(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CanvasKicker(
                  _roleLabel(gap.role, 1),
                  color: TutorColors.ink,
                ),
              ),
              if (gap.level != null) ...[
                TopiLevelChip(level: gap.level!),
                const SizedBox(width: 8),
              ],
              const CanvasAiDraftTag(onSage: true),
            ],
          ),
          const SizedBox(height: 6),
          Text(gap.title ?? gap.node ?? '—', style: TutorType.body()),
          if (gap.wrong != null || gap.right != null) ...[
            const SizedBox(height: 10),
            _WrongRight(gap: gap, color: const Color(0xBFF8F7F4)),
          ],
          if (seen != null) ...[
            const SizedBox(height: 8),
            Text(seen, style: TutorType.caption(color: TutorColors.ink3)),
          ],
        ],
      ),
    );
  }
}

/// Lỗ hổng "tiếp theo": hàng kẻ mảnh, cùng nội dung nhưng phẳng.
class _GapRow extends StatelessWidget {
  const _GapRow({required this.gap, required this.number, required this.first});

  final TopiGap gap;
  final int number;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final seen = (gap.seenInLessons ?? 0) > 0
        ? 'Gặp trong ${gap.seenInLessons} buổi'
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(top: first ? BorderSide.none : TutorSurface.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: CanvasKicker(_roleLabel(gap.role, number))),
              if (gap.level != null) TopiLevelChip(level: gap.level!),
            ],
          ),
          const SizedBox(height: 4),
          Text(gap.title ?? gap.node ?? '—', style: TutorType.body()),
          if (gap.wrong != null || gap.right != null) ...[
            const SizedBox(height: 8),
            _WrongRight(gap: gap, color: TutorColors.surfaceSunken),
          ],
          if (seen != null) ...[
            const SizedBox(height: 6),
            Text(seen, style: TutorType.caption(color: TutorColors.ink3)),
          ],
        ],
      ),
    );
  }
}

/// "Sai: …" / "Đúng: …" trong ô sáng như canvas — chỉ mực, không đỏ/xanh.
class _WrongRight extends StatelessWidget {
  const _WrongRight({required this.gap, required this.color});

  final TopiGap gap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget line(String label, String text, {required bool strong}) => Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TutorType.rowSub(),
          ),
          TextSpan(
            text: topiMathText(text),
            style: TextStyle(
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
      style: TutorType.body().copyWith(fontSize: 13.5, height: 1.7),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gap.wrong != null) line('Sai:', gap.wrong!, strong: false),
          if (gap.right != null) line('Đúng:', gap.right!, strong: true),
        ],
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

/// Một bước đầu buổi trên đường thời gian: số phút · chấm · tên bước + câu hỏi.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.first, required this.last});

  final TopiStep step;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0x241F2A24);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                step.minutes == null ? '–' : '${step.minutes} phút',
                style: TutorType.rowSub(),
              ),
            ),
          ),
          SizedBox(
            width: 14,
            child: Column(
              children: [
                Container(
                  width: 1,
                  height: 12,
                  color: first ? Colors.transparent : lineColor,
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: first ? TutorColors.ink : const Color(0xFFA3A8A2),
                    boxShadow: const [
                      BoxShadow(color: TutorColors.bg, spreadRadius: 3),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: last ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_stepLabel(step.name), style: TutorType.body()),
                  for (final a in step.asks) ...[
                    const SizedBox(height: 4),
                    _AskBlock(ask: a),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: topiAskText(a.say!), style: TutorType.rowSub()),
              ],
            ),
          ),
        if (a.problem != null) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: TutorSurface.well(),
            child: Text(
              topiMathText(a.problem!),
              style: TutorType.rowTitle().copyWith(fontSize: 14.5),
            ),
          ),
        ],
        if (a.answer != null) ...[
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
                    style: TutorType.caption(
                      color: TutorColors.ink3,
                    ).copyWith(fontSize: 13),
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
                style: TutorType.rowTitle().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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

/// Dòng "Kế hoạch buổi sau · Chỉ bạn thấy" trên màn duyệt báo cáo (V56-Review),
/// mở Chuẩn bị buổi học. Ẩn khi cờ `plan` tắt hoặc buổi chưa có kế hoạch.
class TopiNextPlanRow extends ConsumerWidget {
  const TopiNextPlanRow({
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
    return Padding(
      padding: padding,
      child: CanvasRow(
        lastRule: true,
        onTap: () => TopiBeforeLessonScreen.open(context, args),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: TutorColors.ink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kế hoạch buổi sau', style: TutorType.rowTitle()),
                  const SizedBox(height: 2),
                  Text('Chỉ bạn thấy', style: TutorType.rowSub()),
                ],
              ),
            ),
            const CanvasChevron(),
          ],
        ),
      ),
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

    TopiGap? focus;
    for (final g in plan.gaps) {
      if (g.role == 'focus') focus = g;
    }
    focus ??= plan.gaps.firstOrNull;
    final head = focus == null
        ? 'Trước buổi học'
        : _roleLabel(focus.role == 'watch' ? null : focus.role, 1);
    final sub = [
      if ((focus?.seenInLessons ?? 0) > 0)
        'Gặp trong ${focus!.seenInLessons} buổi',
      if (args.nextLessonAt != null) 'Buổi tới ${_when(args.nextLessonAt!)}',
      if (focus == null && plan.steps.isNotEmpty)
        '${plan.steps.length} bước đầu buổi',
    ].join(' · ');

    // V5.6: thẻ sage nổi "Lỗ hổng 1 · luyện ngay" dẫn sang Chuẩn bị buổi học.
    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: TutorSurface.sage(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(TutorSurface.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => TopiBeforeLessonScreen.open(context, args),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CanvasKicker(head, color: TutorColors.ink),
                            ),
                            if (focus?.level != null) ...[
                              TopiLevelChip(level: focus!.level!),
                              const SizedBox(width: 8),
                            ],
                            const CanvasAiDraftTag(onSage: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          focus?.title ??
                              focus?.node ??
                              'Kế hoạch 15 phút đầu buổi',
                          style: TutorType.body(),
                        ),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sub, style: TutorType.rowSub()),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const CanvasChevron(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
