import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_booking_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

/// Chi tiết lớp — buổi gom theo tháng vì một lớp kéo dài nhiều tuần.
class TutorClassDetailScreen extends ConsumerWidget {
  const TutorClassDetailScreen({required this.item, super.key});

  final TutorClassDto item;

  static const _months = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classSessionsProvider(item.bookingId));
    final sessions = async.value ?? const <TutorLessonDto>[];

    // Gom theo tháng, giữ thứ tự thời gian.
    final groups = <String, List<TutorLessonDto>>{};
    for (final s in sessions) {
      final dt = s.startDt;
      if (dt == null) continue;
      groups.putIfAbsent('${dt.year}-${dt.month}', () => []).add(s);
    }

    // Đếm từ danh sách thật vì totalSessions của /tutor/classes đang lệch.
    final counted = sessions.length;
    // pending_confirmation tính là hoàn thành dù tiền chưa giải ngân.
    final done = sessions.where((l) => l.isFinished).length;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            TutorChildHeader(title: item.subjectName),
            Padding(
              padding: TutorSurface.screenPadding,
              child: _ClassSummary(
                item: item,
                total: sessions.isEmpty ? item.totalSessions : counted,
                completed: sessions.isEmpty ? item.completedSessions : done,
              ),
            ),
            const SizedBox(height: TutorSurface.sectionGap),
            if (async.isLoading && sessions.isEmpty)
              const Padding(
                padding: TutorSurface.screenPadding,
                child: TutorSkeleton(height: 180, radius: TutorSurface.radius),
              )
            else if (sessions.isEmpty)
              Padding(
                padding: TutorSurface.screenPadding,
                child: TutorCard(
                  color: TutorColors.dangerBg,
                  borderColor: TutorColors.dangerBorder,
                  onTap: () =>
                      ref.invalidate(classSessionsProvider(item.bookingId)),
                  child: Text(
                    'Không tải được buổi học của lớp này. Chạm để thử lại.',
                    style: TutorType.rowSub(color: TutorColors.danger),
                  ),
                ),
              )
            else
              for (final entry in groups.entries) ...[
                TutorSectionHeader(
                  title: _monthLabel(entry.key),
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    0,
                    TutorSurface.gutter,
                    10,
                  ),
                ),
                for (final s in entry.value)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      0,
                      TutorSurface.gutter,
                      TutorSurface.rowGap,
                    ),
                    child: _SessionRow(lesson: s),
                  ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }

  static String _monthLabel(String key) {
    final parts = key.split('-');
    final month = int.tryParse(parts.last) ?? 1;
    return '${_months[month - 1]} ${parts.first}';
  }
}

/// Thẻ tóm tắt lớp — học sinh, tiến độ, khung giờ cố định.
class _ClassSummary extends StatelessWidget {
  const _ClassSummary({
    required this.item,
    required this.total,
    required this.completed,
  });

  final TutorClassDto item;
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return TutorCard(
      color: TutorColors.heroTealBg,
      borderColor: TutorColors.heroTealBg,
      shadow: TutorColors.cardShadow,
      backgroundImage: const DecorationImage(
        image: AssetImage('assets/images/common/backgroud_tutor_next.png'),
        fit: BoxFit.cover,
        alignment: Alignment.bottomRight,
        opacity: 0.3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TutorAvatar(name: item.studentName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName,
                      style: TutorType.numeral().copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subjectName,
                      style: TutorType.rowSub(color: TutorColors.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    minHeight: 7,
                    backgroundColor: TutorColors.surface,
                    valueColor: const AlwaysStoppedAnimation(
                      TutorColors.heroTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completed/$total buổi',
                style: TutorType.action(),
              ),
            ],
          ),
          if (item.schedule.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.repeat_rounded,
                  size: 14,
                  color: TutorColors.ink2,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.schedule,
                    style: TutorType.caption(color: TutorColors.ink2),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Một buổi trong lớp — ngày bên trái, trạng thái bên phải.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.lesson});

  final TutorLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    final dt = lesson.startDt;
    // Nhãn kèm lý do — nhãn một từ không cho biết còn phải làm gì.
    final (Color tone, String label, String reason) = switch (lesson) {
      _ when lesson.isDisputed => (
        TutorColors.danger,
        'Tranh chấp',
        'Tiền bị giữ tới khi được xử lý',
      ),
      _ when lesson.isNoShow => (
        TutorColors.danger,
        'Vắng mặt',
        'Buổi không diễn ra do có bên vắng',
      ),
      _ when lesson.isAwaitingReport => (
        TutorColors.warning,
        'Chờ báo cáo',
        'Bạn chưa gửi báo cáo — tiền chưa chạy tiếp',
      ),
      _ when lesson.isPendingConfirmation => (
        TutorColors.warning,
        'Chờ xác nhận',
        'Đã gửi báo cáo, chờ học sinh xác nhận',
      ),
      _ when lesson.isCompleted => (
        TutorColors.success,
        'Hoàn thành',
        'Đã dạy xong và được xác nhận',
      ),
      _ when lesson.isLive => (
        TutorColors.accent,
        'Đang dạy',
        'Buổi học đang diễn ra',
      ),
      _ => (TutorColors.primary, 'Sắp tới', 'Đã lên lịch, chưa diễn ra'),
    };

    return TutorCard(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      shadow: TutorColors.cardShadow,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorBookingDetailScreen(lesson: lesson),
        ),
      ),
      child: Row(
        children: [
          // Ô ngày: mốc neo mắt khi lướt danh sách nhiều buổi.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dt == null ? '—' : '${dt.day}',
                  style: TutorType.numeral(color: tone).copyWith(fontSize: 16),
                ),
                Text(
                  dt == null ? '' : 'Th${dt.month}',
                  style: TutorType.caption(color: tone).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${lesson.timeStart}–${lesson.timeEnd}',
                      style: TutorType.rowTitle(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TutorType.caption(
                          color: tone,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  style: TutorType.caption(color: TutorColors.ink2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: TutorColors.ink4,
          ),
        ],
      ),
    );
  }
}
