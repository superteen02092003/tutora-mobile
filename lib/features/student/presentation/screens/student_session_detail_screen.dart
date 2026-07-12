import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/data/datasources/class_session_datasource.dart';
import 'package:tutora/features/student/data/models/lesson_models.dart';
import 'package:tutora/features/student/presentation/providers/lesson_provider.dart';
import 'package:tutora/features/student/presentation/screens/agora_call_screen.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';

class StudentSessionDetailPage extends ConsumerWidget {
  const StudentSessionDetailPage({required this.lessonId, super.key});
  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lessonDetailProvider(lessonId));
    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.oxblood,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              const _NavBar(title: 'Chi tiết buổi học'),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Không tải được buổi học',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.ink3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () =>
                            ref.invalidate(lessonDetailProvider(lessonId)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Thử lại',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cream,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (lesson) => _DetailScaffold(lesson: lesson),
    );
  }
}

// Main scaffold

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.lesson});
  final StudentLessonDetailDto lesson;

  bool get _isDone => lesson.statusType == LessonStatusType.done;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(
              title: _isDone ? 'Tổng kết buổi học' : 'Chi tiết buổi học',
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomInset + 88),
                children: [
                  if (_isDone) ...[
                    _DoneBanner(lesson: lesson),
                    _TutorCard(lesson: lesson),
                    _DetailsCard(lesson: lesson),
                    const _RatingCard(),
                    if (lesson.report != null)
                      _RecapCard(report: lesson.report!),
                  ] else ...[
                    _ActiveBanner(lesson: lesson),
                    _TutorCard(lesson: lesson),
                    _DetailsCard(lesson: lesson),
                  ],
                ],
              ),
            ),
            if (_isDone)
              _DoneActions(
                tutorName: lesson.tutorName,
                bottomInset: bottomInset,
              )
            else
              _ActiveActions(lesson: lesson, bottomInset: bottomInset),
          ],
        ),
      ),
    );
  }
}

// Nav bar

class _NavBar extends StatelessWidget {
  const _NavBar({required this.title});
  final String title;

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
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// Done banner

class _DoneBanner extends StatelessWidget {
  const _DoneBanner({required this.lesson});
  final StudentLessonDetailDto lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7DF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D3CB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.moss,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đã kết thúc · ${lesson.timeRange}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.moss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Active banner

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.lesson});
  final StudentLessonDetailDto lesson;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = switch (lesson.statusType) {
      LessonStatusType.scheduled => (
        AppColors.moss,
        const Color(0xFFE0E7DF),
        'Đã xác nhận · chờ buổi học',
      ),
      LessonStatusType.pending => (
        const Color(0xFFF0E3CA),
        const Color(0xFF5C3A1A),
        'Chờ gia sư xác nhận',
      ),
      _ => (
        AppColors.moss,
        const Color(0xFFE0E7DF),
        'Đã xác nhận',
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PulseDot(color: fg),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
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
          UserAvatar(name: lesson.tutorName ?? 'GS', size: 56),
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
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const VerifyPip(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.subjectName ?? '',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
                ),
              ],
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
    final rows = [
      (
        icon: Icons.access_time_rounded,
        label: 'Thời gian',
        value: '${lesson.dateLabel} · ${lesson.timeRange}',
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Môn học',
        value: lesson.subjectName ?? '—',
      ),
      if (lesson.lessonContent?.isNotEmpty ?? false)
        (
          icon: Icons.auto_awesome_rounded,
          label: 'Nội dung',
          value: lesson.lessonContent!,
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
          ...rows.asMap().entries.map(
            (e) => Padding(
              padding: EdgeInsets.only(
                bottom: e.key < rows.length - 1 ? 14 : 0,
              ),
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
                    child: Icon(e.value.icon, size: 16, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.value.label.toUpperCase(),
                          style: AppTextStyles.eyebrow(),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          e.value.value,
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
          ),
        ],
      ),
    );
  }
}

// Rating card (done sessions only)
class _RatingCard extends StatefulWidget {
  const _RatingCard();

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _stars = 0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ĐÁNH GIÁ BUỔI HỌC', style: AppTextStyles.eyebrow()),
          const SizedBox(height: 10),
          Text(
            'Bạn đánh giá buổi học thế nào?',
            style: GoogleFonts.ibmPlexSerif(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 38,
                    color: filled ? AppColors.gold : AppColors.line,
                  ),
                ),
              );
            }),
          ),
          if (_stars > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Nhận xét thêm (không bắt buộc)…',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Gửi đánh giá',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Recap card
class _RecapCard extends StatelessWidget {
  const _RecapCard({required this.report});
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
                'BÁO CÁO BUỔI HỌC',
                style: AppTextStyles.eyebrow(color: AppColors.gold),
              ),
              const SizedBox(height: 12),
              _RecapRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Đã học',
                text: report.contentCovered,
              ),
              if (report.homeworkAssigned?.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                _RecapRow(
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
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đánh giá của gia sư: ${report.studentPerformanceRating}/5',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cream,
                        ),
                      ),
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

class _RecapRow extends StatelessWidget {
  const _RecapRow({
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
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.cream.withValues(alpha: 0.85),
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Done actions
class _DoneActions extends StatelessWidget {
  const _DoneActions({required this.tutorName, required this.bottomInset});
  final String? tutorName;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 12),
      color: AppColors.cream,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.oxblood,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Đặt buổi học tiếp theo với ${tutorName ?? 'gia sư'}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFF1E6),
            ),
          ),
        ),
      ),
    );
  }
}

// Active actions
class _ActiveActions extends ConsumerStatefulWidget {
  const _ActiveActions({required this.lesson, required this.bottomInset});
  final StudentLessonDetailDto lesson;
  final double bottomInset;

  @override
  ConsumerState<_ActiveActions> createState() => _ActiveActionsState();
}

class _ActiveActionsState extends ConsumerState<_ActiveActions> {
  bool _busy = false;

  StudentLessonDetailDto get lesson => widget.lesson;

  bool get _awaitingConfirm => lesson.statusType == LessonStatusType.pending;

  @override
  Widget build(BuildContext context) {
    // When the tutor has submitted the report the session sits in
    // pending_confirmation — the student's action is to confirm, not to join.
    if (_awaitingConfirm) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, widget.bottomInset + 12),
        color: AppColors.cream,
        child: GestureDetector(
          onTap: _busy ? null : _confirmLesson,
          child: Opacity(
            opacity: _busy ? 0.5 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.moss,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _busy ? 'Đang xác nhận…' : 'Xác nhận đã học xong',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, widget.bottomInset + 12),
      color: AppColors.cream,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCancelSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Hủy buổi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.oxblood,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _busy ? null : _joinRoom,
              child: Opacity(
                opacity: _busy ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.oxblood,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _busy ? 'Đang vào…' : 'Vào phòng học',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFF1E6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final ds = ref.read(classSessionDatasourceProvider);
      final room = await ds.getAgoraRoom(lesson.lessonId);
      if (!room.isValid) {
        throw Exception('Phòng học chưa sẵn sàng, vui lòng thử lại.');
      }
      if (!mounted) return;
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => AgoraCallScreen(
            room: room,
            tutorName: lesson.tutorName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmLesson() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ds = ref.read(classSessionDatasourceProvider);
      await ds.confirmClassSession(lesson.lessonId);
      if (!mounted) return;
      ref.invalidate(lessonDetailProvider(lesson.lessonId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xác nhận buổi học. Cảm ơn bạn!')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showCancelSheet(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hủy buổi học?',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bạn có chắc muốn hủy buổi học với ${lesson.tutorName ?? 'gia sư'}?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.ink2,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E3CA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0D2A8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.oxblood,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hủy trước 2 giờ — hoàn tiền 100%. Hủy muộn — giữ 30% phí nền tảng.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.ink2,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.oxblood,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Xác nhận hủy · Hoàn 100%',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFF1E6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      'Giữ nguyên',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
