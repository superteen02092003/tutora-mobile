import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

class BookingStep4 extends StatelessWidget {
  const BookingStep4({
    required this.form,
    required this.profile,
    required this.students,
    super.key,
  });

  final BookingForm form;
  final TutorFullProfileDto profile;
  final List<StudentSummaryDto> students;

  String get _modeName => switch (form.teachingMode) {
    'online' => 'Online',
    'offline' => 'Tại nhà',
    _ => 'Kết hợp',
  };

  String get _locationText => [
    form.locationDetail,
    form.locationWard,
    form.locationDistrict,
    form.locationCity,
  ].where((s) => s.isNotEmpty).join(', ');

  @override
  Widget build(BuildContext context) {
    final rate = profile.lowestPrice;
    final totalH = form.totalHoursPerMonth;
    final estimate = rate * totalH;
    final fee = estimate * 0.05;
    final total = estimate + fee;

    final subject = (profile.subjects ?? [])
        .cast<TutorDetailSubjectDto?>()
        .firstWhere(
          (s) => s?.subjectId == form.subjectId,
          orElse: () => null,
        );
    final student = students.cast<StudentSummaryDto?>().firstWhere(
      (s) => s?.studentId == form.studentId,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookingSectionTitle('Tóm tắt đặt lịch'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              if (student != null)
                BookingReviewRow('Học sinh', student.fullName),
              BookingReviewRow('Môn học', subject?.subjectName ?? '—'),
              BookingReviewRow('Hình thức', _modeName),
              if (form.needsLocation && _locationText.isNotEmpty)
                BookingReviewRow('Địa điểm', _locationText),
              BookingReviewRow(
                'Ngày bắt đầu',
                DateFormat(
                  'dd/MM/yyyy',
                ).format(DateTime.tryParse(form.startDate) ?? DateTime.now()),
              ),
              BookingReviewRow(
                'Số buổi/tháng',
                '${form.schedule.length * 4} buổi',
              ),
              BookingReviewRow(
                'Tổng giờ/tháng',
                '${totalH.toStringAsFixed(1)} giờ',
              ),
              const Divider(height: 16, color: AppColors.line),
              ...form.schedule.map(
                (s) => BookingReviewRow(
                  kDayNamesLong[s.dayOfWeek],
                  '${s.startTime} – ${s.endTime}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const BookingSectionTitle('Dự tính chi phí'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              BookingPriceRow(
                'Học phí (${totalH.toStringAsFixed(1)}h × ${formatPrice(rate)}/h)',
                formatPrice(estimate),
              ),
              BookingPriceRow('Phí dịch vụ (5%)', formatPrice(fee)),
              const Divider(height: 16, color: AppColors.line),
              BookingPriceRow(
                'Dự kiến thanh toán',
                formatPrice(total),
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            '💡 Giá ước tính. Giá cuối cùng được tính bởi hệ thống và thanh toán qua Tutora Escrow.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
