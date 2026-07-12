import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class BookingStep1 extends StatelessWidget {
  const BookingStep1({
    required this.form,
    required this.profile,
    required this.students,
    required this.loadingStudents,
    required this.userRole,
    required this.onChanged,
    super.key,
  });

  final BookingForm form;
  final TutorFullProfileDto profile;
  final List<StudentSummaryDto> students;
  final bool loadingStudents;
  final String userRole;
  final ValueChanged<BookingForm> onChanged;

  BookingForm _selectSubject(int subjectId) {
    final prices = profile.subjectGradePrices ?? [];
    final forSubject = prices.where((p) => p.subjectId == subjectId).toList();

    SubjectGradePriceDto? match;
    final student = students.where((s) => s.studentId == form.studentId);
    final gradeName = student.isEmpty ? null : student.first.displayGrade;
    if (gradeName != null && gradeName.isNotEmpty) {
      for (final p in forSubject) {
        if (p.gradeLevelName == gradeName) {
          match = p;
          break;
        }
      }
    }
    match ??= forSubject.isNotEmpty ? forSubject.first : null;

    final duration = match?.durationMinutesPerSession;
    return form.copyWith(
      subjectId: subjectId,
      tutorSubjectGradePriceId: match?.id ?? 0,
      selectedGradePrice: match,
      slotDurationHours: duration != null ? duration / 60.0 : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = profile.subjects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (userRole == 'Parent') ...[
          const BookingSectionTitle('Chọn học sinh'),
          const SizedBox(height: 8),
          if (loadingStudents)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Chưa có hồ sơ học sinh.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
              ),
            )
          else
            ...students.map((s) {
              final selected = form.studentId == s.studentId;
              return GestureDetector(
                onTap: () => onChanged(form.copyWith(studentId: s.studentId)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ink.withValues(alpha: 0.04)
                        : AppColors.paper,
                    border: Border.all(
                      color: selected ? AppColors.ink : AppColors.line,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: s.fullName,
                        size: 40,
                        imageUrl: s.avatarUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.fullName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
                            if (s.displayGrade.isNotEmpty)
                              Text(
                                s.displayGrade,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.ink3,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: AppColors.ink,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
        ],
        const BookingSectionTitle('Chọn môn học'),
        const SizedBox(height: 8),
        if (subjects.isEmpty)
          Text(
            'Gia sư chưa cập nhật môn học.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((s) {
              final sid = s.subjectId ?? 0;
              final selected = form.subjectId == sid;
              return GestureDetector(
                onTap: () => onChanged(_selectSubject(sid)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : AppColors.paper,
                    border: Border.all(
                      color: selected ? AppColors.ink : AppColors.line,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    s.subjectName ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.gold : AppColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
