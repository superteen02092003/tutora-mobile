import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_booking_detail_screen.dart';
import 'package:tutora/shared/widgets/status_chip.dart';

const _kStatusFilters = <(String, String?)>[
  ('Tất cả', null),
  ('Sắp diễn ra', 'scheduled'),
  ('Đang dạy', 'inprogress'),
  ('Hoàn thành', 'completed'),
  ('Đã huỷ', 'cancelled'),
];

class TutorClassesScreen extends ConsumerStatefulWidget {
  const TutorClassesScreen({super.key});

  @override
  ConsumerState<TutorClassesScreen> createState() => _TutorClassesScreenState();
}

class _TutorClassesScreenState extends ConsumerState<TutorClassesScreen> {
  String? _filterStatus;
  DateTime? _filterDate;

  List<TutorLessonDto> _apply(List<TutorLessonDto> all) {
    var list = all;
    if (_filterStatus != null) {
      list = list
          .where((l) => l.status.toLowerCase() == _filterStatus)
          .toList();
    }
    if (_filterDate != null) {
      list = list.where((l) => l.isSameDay(_filterDate!)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorLessonListProvider);
    final lessons = _apply(state.lessons);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Buổi học', style: AppTextStyles.h2()),
                  ),
                  GestureDetector(
                    onTap: _filterDate != null
                        ? () => setState(() => _filterDate = null)
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2027),
                            );
                            if (picked != null) {
                              setState(() => _filterDate = picked);
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _filterDate != null
                            ? AppColors.ink
                            : AppColors.cream2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterDate != null
                                ? Icons.close_rounded
                                : Icons.calendar_today_rounded,
                            size: 14,
                            color: _filterDate != null
                                ? AppColors.cream
                                : AppColors.ink3,
                          ),
                          if (_filterDate != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${_filterDate!.day}/${_filterDate!.month}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cream,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _kStatusFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final (label, status) = _kStatusFilters[i];
                  final active = _filterStatus == status;
                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = status),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : AppColors.cream2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.cream : AppColors.ink3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Body
            if (state.isLoading && state.lessons.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(tutorLessonListProvider.notifier).load(),
                  child: lessons.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: Text(
                                  'Không có buổi học nào',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.ink4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            bottomPad + AppSpacing.xxl,
                          ),
                          itemCount: lessons.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _LessonCard(lesson: lessons[i]),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});
  final TutorLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipTone) = lessonChip(lesson.status);
    final dt = lesson.startDt;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorBookingDetailScreen(lesson: lesson),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dt != null ? '${dt.day}' : '—',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                  Text(
                    dt != null ? 'Thg${dt.month}' : '',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      color: AppColors.ink4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.studentName,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      lesson.subjectName,
                      '${lesson.timeStart}–${lesson.timeEnd}',
                      // Buổi phụ / buổi học lại
                      ?lesson.linkLabel,
                    ].join(' · '),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.ink4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(label: chipLabel, tone: chipTone),
          ],
        ),
      ),
    );
  }
}
