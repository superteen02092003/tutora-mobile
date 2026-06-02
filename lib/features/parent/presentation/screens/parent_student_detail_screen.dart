import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';

class ParentStudentDetailPage extends ConsumerStatefulWidget {
  const ParentStudentDetailPage({required this.studentId, super.key});
  final String studentId;

  @override
  ConsumerState<ParentStudentDetailPage> createState() =>
      _ParentStudentDetailPageState();
}

class _ParentStudentDetailPageState
    extends ConsumerState<ParentStudentDetailPage> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref
            .read(parentStudentBookingsProvider(widget.studentId).notifier)
            .load(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(parentStudentsProvider);
    final bookingsState = ref.watch(
      parentStudentBookingsProvider(widget.studentId),
    );

    final student = studentsState.students
        .where((s) => s.studentId == widget.studentId)
        .firstOrNull;

    final initials = (student?.fullName ?? '?')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          student?.fullName ?? 'Chi tiết học sinh',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppColors.ink,
        backgroundColor: AppColors.paper,
        onRefresh: () => ref
            .read(parentStudentBookingsProvider(widget.studentId).notifier)
            .load(),
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.fullName ?? '—',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (student?.gradeLevel != null)
                            _InfoChip(student!.gradeLevel!),
                          if (student?.school != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              student!.school!,
                              style: AppTextStyles.bodySmall(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const _SectionHeader('Lịch học đang có'),
            if (bookingsState.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.ink),
                ),
              )
            else if (bookingsState.bookings.isEmpty)
              const _EmptyState(
                icon: Icons.calendar_today_outlined,
                message: 'Chưa có lịch học nào đang hoạt động',
              )
            else
              ...bookingsState.bookings.map(
                (b) => _BookingCard(booking: b),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: AppColors.ink4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.ink4),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.bodySmall(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final ParentBookingDto booking;

  @override
  Widget build(BuildContext context) {
    final scheduleStr =
        booking.schedule?.map((s) => s.dayLabel).join(', ') ?? '';
    final timeStr = (booking.schedule?.isNotEmpty ?? false)
        ? '${booking.schedule!.first.startTime} – ${booking.schedule!.first.endTime}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.subjectName ?? 'Môn học',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _StatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            if (booking.tutorName != null)
              _InfoRow(
                icon: Icons.person_outline_rounded,
                text: 'Gia sư: ${booking.tutorName!}',
              ),
            if (scheduleStr.isNotEmpty)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: '$scheduleStr  $timeStr',
              ),
            if (booking.remainingSessions != null)
              _InfoRow(
                icon: Icons.confirmation_num_outlined,
                text: 'Còn ${booking.remainingSessions} buổi',
              ),
            if (booking.teachingMode != null)
              _InfoRow(
                icon: booking.teachingMode == 'online'
                    ? Icons.videocam_outlined
                    : Icons.location_on_outlined,
                text: booking.teachingMode == 'online' ? 'Online' : 'Offline',
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.ink4),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Đang học', AppColors.green),
      'accepted' => ('Đã duyệt', const Color(0xFF3D6EEA)),
      'pending_tutor' => ('Chờ duyệt', AppColors.gold),
      'completed' => ('Hoàn thành', AppColors.ink3),
      'cancelled' => ('Đã huỷ', AppColors.oxblood),
      _ => ('Không rõ', AppColors.ink4),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
