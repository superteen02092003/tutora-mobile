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
import 'package:tutora/features/tutor/presentation/widgets/topi_math_text.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

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
        child: Column(
          children: [
            const TutorChildHeader(title: 'Trước buổi học'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  4,
                  TutorSurface.gutter,
                  40,
                ),
                children: [
                  _Header(
                    name: args.studentName,
                    when: args.nextLessonAt,
                  ),
                  const SizedBox(height: 20),
                  body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];

String _when(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${_weekdays[d.weekday - 1]}, ${two(d.hour)}:${two(d.minute)} · '
      '${two(d.day)}/${two(d.month)}';
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.when});

  final String name;
  final DateTime? when;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: TutorColors.surfaceSunken,
          shape: BoxShape.circle,
        ),
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TutorType.rowTitle(),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? 'Học sinh' : name,
              style: TutorType.rowTitle(),
            ),
            const SizedBox(height: 2),
            Text(
              when == null ? 'Buổi tới' : 'Buổi tới · ${_when(when!)}',
              style: TutorType.rowSub(),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TutorCard(
    onTap: onTap,
    child: Text(text, style: TutorType.rowSub()),
  );
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});

  final TopiPlan plan;

  static const _stepOrder = ['check', 'homework', 'memory', 'warmup'];

  @override
  Widget build(BuildContext context) {
    final gaps = plan.gaps;
    final steps = [...plan.steps]
      ..sort((a, b) {
        int i(TopiStep s) {
          final k = _stepOrder.indexOf(s.name.replaceAll(RegExp('[-_ ]'), ''));
          return k < 0 ? _stepOrder.length : k;
        }

        return i(a).compareTo(i(b));
      });
    final total = steps.fold<int>(0, (s, x) => s + (x.minutes ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gaps.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${gaps.length}',
                style: TutorType.numeralLarge().copyWith(fontSize: 44),
              ),
              const SizedBox(width: 8),
              Text(
                'lỗ hổng',
                style: TutorType.screenTitle().copyWith(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Đã thấy trong các buổi trước. Mỗi lỗ hổng được luyện qua vài '
            'buổi, không sửa xong trong một buổi.',
            style: TutorType.rowSub(),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < gaps.length; i++) ...[
            _GapCard(gap: gaps[i], number: i + 1),
            const SizedBox(height: TutorSurface.rowGap),
          ],
          const SizedBox(height: 8),
        ],
        const TopiInfoBox(
          title: 'Kiểm tra trước, bằng bài mới',
          text:
              'Cho học sinh làm bài mới trước khi luyện, không gợi ý. Làm lại '
              'bài cũ không chứng minh gì vì học sinh đã thấy đáp án.',
        ),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: TutorSurface.sectionGap),
          Row(
            children: [
              Expanded(
                child: Text(
                  total > 0 ? '$total phút đầu buổi' : 'Đầu buổi',
                  style: TutorType.sectionTitle(),
                ),
              ),
              Text('${steps.length} bước', style: TutorType.caption()),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++) ...[
            _StepCard(step: steps[i], number: i + 1),
            const SizedBox(height: TutorSurface.rowGap),
          ],
        ],
      ],
    );
  }
}

(String, Color) _role(String? role) => switch (role) {
  'focus' => ('Đang tập trung', TutorColors.primary),
  'next' => ('Tiếp theo', TutorColors.warning),
  'watch' => ('Theo dõi', TutorColors.ink3),
  _ => ('', TutorColors.ink3),
};

class _GapCard extends StatelessWidget {
  const _GapCard({required this.gap, required this.number});

  final TopiGap gap;
  final int number;

  @override
  Widget build(BuildContext context) {
    final (roleLabel, roleColor) = _role(gap.role);
    return TutorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lỗ hổng $number',
                  style: TutorType.caption(
                    color: TutorColors.ink3,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ),
              if (gap.level != null) ...[
                TopiLevelChip(level: gap.level!),
                const SizedBox(width: 6),
              ],
              if (roleLabel.isNotEmpty)
                TopiChip(label: roleLabel, color: roleColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(gap.title ?? gap.node ?? '—', style: TutorType.rowTitle()),
          if (gap.title != null && gap.node != null) ...[
            const SizedBox(height: 2),
            Text(gap.node!, style: TutorType.caption()),
          ],
          if (gap.wrong != null) ...[
            const SizedBox(height: 10),
            _Line(
              icon: Icons.close_rounded,
              label: 'Sai',
              color: TopiLevelColors.toDo,
              text: gap.wrong!,
            ),
          ],
          if (gap.right != null) ...[
            const SizedBox(height: 6),
            _Line(
              icon: Icons.check_rounded,
              label: 'Đúng',
              color: TopiLevelColors.standard,
              text: gap.right!,
            ),
          ],
          if ((gap.seenInLessons ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Đã gặp trong ${gap.seenInLessons} buổi',
              style: TutorType.caption(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.label,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: TutorType.caption(
              color: color,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TutorType.rowTitle().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

String _stepLabel(String name) =>
    switch (name.replaceAll(RegExp('[-_ ]'), '')) {
      'check' => 'Kiểm tra',
      'homework' => 'Bài về nhà',
      'memory' => 'Nhớ lại, gấp vở',
      'warmup' => 'Khởi động',
      _ => name,
    };

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.number});

  final TopiStep step;
  final int number;

  @override
  Widget build(BuildContext context) => TutorCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: TutorColors.ink,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: TutorType.caption(
                  color: TutorColors.surface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_stepLabel(step.name), style: TutorType.rowTitle()),
            ),
            if (step.minutes != null)
              TutorStatusChip.neutral(
                '${step.minutes} phút',
                icon: Icons.schedule_rounded,
              ),
          ],
        ),
        for (final a in step.asks) ...[
          const SizedBox(height: 10),
          _AskBlock(ask: a),
        ],
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
      if (plan.gaps.isNotEmpty) '${plan.gaps.length} lỗ hổng',
      if (plan.steps.isNotEmpty) '${plan.steps.length} bước đầu buổi',
    ];
    return Padding(
      padding: padding,
      child: TutorCard(
        onTap: () => TopiBeforeLessonScreen.open(context, args),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: TutorColors.accentBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 19,
                color: TutorColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trước buổi học', style: TutorType.rowTitle()),
                  const SizedBox(height: 2),
                  Text(parts.join(' · '), style: TutorType.rowSub()),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: TutorColors.ink4,
            ),
          ],
        ),
      ),
    );
  }
}
