import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/course_renew.dart';

/// Tab "Học sinh" (V5.6, canvas V56-Classes): mọi học sinh gia sư tự thêm,
/// học 1-1. Thẻ hai cột; bấm vào mở hồ sơ, "+ Thêm" mở form thêm học sinh.
class TutorStudentsScreen extends ConsumerWidget {
  const TutorStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recorderStudentsProvider);
    final students = async.valueOrNull ?? const <RecorderStudentDto>[];
    final loading = async.isLoading && async.valueOrNull == null;
    // Học sinh đã hết khóa lên đầu, kèm khối gia hạn tháng mới.
    final ended = students
        .where((s) => s.courseStatus() == CourseStatus.ended)
        .toList();
    final learning = students
        .where((s) => s.courseStatus() != CourseStatus.ended)
        .toList();

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () => ref.refresh(recorderStudentsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                TutorSurface.gutter,
                22,
                TutorSurface.gutter,
                32,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Học sinh', style: TutorType.screenTitle()),
                          const SizedBox(height: 4),
                          Text(
                            loading
                                ? 'Đang tải…'
                                : '${students.length} em · học 1-1',
                            style: TutorType.rowSub(),
                          ),
                        ],
                      ),
                    ),
                    _AddChip(
                      onTap: () =>
                          unawaited(TutorStudentFormScreen.open(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!loading && students.isEmpty)
                  _Empty(
                    onAdd: () =>
                        unawaited(TutorStudentFormScreen.open(context)),
                  )
                else ...[
                  if (ended.isNotEmpty) ...[
                    Text(
                      'Hết khóa · ${ended.length}',
                      style: TutorType.kicker(),
                    ),
                    const SizedBox(height: 8),
                    for (final s in ended) ...[
                      _EndedCard(student: s),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (learning.isNotEmpty) ...[
                    Text('Đang học', style: TutorType.kicker()),
                    const SizedBox(height: 8),
                    _Grid(students: learning),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: TutorColors.surface,
    shape: const StadiumBorder(),
    elevation: 1,
    shadowColor: const Color(0x331F2A24),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: TutorColors.ink),
            const SizedBox(width: 4),
            Text('Thêm', style: TutorType.action()),
          ],
        ),
      ),
    ),
  );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.students});

  final List<RecorderStudentDto> students;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in students)
              SizedBox(
                width: w,
                child: _StudentCard(student: s),
              ),
          ],
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final RecorderStudentDto student;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return DecoratedBox(
      decoration: TutorSurface.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TutorSurface.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              unawaited(TutorStudentDetailScreen.open(context, s.studentId)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TutorType.body(),
                ),
                if (s.subtitle.isNotEmpty)
                  Text(
                    s.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.rowSub(),
                  ),
                const SizedBox(height: 10),
                Text(
                  s.lessonCount == 0
                      ? 'Chưa có buổi ghi âm'
                      : '${s.lessonCount} buổi đã ghi',
                  style: TutorType.caption(),
                ),
                const SizedBox(height: 6),
                CourseStatusLabel(student: s),
                if (!s.hasConsent) ...[
                  const SizedBox(height: 6),
                  const CanvasTag('Chờ phụ huynh đồng ý'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Học sinh đã hết khóa: tên (bấm mở hồ sơ) + khối gia hạn tháng mới.
class _EndedCard extends StatelessWidget {
  const _EndedCard({required this.student});

  final RecorderStudentDto student;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return DecoratedBox(
      decoration: TutorSurface.card(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => unawaited(
                TutorStudentDetailScreen.open(context, s.studentId),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.fullName, style: TutorType.body()),
                          if (s.subtitle.isNotEmpty)
                            Text(s.subtitle, style: TutorType.rowSub()),
                        ],
                      ),
                    ),
                    CourseStatusLabel(student: s),
                    const SizedBox(width: 4),
                    const CanvasChevron(),
                  ],
                ),
              ),
            ),
            CourseRenewPanel(student: s),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(
      children: [
        const CanvasHand('Bắt đầu với em đầu tiên'),
        const SizedBox(height: 18),
        Text('Chưa có học sinh', style: TutorType.sectionTitle()),
        const SizedBox(height: 6),
        Text(
          'Thêm học sinh để ghi âm và gửi báo cáo cho phụ huynh.',
          textAlign: TextAlign.center,
          style: TutorType.rowSub(),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 200,
          child: CanvasCta(
            label: '+ Thêm học sinh',
            onPressed: onAdd,
            secondary: true,
          ),
        ),
      ],
    ),
  );
}
