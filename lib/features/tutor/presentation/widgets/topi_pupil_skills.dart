import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_skills_section.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_ui.dart';

/// Kỹ năng của một học sinh trên hồ sơ (canvas V57-Pupil, V57-Levels,
/// V57-Skills; Khanh 2026-11-16): nút "?" giải thích bốn mức, thẻ tổng hợp
/// mọi kỹ năng đã thấy, dòng "Ôn lại để lên Vững", và màn danh sách theo mức.

int topiDots(TopiLevel l) => switch (l) {
  TopiLevel.toDo => 1,
  TopiLevel.improving => 2,
  TopiLevel.standard => 3,
  TopiLevel.mastered => 4,
};

/// Câu ngắn nói mức bằng lời (dùng cạnh chấm ở "Cần luyện tập").
String topiLevelPlain(TopiLevel l) => switch (l) {
  TopiLevel.toDo => 'còn làm sai',
  TopiLevel.improving => 'làm được khi có gợi ý',
  TopiLevel.standard => 'tự làm đúng',
  TopiLevel.mastered => 'vững sau nhiều tuần',
};

/// Tiêu chí của từng mức (skills-detector.md, bản nháp chưa kiểm chứng).
const _criteria = <TopiLevel, String>{
  TopiLevel.toDo: 'Đã gặp nhưng phần lớn làm sai, hoặc sai lặp lại ở 2 buổi.',
  TopiLevel.improving: 'Làm được khi có gợi ý, hoặc đúng phần lớn.',
  TopiLevel.standard:
      'Tự làm đúng 2 bài mới, không cần gợi ý, ở buổi sau buổi đã học.',
  TopiLevel.mastered:
      'Vẫn tự làm đúng khi kiểm tra lại sau ít nhất 3 tuần, trộn với bài khác.',
};

String _dm(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Bảng "4 mức kỹ năng" (V57-Levels), mở từ nút "?".
Future<void> showTopiLevelsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: TutorColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            18,
            TutorSurface.gutter,
            18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('4 mức kỹ năng', style: TutorType.sectionTitle()),
              const SizedBox(height: 4),
              Text(
                'AI đề xuất mức từ bản ghi; bạn xác nhận khi lên Chuẩn hoặc '
                'Vững.',
                style: TutorType.rowSub(),
              ),
              const SizedBox(height: 8),
              for (final l in TopiLevel.values)
                _SheetRow(
                  lead: CanvasSkillDots(level: topiDots(l)),
                  title: topiLevelLabel(l),
                  text: _criteria[l]!,
                ),
              const _SheetRow(
                lead: Text('★', style: TextStyle(fontSize: 16)),
                text:
                    'Mỗi lần lên một mức = 1 sao cho học sinh và cho bạn. Sai '
                    'ở lần kiểm tra sau thì xuống một mức; sao đã có vẫn giữ.',
              ),
              const SizedBox(height: 16),
              CanvasCta(
                label: 'Đã hiểu',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.lead, required this.text, this.title});

  final Widget lead;
  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: TutorColors.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Padding(padding: const EdgeInsets.only(top: 5), child: lead),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) Text(title!, style: TutorType.rowTitle()),
              Text(text, style: TutorType.rowSub()),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Nút "?" tròn: mở bảng giải thích bốn mức.
class TopiLevelsHelpButton extends StatelessWidget {
  const TopiLevelsHelpButton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Giải thích các mức kỹ năng',
    excludeSemantics: true,
    child: InkWell(
      onTap: () => unawaited(showTopiLevelsSheet(context)),
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F4),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF8A8F89), width: 1.4),
        ),
        child: Text(
          '?',
          style: TutorType.action(
            color: const Color(0xFF4A514C),
          ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

/// Thẻ kỹ năng trên hồ sơ: mọi kỹ năng đã thấy của học sinh (cần backend có
/// endpoint kỹ năng học sinh); chưa có thì quay về thẻ của buổi gần nhất.
class PupilSkillsCard extends ConsumerWidget {
  const PupilSkillsCard({
    required this.studentId,
    required this.studentName,
    this.fallbackLessonId,
    this.padding = const EdgeInsets.only(top: 16),
    super.key,
  });

  final String studentId;
  final String studentName;
  final String? fallbackLessonId;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(topiFlagsNowProvider).skills) {
      return const SizedBox.shrink();
    }
    final skills =
        ref.watch(pupilSkillsProvider(studentId)).valueOrNull ??
        const <TopiPupilSkill>[];
    if (skills.isEmpty) {
      final id = fallbackLessonId;
      if (id == null) return const SizedBox.shrink();
      return TopiSkillsSection(
        lessonId: id,
        title: 'Kỹ năng ở buổi gần nhất',
        padding: padding,
        showHelp: true,
      );
    }
    void open() => unawaited(
      TopiPupilSkillsScreen.open(context, studentId, studentName),
    );
    const order = [
      TopiLevel.mastered,
      TopiLevel.standard,
      TopiLevel.improving,
      TopiLevel.toDo,
    ];
    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: TutorSurface.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${skills.length} kỹ năng toán, tìm thấy trong các buổi',
                    style: TutorType.caption(color: TutorColors.ink3),
                  ),
                ),
                const TopiLevelsHelpButton(),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 14) / 2;
                return Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final l in order)
                      SizedBox(
                        width: w,
                        child: InkWell(
                          onTap: open,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CanvasSkillDots(level: topiDots(l)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${topiLevelLabel(l)} · '
                                    '${skills.where((s) => s.level == l).length}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TutorType.rowSub(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: open,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Xem cả ${skills.length} kỹ năng →',
                  style: TutorType.rowSub(color: TutorColors.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dòng "Ôn lại để lên Vững" dưới "Cần luyện tập": số kỹ năng Chuẩn đã đến
/// hạn kiểm tra lại. Ẩn khi học sinh chưa có kỹ năng Chuẩn.
class PupilReviewRow extends ConsumerWidget {
  const PupilReviewRow({
    required this.studentId,
    required this.studentName,
    super.key,
  });

  final String studentId;
  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills =
        ref.watch(pupilSkillsProvider(studentId)).valueOrNull ??
        const <TopiPupilSkill>[];
    final standard = skills
        .where((s) => s.level == TopiLevel.standard)
        .toList();
    if (standard.isEmpty) return const SizedBox.shrink();
    final due = standard.where((s) => s.reviewDue(DateTime.now())).length;
    return CanvasRow(
      onTap: () => unawaited(
        TopiPupilSkillsScreen.open(context, studentId, studentName),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ôn lại để lên Vững', style: TutorType.body()),
                Text(
                  due == 0
                      ? '${standard.length} kỹ năng Chuẩn, chưa đến hạn kiểm tra lại'
                      : '$due trong ${standard.length} kỹ năng Chuẩn đến hạn '
                            'kiểm tra lại',
                  style: TutorType.rowSub(),
                ),
              ],
            ),
          ),
          const CanvasChevron(),
        ],
      ),
    );
  }
}

/// Màn "N kỹ năng toán" (V57-Skills): mọi kỹ năng theo nhóm Cần luyện tập ·
/// Chuẩn (kèm ngày ôn lại) · Vững.
class TopiPupilSkillsScreen extends ConsumerWidget {
  const TopiPupilSkillsScreen({
    required this.studentId,
    required this.studentName,
    super.key,
  });

  final String studentId;
  final String studentName;

  static Future<void> open(
    BuildContext context,
    String studentId,
    String studentName,
  ) => Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => TopiPupilSkillsScreen(
        studentId: studentId,
        studentName: studentName,
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills =
        ref.watch(pupilSkillsProvider(studentId)).valueOrNull ??
        const <TopiPupilSkill>[];
    final today = DateTime.now();
    final practise =
        skills
            .where(
              (s) =>
                  s.level == TopiLevel.toDo || s.level == TopiLevel.improving,
            )
            .toList()
          ..sort((a, b) => b.level.index.compareTo(a.level.index));
    final standard = skills.where((s) => s.level == TopiLevel.standard).toList()
      ..sort(
        (a, b) => (a.reviewFrom ?? today).compareTo(b.reviewFrom ?? today),
      );
    final mastered = skills
        .where((s) => s.level == TopiLevel.mastered)
        .toList();

    String name(TopiPupilSkill s) => s.name ?? s.node;
    String seen(TopiPupilSkill s) =>
        s.lessonsSeen > 0 ? 'Gặp ${s.lessonsSeen} buổi · ' : '';

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TutorSurface.gutter,
              16,
              TutorSurface.gutter,
              32,
            ),
            children: [
              Row(
                children: [
                  CanvasBackButton(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const TopiLevelsHelpButton(),
                ],
              ),
              const SizedBox(height: 14),
              Text(studentName, style: TutorType.caption()),
              const SizedBox(height: 4),
              Text(
                '${skills.length} kỹ năng toán',
                style: TutorType.display(size: 26),
              ),
              const SizedBox(height: 4),
              Text(
                'Tìm thấy trong các buổi đã ghi âm.',
                style: TutorType.rowSub(),
              ),
              if (practise.isNotEmpty) ...[
                _Group('Cần luyện tập · ${practise.length}'),
                for (final s in practise)
                  _SkillLine(
                    title: name(s),
                    sub: '${seen(s)}${topiLevelPlain(s.level)}',
                    level: s.level,
                  ),
              ],
              if (standard.isNotEmpty) ...[
                _Group('Chuẩn · ${standard.length} · ôn lại để lên Vững'),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: TutorSurface.sage(),
                  child: Text(
                    'Gợi ý: mỗi buổi cho 1 bài trộn của kỹ năng đến hạn. Đúng '
                    'không cần gợi ý → Vững, thêm 1 sao.',
                    style: TutorType.rowSub(color: TutorColors.ink),
                  ),
                ),
                for (final s in standard)
                  _SkillLine(
                    title: name(s),
                    sub: s.reviewFrom == null
                        ? 'Chuẩn'
                        : s.reviewDue(today)
                        ? 'Đến hạn kiểm tra lại'
                        : 'Kiểm tra lại từ ${_dm(s.reviewFrom!)}',
                    level: s.level,
                  ),
              ],
              if (mastered.isNotEmpty) ...[
                _Group('Vững · ${mastered.length}'),
                for (final s in mastered)
                  _SkillLine(
                    title: name(s),
                    sub: s.lastChange == null
                        ? 'Vững'
                        : 'Vững từ ${_dm(s.lastChange!)}',
                    level: s.level,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 2),
    child: CanvasKicker(text, color: TutorColors.ink),
  );
}

class _SkillLine extends StatelessWidget {
  const _SkillLine({
    required this.title,
    required this.sub,
    required this.level,
  });

  final String title;
  final String sub;
  final TopiLevel level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: TutorColors.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TutorType.body()),
              Text(sub, style: TutorType.rowSub()),
            ],
          ),
        ),
        const SizedBox(width: 10),
        CanvasSkillDots(level: topiDots(level)),
        const SizedBox(width: 6),
        Text(
          topiLevelLabel(level),
          style: TutorType.caption(color: const Color(0xFF4A514C)),
        ),
      ],
    ),
  );
}
