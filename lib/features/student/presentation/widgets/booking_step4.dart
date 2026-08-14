import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_month_preview.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

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
    'online' => 'Học Online',
    'offline' => 'Học tại nhà',
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
    final totalH = form.totalHours;
    final estimate = rate * totalH;
    final fee = estimate * 0.05;
    final total = estimate + fee;

    final isPackage = form.bookingMode == BookingMode.package;
    final sessionsPerMonth = form.totalSessions;

    final subject = (profile.subjects ?? [])
        .cast<TutorDetailSubjectDto?>()
        .firstWhere((s) => s?.subjectId == form.subjectId, orElse: () => null);
    final student = students.cast<StudentSummaryDto?>().firstWhere(
      (s) => s?.studentId == form.studentId,
      orElse: () => null,
    );
    final startDate = DateTime.tryParse(form.startDate) ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TutorHeader(profile: profile, subjectName: subject?.subjectName),

        const SizedBox(height: 20),
        const BookingSectionTitle('Chi tiết lớp học'),
        const SizedBox(height: 10),
        _Card(
          children: [
            if (student != null) BookingReviewRow('Học sinh', student.fullName),
            BookingReviewRow('Môn học', subject?.subjectName ?? '—'),
            BookingReviewRow('Hình thức', _modeName),
            BookingReviewRow(
              'Cách đặt',
              isPackage ? 'Gói cố định của gia sư' : 'Tự chọn lịch',
            ),
            if (isPackage && form.selectedPackage != null)
              BookingReviewRow(
                'Tên gói',
                form.selectedPackage!.name?.trim().isNotEmpty ?? false
                    ? form.selectedPackage!.name!.trim()
                    : 'Gói cố định',
              ),
            if (form.needsLocation && _locationText.isNotEmpty)
              BookingReviewRow('Địa điểm', _locationText),
            BookingReviewRow(
              'Ngày bắt đầu',
              DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(startDate),
            ),
            BookingReviewRow(
              'Học đến',
              DateFormat(
                'dd/MM/yyyy',
              ).format(bookingWindowEnd(startDate)),
            ),
            BookingReviewRow(
              'Thời lượng',
              '${_hoursLabel(form.slotDurationHours)} mỗi buổi',
            ),
          ],
        ),

        const SizedBox(height: 20),
        const BookingSectionTitle('Lịch học hàng tuần'),
        const SizedBox(height: 10),
        _Card(
          children: [
            for (var i = 0; i < form.schedule.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: AppColors.line),
              _SessionRow(slot: form.schedule[i]),
            ],
          ],
        ),

        const SizedBox(height: 20),
        const BookingSectionTitle('Các buổi sẽ học'),
        const SizedBox(height: 10),
        BookingMonthPreview(
          startDate: form.startDate,
          schedule: form.schedule,
        ),

        const SizedBox(height: 20),
        const BookingSectionTitle('Chi phí dự tính'),
        const SizedBox(height: 10),
        _Card(
          children: [
            BookingPriceRow('Tổng số buổi', '$sessionsPerMonth buổi'),
            const SizedBox(height: 10),
            BookingPriceRow('Tổng giờ học', '${totalH.toStringAsFixed(1)} giờ'),
            const SizedBox(height: 10),
            BookingPriceRow(
              'Học phí (${formatPrice(rate)}/giờ)',
              formatPrice(estimate),
            ),
            const SizedBox(height: 10),
            BookingPriceRow('Phí dịch vụ (5%)', formatPrice(fee)),
            const Divider(height: 22, color: AppColors.line),
            BookingPriceRow('Tổng cộng', formatPrice(total), bold: true),
          ],
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.ink2,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bạn chỉ trả tiền buổi đầu trước. Phần còn lại thanh toán sau '
                  'khi buổi 1 kết thúc, tiền được giữ tại Tutora Escrow.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.ink2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _hoursLabel(double h) =>
    h == h.truncateToDouble() ? '${h.toInt()} giờ' : '$h giờ';

class _TutorHeader extends StatelessWidget {
  const _TutorHeader({required this.profile, required this.subjectName});

  final TutorFullProfileDto profile;
  final String? subjectName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      children: [
        UserAvatar(
          name: profile.displayName,
          size: 56,
          imageUrl: profile.avatarUrl,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subjectName != null
                    ? 'Gia sư $subjectName của bạn'
                    : 'Gia sư của bạn',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
              ),
              const SizedBox(height: 2),
              Text(
                profile.displayName,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (profile.totalFeedbacks > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.averageRating.toStringAsFixed(1)} '
                      '(${profile.totalFeedbacks} đánh giá)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.slot});
  final ScheduleSlotDto slot;

  @override
  Widget build(BuildContext context) {
    final part = DayPartX.of(slot.startTime);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cream2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              kDayNames[slot.dayOfWeek],
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kDayNamesLong[slot.dayOfWeek],
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${slot.startTime} – ${slot.endTime} · ${part.label}',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
