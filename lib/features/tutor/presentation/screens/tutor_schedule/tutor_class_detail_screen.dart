import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_booking_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/recorded_lesson_tile.dart';
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

    // Buổi đã ghi âm của lớp này (recorder.lessons gắn classSessionId).
    final sessionIds = {for (final s in sessions) s.lessonId};
    final recorded =
        (ref.watch(recorderAllLessonsProvider).valueOrNull ?? const [])
            .where(
              (l) =>
                  l.classSessionId != null &&
                  sessionIds.contains(l.classSessionId),
            )
            .where((l) => l.status != 'scheduled')
            .toList()
          ..sort(
            (a, b) => (b.startedAt ?? DateTime(0)).compareTo(
              a.startedAt ?? DateTime(0),
            ),
          );

    // Sắp tới: buổi chưa diễn ra, gần nhất trước.
    final now = DateTime.now();
    final upcoming =
        sessions
            .where(
              (s) =>
                  s.isScheduled && (s.endDt ?? s.startDt ?? now).isAfter(now),
            )
            .toList()
          ..sort((a, b) => (a.startDt ?? now).compareTo(b.startDt ?? now));

    // Buổi phụ / học lại gom về đúng buổi gốc, rồi mới chia theo tháng.
    final chains = groupSessionChains(sessions);
    final groups = <String, List<SessionChain>>{};
    for (final c in chains) {
      final dt = c.parent.startDt;
      if (dt == null) continue;
      groups.putIfAbsent('${dt.year}-${dt.month}', () => []).add(c);
    }

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              CanvasHeader(
                title: item.subjectName,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: TutorSurface.screenPadding,
                child: _ClassSummary(
                  item: item,
                  total: item.totalWithReserved,
                  completed: item.completedSessions,
                ),
              ),
              const SizedBox(height: TutorSurface.sectionGap),
              if (upcoming.isNotEmpty) ...[
                const _Label('Sắp tới'),
                for (final s in upcoming.take(3))
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
              if (recorded.isNotEmpty) ...[
                _Label('Buổi đã ghi âm · ${recorded.length}'),
                for (final l in recorded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      0,
                      TutorSurface.gutter,
                      TutorSurface.rowGap,
                    ),
                    child: RecordedLessonTile(lesson: l),
                  ),
                const SizedBox(height: 8),
              ],
              if (sessions.isNotEmpty) const _Label('Tất cả buổi học'),
              if (async.isLoading && sessions.isEmpty)
                const Padding(
                  padding: TutorSurface.screenPadding,
                  child: TutorSkeleton(
                    height: 180,
                    radius: TutorSurface.radius,
                  ),
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
              else ...[
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      0,
                      TutorSurface.gutter,
                      10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _monthLabel(entry.key),
                            style: TutorType.sectionTitle(),
                          ),
                        ),
                        if (entry.value.any(
                          (c) => c.parent.isExtra || c.children.isNotEmpty,
                        ))
                          const _ExtraSessionLegend(),
                      ],
                    ),
                  ),
                  for (final chain in entry.value) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TutorSurface.gutter,
                        0,
                        TutorSurface.gutter,
                        TutorSurface.rowGap,
                      ),
                      child: _SessionRow(lesson: chain.parent),
                    ),
                    // Buổi phụ / học lại thụt vào để thấy rõ nó bám buổi trên
                    for (final child in chain.children)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TutorSurface.gutter + 24,
                          0,
                          TutorSurface.gutter,
                          TutorSurface.rowGap,
                        ),
                        child: _SessionRow(lesson: child, nested: true),
                      ),
                  ],
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
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
    return Container(
      padding: TutorSurface.cardPadding,
      decoration: TutorSurface.sage(),
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
                      style: TutorType.display(size: 19),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subjectName,
                      style: TutorType.rowSub(),
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
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    minHeight: 4,
                    backgroundColor: const Color(0x1F1F2A24),
                    valueColor: const AlwaysStoppedAnimation(TutorColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$completed/$total buổi', style: TutorType.action()),
            ],
          ),
          if (item.schedule.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.repeat_rounded,
                  size: 14,
                  color: TutorColors.ink3,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.schedule,
                    style: TutorType.rowSub(),
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

/// Chú thích màu ribbon của buổi học phụ.
class _ExtraSessionLegend extends StatelessWidget {
  const _ExtraSessionLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: _SessionRow._extraTone,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text('Buổi học phụ', style: TutorType.caption(color: TutorColors.ink3)),
      ],
    );
  }
}

/// Một buổi trong lớp — ngày bên trái, trạng thái bên phải.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.lesson, this.nested = false});

  final TutorLessonDto lesson;

  /// Buổi con trong chuỗ
  final bool nested;

  /// Màu ribbon cho buổi sinh thêm.
  static const Color _extraTone = TutorColors.ink3;

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
      // Buổi huỷ vẫn nằm trong danh sách để đủ số buổi của gói
      _ when lesson.isCancelled => (
        TutorColors.ink4,
        'Đã huỷ',
        'Buổi này đã bị huỷ, không diễn ra',
      ),
      _ when lesson.isReserved => (
        TutorColors.ink3,
        'Giữ chỗ',
        'Chưa mở, chờ phụ huynh thanh toán đợt 2',
      ),
      // Buổi phụ hai bên đã thống nhất bỏ: còn status scheduled nhưng không
      // vào lớp nữa, nên phải tách khỏi nhánh "Sắp tới" bên dưới.
      _ when lesson.isContinuation && lesson.skipConfirmedByBothSides => (
        TutorColors.ink3,
        'Đã bỏ',
        'Hai bên đồng ý bỏ buổi phụ này',
      ),
      _ when lesson.isInterrupted => (
        TutorColors.warning,
        'Học dở dang',
        'Buổi bị ngắt giữa chừng, chờ buổi phụ hoặc gửi báo cáo',
      ),
      _ when lesson.isAwaitingReport => (
        TutorColors.warning,
        'Chờ báo cáo',
        'Bạn chưa gửi báo cáo cho buổi này',
      ),
      _ when lesson.isPendingConfirmation => (
        TutorColors.ink3,
        'Chờ xác nhận',
        'Đã gửi báo cáo, chờ học sinh xác nhận',
      ),
      _ when lesson.isCompleted => (
        TutorColors.ink,
        'Hoàn thành',
        'Đã dạy xong và được xác nhận',
      ),
      _ when lesson.isLive => (
        TutorColors.ink,
        'Đang dạy',
        'Buổi học đang diễn ra',
      ),
      _ => (TutorColors.ink, 'Sắp tới', 'Đã lên lịch, chưa diễn ra'),
    };

    // Màu chỉ cho cảnh báo thật; còn lại là mực.
    final warn = tone == TutorColors.danger || tone == TutorColors.warning;

    return DecoratedBox(
      decoration: nested
          ? BoxDecoration(
              color: TutorColors.surfaceSunken,
              borderRadius: BorderRadius.circular(TutorSurface.radius),
            )
          : TutorSurface.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TutorSurface.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TutorBookingDetailScreen(lesson: lesson),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              children: [
                if (lesson.linkLabel != null) ...[
                  Container(
                    width: 3,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _extraTone,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 9),
                ],
                // Ô ngày: mốc neo mắt khi lướt danh sách nhiều buổi.
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: warn
                        ? tone.withValues(alpha: 0.1)
                        : (nested
                              ? TutorColors.surface
                              : TutorColors.surfaceSunken),
                    borderRadius: BorderRadius.circular(
                      TutorSurface.radiusSmall,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dt == null ? '—' : '${dt.day}',
                        style: TutorType.numeral(
                          color: tone,
                        ).copyWith(fontSize: 16),
                      ),
                      Text(
                        dt == null ? '' : 'Th${dt.month}',
                        style: TutorType.caption(
                          color: warn ? tone : TutorColors.ink3,
                        ).copyWith(fontSize: 10),
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
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: warn
                                    ? tone.withValues(alpha: 0.1)
                                    : const Color(0xFFEAEAE4),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TutorType.caption(
                                  color: warn ? tone : TutorColors.ink,
                                ).copyWith(fontSize: 11.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reason,
                        style: TutorType.rowSub(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const CanvasChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      4,
      TutorSurface.gutter,
      10,
    ),
    child: Text(text, style: TutorType.sectionTitle().copyWith(fontSize: 17)),
  );
}
