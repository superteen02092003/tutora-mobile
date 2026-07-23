import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/data/datasources/parent_datasource.dart';
import 'package:tutora/features/parent/presentation/providers/parent_classes_provider.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_status_pill.dart';
import 'package:tutora/shared/datasources/class_interaction_datasource.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:tutora/shared/widgets/class_interaction_sheets.dart';

/// Chi tiết buổi học cho phụ huynh — CHỈ theo dõi + xác nhận.
/// KHÔNG có nút vào phòng học (theo yêu cầu sản phẩm: parent không dạy/học video).
class ParentSessionDetailScreen extends ConsumerStatefulWidget {
  const ParentSessionDetailScreen({required this.lessonId, super.key});

  final int lessonId;

  @override
  ConsumerState<ParentSessionDetailScreen> createState() =>
      _ParentSessionDetailScreenState();
}

class _ParentSessionDetailScreenState
    extends ConsumerState<ParentSessionDetailScreen> {
  bool _confirming = false;

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final resultMsg = await ref
          .read(parentDatasourceProvider)
          .confirmLesson(widget.lessonId);
      if (!mounted) return;
      ref
        ..invalidate(parentLessonDetailProvider(widget.lessonId))
        ..invalidate(parentPendingLessonsProvider)
        ..invalidate(parentUpcomingLessonsProvider);
      AppToast.show(
        context,
        message: (resultMsg?.isNotEmpty ?? false)
            ? resultMsg!
            : 'Đã xác nhận buổi học. Cảm ơn bạn!',
        type: AppToastType.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _confirming = false);
      AppToast.show(
        context,
        message: 'Không xác nhận được, vui lòng thử lại.',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(parentLessonDetailProvider(widget.lessonId));
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            const _AppBar(title: 'Chi tiết buổi học'),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Không tải được chi tiết.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
                data: (lesson) => ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 24),
                  children: [
                    _Header(lesson: lesson),
                    const SizedBox(height: 14),
                    _InfoCard(lesson: lesson),
                    if (_hasContent(lesson)) ...[
                      const SizedBox(height: 14),
                      _ReportCard(lesson: lesson),
                    ],
                    if (lesson.isPendingConfirm) ...[
                      const SizedBox(height: 20),
                      _ConfirmButton(
                        busy: _confirming,
                        onTap: _confirming ? null : _confirm,
                      ),
                    ],
                    ..._buildInteractions(lesson),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _hasContent(ParentLessonDto l) =>
      (l.lessonContent?.isNotEmpty ?? false) ||
      (l.homework?.isNotEmpty ?? false) ||
      (l.tutorNotes?.isNotEmpty ?? false);

  /// Buổi hoàn tất / chờ xác nhận → cho đánh giá (nếu đủ điều kiện) + khiếu nại.
  List<Widget> _buildInteractions(ParentLessonDto lesson) {
    final status = lesson.status;
    final canInteract =
        status == 'completed' || status == 'pending_confirmation';
    if (!canInteract) return const [];

    final canFeedback =
        ref.watch(canLeaveFeedbackProvider(lesson.lessonId)).valueOrNull ??
        false;

    return [
      const SizedBox(height: 10),
      Row(
        children: [
          if (canFeedback) ...[
            Expanded(
              child: _SecondaryButton(
                icon: Icons.star_outline_rounded,
                label: 'Đánh giá',
                onTap: () => _openFeedback(lesson.lessonId),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _SecondaryButton(
              icon: Icons.flag_outlined,
              label: 'Khiếu nại',
              onTap: () => _openDispute(lesson.lessonId),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _openFeedback(int id) async {
    final ok = await showFeedbackSheet(context, id);
    if ((ok ?? false) && mounted) {
      ref.invalidate(canLeaveFeedbackProvider(id));
      AppToast.show(
        context,
        message: 'Cảm ơn đánh giá của bạn!',
        type: AppToastType.success,
      );
    }
  }

  Future<void> _openDispute(int id) async {
    final ok = await showDisputeSheet(context, id);
    if ((ok ?? false) && mounted) {
      ref.invalidate(parentLessonDetailProvider(id));
      AppToast.show(
        context,
        message: 'Đã gửi khiếu nại. Chúng tôi sẽ xem xét sớm.',
        type: AppToastType.success,
      );
    }
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.lesson});
  final ParentLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.subjectName ?? 'Buổi học',
                  style: AppTextStyles.h3(),
                ),
              ),
              ParentStatusPill(
                status: lesson.status,
                isPendingConfirm: lesson.isPendingConfirm,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gia sư: ${lesson.tutorName ?? '—'}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          ),
          if (lesson.studentName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Học sinh: ${lesson.studentName}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.lesson});
  final ParentLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _Row(label: 'Ngày', value: _date(lesson.startDt)),
          _Row(
            label: 'Thời gian',
            value: '${_time(lesson.startDt)} – ${_time(lesson.endDt)}',
          ),
          if (lesson.confirmDeadline != null)
            _Row(
              label: 'Hạn xác nhận',
              value: _date(
                DateTime.tryParse(lesson.confirmDeadline!)?.toLocal() ??
                    lesson.startDt,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.lesson});
  final ParentLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BÁO CÁO BUỔI HỌC',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: AppColors.ink4,
            ),
          ),
          if (lesson.lessonContent?.isNotEmpty ?? false)
            _Block(label: 'Nội dung đã học', text: lesson.lessonContent!),
          if (lesson.homework?.isNotEmpty ?? false)
            _Block(label: 'Bài tập về nhà', text: lesson.homework!),
          if (lesson.tutorNotes?.isNotEmpty ?? false)
            _Block(label: 'Nhận xét của gia sư', text: lesson.tutorNotes!),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.ink2,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.oxblood,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Xác nhận hoàn thành',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFF1E6),
                ),
              ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.ink,
          ),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h3(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _time(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
