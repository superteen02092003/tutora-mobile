import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/data/datasources/class_session_datasource.dart';
import 'package:tutora/features/student/data/models/lesson_models.dart';
import 'package:tutora/features/student/presentation/providers/class_provider.dart';
import 'package:tutora/features/student/presentation/providers/lesson_provider.dart';
import 'package:tutora/features/student/presentation/screens/session_recording_player_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_class_detail_screen.dart';
import 'package:tutora/features/student/presentation/widgets/class_widgets.dart';
import 'package:tutora/features/student/presentation/widgets/reschedule_sheet.dart';
import 'package:tutora/shared/datasources/class_interaction_datasource.dart';
import 'package:tutora/shared/live_session/live_session_call_screen.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:tutora/shared/widgets/class_interaction_sheets.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';

/// Chi tiết một buổi học.
class StudentSessionDetailPage extends ConsumerWidget {
  const StudentSessionDetailPage({required this.lessonId, super.key});
  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lessonDetailProvider(lessonId));
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Column(
            children: [
              _NavBar(title: 'Buổi học'),
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          ),
          error: (e, _) => Column(
            children: [
              const _NavBar(title: 'Buổi học'),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Không tải được buổi học',
                          style: AppTextStyles.label(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          style: AppTextStyles.bodySmall(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 140,
                          child: PrimaryButton(
                            label: 'Thử lại',
                            color: AppColors.ink,
                            fg: AppColors.cream,
                            onTap: () =>
                                ref.invalidate(lessonDetailProvider(lessonId)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (lesson) => _DetailBody(lesson: lesson),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.lesson});
  final StudentLessonDetailDto lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final status = lesson.statusType;
    final isDone = status == LessonStatusType.done;
    final isPending = status == LessonStatusType.pending;
    final isCancelled = status == LessonStatusType.cancelled;

    return Column(
      children: [
        _NavBar(
          title: isDone
              ? 'Tổng kết buổi học'
              : isPending
              ? 'Xác nhận buổi học'
              : 'Chi tiết buổi học',
          bookingId: lesson.bookingId,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(lessonDetailProvider(lesson.lessonId)),
            color: AppColors.oxblood,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomInset + 100),
              children: [
                _HeroCard(lesson: lesson),
                // Đề xuất đổi lịch chỉ còn ý nghĩa với buổi chưa diễn ra; buổi
                // đã học xong hoặc đã hủy thì không hiện để phản hồi nữa.
                if ((lesson.pendingReschedule?.isPending ?? false) &&
                    lesson.statusType == LessonStatusType.scheduled)
                  _RescheduleCard(proposal: lesson.pendingReschedule!),
                if (lesson.requiresRemainingPayment) const _PaymentLockCard(),
                _TutorCard(lesson: lesson),
                _DetailsCard(lesson: lesson),
                if (lesson.report != null) _ReportCard(report: lesson.report!),
                if (isDone || isPending)
                  _RecordingCard(lessonId: lesson.lessonId),
                if (isCancelled) const _CancelledNote(),
              ],
            ),
          ),
        ),
        _ActionBar(lesson: lesson, bottomInset: bottomInset),
      ],
    );
  }
}

// Nav bar

class _NavBar extends StatelessWidget {
  const _NavBar({required this.title, this.bookingId});
  final String title;
  final int? bookingId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSerif(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (bookingId != null)
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudentClassDetailPage(bookingId: bookingId!),
                ),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  size: 15,
                  color: AppColors.ink,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// Hero card — trạng thái + đếm ngược

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.lesson});
  final StudentLessonDetailDto lesson;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  Timer? _ticker;

  StudentLessonDetailDto get lesson => widget.lesson;

  @override
  void initState() {
    super.initState();
    // Đếm ngược tới giờ học / tới hạn xác nhận cần cập nhật mỗi phút.
    if (lesson.statusType == LessonStatusType.scheduled ||
        lesson.statusType == LessonStatusType.pending) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, detail) = _copy();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1.1),
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (lesson.statusType == LessonStatusType.inProgress)
                    const _PulseDot(color: AppColors.gold)
                  else
                    Icon(_heroIcon, size: 13, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: AppTextStyles.eyebrow(color: AppColors.gold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lesson.subjectName ?? 'Buổi học',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.1,
                  color: AppColors.cream,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.cream.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _HeroStat(
                    icon: Icons.calendar_today_rounded,
                    value: DateFormat('dd/MM').format(lesson.startDt),
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.schedule_rounded,
                    value: lesson.timeRange,
                  ),
                  if (lesson.actualMinutes != null) ...[
                    const SizedBox(width: 8),
                    _HeroStat(
                      icon: Icons.timelapse_rounded,
                      value: '${lesson.actualMinutes} phút',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _heroIcon => switch (lesson.statusType) {
    LessonStatusType.done => Icons.check_circle_rounded,
    LessonStatusType.pending => Icons.pending_actions_rounded,
    LessonStatusType.cancelled => Icons.cancel_outlined,
    _ => Icons.event_available_rounded,
  };

  (String, String) _copy() {
    switch (lesson.statusType) {
      case LessonStatusType.inProgress:
        return (
          'Đang diễn ra',
          'Buổi học đang diễn ra — vào phòng để tiếp tục.',
        );
      case LessonStatusType.pending:
        final deadline = lesson.confirmDeadlineDt;
        final left = deadline?.difference(DateTime.now());
        if (left != null && !left.isNegative) {
          return (
            'Chờ bạn xác nhận',
            'Gia sư đã gửi báo cáo. Xác nhận trong ${_humanDuration(left)} nữa, '
                'nếu không hệ thống sẽ tự động xác nhận giúp bạn.',
          );
        }
        return (
          'Chờ bạn xác nhận',
          'Gia sư đã gửi báo cáo buổi học. Xem lại nội dung rồi xác nhận đã học xong.',
        );
      case LessonStatusType.done:
        return (
          'Đã hoàn thành',
          'Buổi học đã kết thúc. Xem lại nội dung, bài tập và video buổi học bên dưới.',
        );
      case LessonStatusType.cancelled:
        return ('Đã hủy', 'Buổi học này đã bị hủy hoặc gia sư vắng mặt.');
      case LessonStatusType.reserved:
        return (
          'Chờ mở khoá',
          'Buổi học sẽ mở sau khi phụ huynh thanh toán phần còn lại.',
        );
      case LessonStatusType.scheduled:
        final until = lesson.startDt.difference(DateTime.now());
        if (until.isNegative) {
          return ('Đã tới giờ', 'Buổi học đã tới giờ — vào phòng học ngay.');
        }
        return (
          'Sắp diễn ra',
          'Còn ${_humanDuration(until)} nữa tới giờ học. '
              'Phòng học mở trước giờ bắt đầu 15 phút.',
        );
    }
  }
}

String _humanDuration(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} ngày';
  if (d.inHours >= 1) return '${d.inHours} giờ ${d.inMinutes % 60} phút';
  return '${d.inMinutes + 1} phút';
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_ctrl.repeat(reverse: true));
    _anim = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

// Reschedule proposal
class _RescheduleCard extends ConsumerStatefulWidget {
  const _RescheduleCard({required this.proposal});
  final RescheduleProposalDto proposal;

  @override
  ConsumerState<_RescheduleCard> createState() => _RescheduleCardState();
}

class _RescheduleCardState extends ConsumerState<_RescheduleCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.proposal;
    final newStart = p.proposedStartDt;
    final fmt = DateFormat('EEEE, dd/MM · HH:mm', 'vi_VN');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E3CA),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFE0D2A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_calendar_rounded,
                size: 15,
                color: Color(0xFF5C3A1A),
              ),
              const SizedBox(width: 8),
              Text(
                'ĐỀ XUẤT ĐỔI LỊCH',
                style: AppTextStyles.eyebrow(color: const Color(0xFF5C3A1A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.fromTutor
                ? '${p.proposedByName ?? 'Gia sư'} muốn dời buổi học sang:'
                : 'Bạn đã đề xuất dời buổi học sang:',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            newStart != null ? fmt.format(newStart) : 'Thời gian mới',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          if (p.reason?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              'Lý do: ${p.reason}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.ink3,
                height: 1.5,
              ),
            ),
          ],
          if (p.fromTutor) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Từ chối',
                    fg: AppColors.oxblood,
                    onTap: _busy ? () {} : () => unawaited(_respond(false)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: _busy ? 'Đang gửi…' : 'Đồng ý đổi',
                    color: AppColors.moss,
                    fg: Colors.white,
                    enabled: !_busy,
                    onTap: () => unawaited(_respond(true)),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Đang chờ gia sư phản hồi.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5C3A1A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _respond(bool accepted) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(classSessionDatasourceProvider)
          .respondToReschedule(
            classSessionId: widget.proposal.classSessionId,
            accepted: accepted,
          );
      if (!mounted) return;
      ref.invalidate(lessonDetailProvider(widget.proposal.classSessionId));
      unawaited(ref.read(classListProvider.notifier).refresh());
      AppToast.show(
        context,
        message: accepted ? 'Đã đồng ý đổi lịch.' : 'Đã từ chối đổi lịch.',
        type: AppToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// Payment lock

class _PaymentLockCard extends StatelessWidget {
  const _PaymentLockCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9E9),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFE8D5D5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.oxblood,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buổi học đang tạm khóa',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oxblood,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phụ huynh cần thanh toán phần học phí còn lại thì buổi này mới mở phòng học.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.ink2,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tutor card

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.lesson});
  final StudentLessonDetailDto lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          UserAvatar(name: lesson.tutorName ?? 'GS', size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        lesson.tutorName ?? 'Gia sư',
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const VerifyPip(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.subjectName ?? 'Gia sư phụ trách',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          if (lesson.isTutorPresent ?? false)
            const _AttendanceTick(label: 'Có mặt'),
        ],
      ),
    );
  }
}

class _AttendanceTick extends StatelessWidget {
  const _AttendanceTick({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7DF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 11, color: AppColors.moss),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.moss,
            ),
          ),
        ],
      ),
    );
  }
}

// Details card

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.lesson});
  final StudentLessonDetailDto lesson;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi_VN');
    final rows = <({IconData icon, String label, String value})>[
      (
        icon: Icons.access_time_rounded,
        label: 'Thời gian',
        value:
            '${DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(lesson.startDt)} · ${lesson.timeRange}',
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Môn học',
        value: lesson.subjectName ?? '—',
      ),
      if (lesson.checkinDt != null)
        (
          icon: Icons.login_rounded,
          label: 'Bắt đầu thực tế',
          value: DateFormat('HH:mm · dd/MM').format(lesson.checkinDt!),
        ),
      if (lesson.checkoutDt != null)
        (
          icon: Icons.logout_rounded,
          label: 'Kết thúc thực tế',
          value: DateFormat('HH:mm · dd/MM').format(lesson.checkoutDt!),
        ),
      if ((lesson.lessonPrice ?? 0) > 0)
        (
          icon: Icons.payments_outlined,
          label: 'Học phí buổi',
          value: '${money.format(lesson.lessonPrice)} đ',
        ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THÔNG TIN BUỔI HỌC', style: AppTextStyles.eyebrow()),
          const SizedBox(height: 14),
          for (int i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 14 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.cream2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(rows[i].icon, size: 16, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].label.toUpperCase(),
                          style: AppTextStyles.eyebrow(),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rows[i].value,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Report card

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final LessonReportDto report;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1.1),
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BÁO CÁO CỦA GIA SƯ',
                style: AppTextStyles.eyebrow(color: AppColors.gold),
              ),
              const SizedBox(height: 12),
              if (report.contentCovered.isNotEmpty)
                _ReportRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Đã học',
                  text: report.contentCovered,
                ),
              if (report.homeworkAssigned?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                _ReportRow(
                  icon: Icons.assignment_outlined,
                  label: 'Bài tập',
                  text: report.homeworkAssigned!,
                ),
              ],
              if (report.studentPerformanceRating != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Gia sư đánh giá bạn',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cream,
                        ),
                      ),
                      const Spacer(),
                      ...List.generate(5, (i) {
                        final filled = i < report.studentPerformanceRating!;
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 15,
                          color: filled
                              ? AppColors.gold
                              : AppColors.cream.withValues(alpha: 0.3),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.icon,
    required this.label,
    required this.text,
  });
  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.cream.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Recording card

class _RecordingCard extends ConsumerWidget {
  const _RecordingCard({required this.lessonId});
  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lessonRecordingProvider(lessonId));
    final rec = async.valueOrNull;
    // Không có bản ghi thì ẩn hẳn khối này, tránh chiếm chỗ vô ích.
    if (rec == null || rec.status == 'none' || rec.status == 'failed') {
      return const SizedBox.shrink();
    }

    final ready = rec.available && (rec.streamUrl?.isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              ready
                  ? Icons.play_circle_outline_rounded
                  : Icons.hourglass_top_rounded,
              size: 20,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xem lại buổi học',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ready
                      ? 'Video đã sẵn sàng'
                      : rec.status == 'recording'
                      ? 'Đang ghi hình…'
                      : 'Đang xử lý, quay lại sau ít phút',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          if (ready)
            SecondaryButton(
              label: 'Xem',
              icon: Icons.play_arrow_rounded,
              onTap: () {
                // Token trong streamUrl chỉ sống vài phút, nên lấy link mới mỗi
                // lần mở thay vì cache lại ở đây.
                ref.invalidate(lessonRecordingProvider(lessonId));
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SessionRecordingPlayerScreen(
                        streamUrl: rec.streamUrl!,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Cancelled note

class _CancelledNote extends StatelessWidget {
  const _CancelledNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.ink3,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buổi học này không được tính vào tiến độ lớp. Liên hệ hỗ trợ nếu bạn cần học bù.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.ink3,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Action bar

class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.lesson, required this.bottomInset});
  final StudentLessonDetailDto lesson;
  final double bottomInset;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  StudentLessonDetailDto get lesson => widget.lesson;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(16, 10, 16, widget.bottomInset + 12);

    return switch (lesson.statusType) {
      LessonStatusType.pending => Container(
        padding: padding,
        color: AppColors.cream,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: _busy ? 'Đang xác nhận…' : 'Xác nhận đã học xong',
              color: AppColors.moss,
              fg: Colors.white,
              icon: Icons.check_rounded,
              enabled: !_busy,
              onTap: () => unawaited(_confirm()),
            ),
            const SizedBox(height: 10),
            _secondaryRow(),
          ],
        ),
      ),
      LessonStatusType.done => Container(
        padding: padding,
        color: AppColors.cream,
        child: _secondaryRow(),
      ),
      LessonStatusType.cancelled => Container(
        padding: padding,
        color: AppColors.cream,
        child: SecondaryButton(
          label: 'Xem lớp học',
          icon: Icons.grid_view_rounded,
          onTap: () {
            final id = lesson.bookingId;
            if (id == null) return;
            unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudentClassDetailPage(bookingId: id),
                ),
              ),
            );
          },
        ),
      ),
      _ => Container(
        padding: padding,
        color: AppColors.cream,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: _joinLabel,
              icon: _canJoin
                  ? Icons.videocam_rounded
                  : Icons.lock_clock_rounded,
              enabled: _canJoin,
              onTap: _joinRoom,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Chỉ mời đổi lịch khi BE thực sự cho phép (buổi chưa diễn ra,
                // còn ≥2 giờ, không có đề xuất đang chờ) — tránh bấm vào rồi ăn 400.
                if (lesson.canProposeReschedule) ...[
                  Expanded(
                    child: SecondaryButton(
                      label: 'Đổi lịch',
                      icon: Icons.edit_calendar_outlined,
                      onTap: () => unawaited(_openReschedule()),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SecondaryButton(
                    label: 'Khiếu nại',
                    icon: Icons.flag_outlined,
                    fg: AppColors.oxblood,
                    onTap: () => unawaited(_openDispute()),
                  ),
                ),
              ],
            ),
            if (!lesson.canProposeReschedule &&
                lesson.statusType == LessonStatusType.scheduled) ...[
              const SizedBox(height: 8),
              Text(
                lesson.rescheduleBlockReason!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ],
        ),
      ),
    };
  }

  Widget _secondaryRow() {
    final canFeedback =
        ref.watch(canLeaveFeedbackProvider(lesson.lessonId)).valueOrNull ??
        false;
    return Row(
      children: [
        if (canFeedback) ...[
          Expanded(
            child: SecondaryButton(
              label: 'Đánh giá gia sư',
              icon: Icons.star_outline_rounded,
              onTap: () => unawaited(_openFeedback()),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: SecondaryButton(
            label: 'Khiếu nại',
            icon: Icons.flag_outlined,
            fg: AppColors.oxblood,
            onTap: () => unawaited(_openDispute()),
          ),
        ),
      ],
    );
  }

  bool get _canJoin =>
      !_busy && lesson.canJoinNow && !lesson.requiresRemainingPayment;

  /// Phòng luôn mở nên chỉ đổi chữ theo việc đã tới sát giờ hay chưa.
  String get _joinLabel {
    if (lesson.requiresRemainingPayment) return 'Chờ phụ huynh thanh toán';
    if (!lesson.canJoinNow) return 'Phòng học đã đóng';
    return lesson.isWithinJoinWindow ? 'Vào phòng học' : 'Vào phòng sớm';
  }

  void _joinRoom() {
    // Lease/token/heartbeat do LiveSessionCallScreen tự lo; ở đây chỉ mở màn.
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LiveSessionCallScreen(
            classSessionId: lesson.lessonId,
            tutorName: lesson.tutorName,
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(classSessionDatasourceProvider)
          .confirmClassSession(lesson.lessonId);
      if (!mounted) return;
      ref.invalidate(lessonDetailProvider(lesson.lessonId));
      unawaited(ref.read(classListProvider.notifier).refresh());
      AppToast.show(
        context,
        message: 'Đã xác nhận buổi học. Cảm ơn bạn!',
        type: AppToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFeedback() async {
    final ok = await showFeedbackSheet(context, lesson.lessonId);
    if ((ok ?? false) && mounted) {
      ref.invalidate(canLeaveFeedbackProvider(lesson.lessonId));
      AppToast.show(
        context,
        message: 'Cảm ơn đánh giá của bạn!',
        type: AppToastType.success,
      );
    }
  }

  Future<void> _openDispute() async {
    final ok = await showDisputeSheet(context, lesson.lessonId);
    if ((ok ?? false) && mounted) {
      ref.invalidate(lessonDetailProvider(lesson.lessonId));
      AppToast.show(
        context,
        message: 'Đã gửi khiếu nại. Chúng tôi sẽ xem xét sớm.',
        type: AppToastType.success,
      );
    }
  }

  Future<void> _openReschedule() async {
    final picked = await showRescheduleSheet(
      context,
      currentStart: lesson.startDt,
      currentEnd: lesson.endDt,
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(classSessionDatasourceProvider)
          .proposeReschedule(
            classSessionId: lesson.lessonId,
            proposedStart: picked.start,
            reason: picked.reason,
          );
      if (!mounted) return;
      ref.invalidate(lessonDetailProvider(lesson.lessonId));
      AppToast.show(
        context,
        message: 'Đã gửi đề xuất đổi lịch cho gia sư.',
        type: AppToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }
}
