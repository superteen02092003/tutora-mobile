import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_lesson_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';

final AutoDisposeFutureProviderFamily<TutorSessionDetailDto, int>
_sessionDetailProvider = FutureProvider.autoDispose
    .family<TutorSessionDetailDto, int>(
      (ref, id) => ref.read(tutorLessonDatasourceProvider).getSessionDetail(id),
    );

/// Chi tiết buổi học (prototype: "11 · Chi tiết buổi học").
///
/// Mở từ một dòng agenda trên tab Lịch. Phần lịch có sẵn (giờ, học sinh, môn,
/// trạng thái) hiện ngay; học phí và khối lớp tải thêm từ chi tiết buổi.
class TutorSessionDetailScreen extends ConsumerWidget {
  const TutorSessionDetailScreen({required this.lesson, super.key});

  final TutorLessonDto lesson;

  static Future<void> open(BuildContext context, TutorLessonDto lesson) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorSessionDetailScreen(lesson: lesson),
        ),
      );

  static const _weekday = [
    'Thứ hai',
    'Thứ ba',
    'Thứ tư',
    'Thứ năm',
    'Thứ sáu',
    'Thứ bảy',
    'Chủ nhật',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _money(double v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '$bđ';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_sessionDetailProvider(lesson.lessonId)).valueOrNull;
    final start = lesson.startDt?.toLocal();
    final end = lesson.endDt?.toLocal();
    final now = DateTime.now();
    final isToday = start != null &&
        start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final canRecord = isToday && !lesson.isFinished && !lesson.isAwaitingReport;

    final status = _Status.of(lesson, now);
    final subtitle = [
      if (lesson.subjectName.isNotEmpty) lesson.subjectName,
      if (detail?.gradeName != null && detail!.gradeName!.isNotEmpty)
        detail.gradeName!,
    ].join(' · ');

    // Buổi trước cùng lớp — lấy từ lịch đã tải.
    final schedule =
        ref.watch(tutorAgendaLessonsProvider).valueOrNull ?? const <TutorLessonDto>[];
    TutorLessonDto? previous;
    if (lesson.bookingId != null && start != null) {
      for (final l in schedule) {
        final s = l.startDt;
        if (l.bookingId != lesson.bookingId || s == null || !s.isBefore(start)) {
          continue;
        }
        if (previous == null || s.isAfter(previous.startDt!)) previous = l;
      }
    }

    final prev = previous;
    final initial = lesson.studentName.trim().isEmpty
        ? '?'
        : lesson.studentName.trim()[0].toUpperCase();

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // ── Quay lại + trạng thái ─────────────────────────
                  Row(
                    children: [
                      _CircleBtn(
                        icon: Icons.chevron_left_rounded,
                        label: 'Quay lại',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: status.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.label,
                          style: TutorType.caption(color: status.fg)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Học sinh ─────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TutorColors.surfaceSunken,
                          border: Border.all(color: TutorColors.line),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initial,
                          style: TutorType.rowTitle().copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.studentName,
                              style: TutorType.screenTitle()
                                  .copyWith(height: 1.1),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TutorType.rowTitle(
                                  color: TutorColors.ink3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Giờ · địa điểm · học phí ──────────────────────
                  _Card(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          title: start == null
                              ? 'Chưa có giờ'
                              : '${_weekday[start.weekday - 1]}, '
                                    '${_two(start.day)}/${_two(start.month)} · '
                                    '${lesson.timeStart}'
                                    '${end == null ? '' : ' – ${lesson.timeEnd}'}',
                          sub: lesson.linkLabel,
                        ),
                        const Divider(height: 1, color: TutorColors.line),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          title: _place(lesson.teachingMode),
                        ),
                        const Divider(height: 1, color: TutorColors.line),
                        _InfoRow(
                          icon: Icons.attach_money_rounded,
                          title: detail?.price == null
                              ? '—'
                              : _money(detail!.price!),
                          trailing: 'Giải ngân sau khi gửi báo cáo',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Báo cáo gửi tới ──────────────────────────────
                  const _SectionLabel('BÁO CÁO GỬI TỚI'),
                  const SizedBox(height: 10),
                  _Card(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: TutorColors.surfaceSunken,
                            border: Border.all(color: TutorColors.line),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: TutorColors.ink,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phụ huynh của ${lesson.studentName}',
                                style: TutorType.rowTitle(),
                              ),
                              const SizedBox(height: 2),
                              Text('Phụ huynh', style: TutorType.caption()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Ghi âm & báo cáo ─────────────────────────────
                  const _SectionLabel('GHI ÂM & BÁO CÁO'),
                  const SizedBox(height: 10),
                  _RecordingState(lesson: lesson, isToday: isToday),
                  if (prev != null) ...[
                    const SizedBox(height: 10),
                    _Card(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buổi trước · '
                                  '${_two(prev.startDt!.day)}/'
                                  '${_two(prev.startDt!.month)}',
                                  style: TutorType.rowTitle(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  prev.isFinished
                                      ? 'Đã hoàn thành'
                                      : prev.isAwaitingReport
                                      ? 'Chưa có báo cáo'
                                      : 'Chưa diễn ra',
                                  style: TutorType.caption(),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => TutorSessionDetailScreen(
                                        lesson: prev,
                                      ),
                                    ),
                                  ),
                              style: OutlinedButton.styleFrom(
                                // Theme app đặt minimumSize rộng vô hạn cho OutlinedButton.
                                minimumSize: const Size(0, 36),
                                side: const BorderSide(color: TutorColors.line),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: Text('Xem', style: TutorType.action()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Thanh hành động ─────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: TutorColors.bg,
                border: Border(top: BorderSide(color: TutorColors.line)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canRecord) ...[
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push(
                            AppRoutes.tutorRecording,
                            extra: RecordingTarget(
                              lessonId: lesson.lessonId,
                              studentName: lesson.studentName,
                              subjectName: lesson.subjectName,
                              timeStart: lesson.timeStart,
                              timeEnd: lesson.timeEnd,
                              scheduledEnd: end,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: TutorColors.primary,
                          foregroundColor: TutorColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.mic_none_rounded, size: 18),
                        label: Text(
                          'Bắt đầu ghi âm',
                          style: TutorType.action(color: TutorColors.surface),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      _ActionBtn(
                        icon: Icons.calendar_today_outlined,
                        label: 'Đổi lịch',
                        onTap: () => _soon(context),
                      ),
                      _ActionBtn(
                        icon: Icons.person_outline_rounded,
                        label: 'Hồ sơ HS',
                        onTap: () => _soon(context),
                      ),
                      _ActionBtn(
                        icon: Icons.close_rounded,
                        label: 'Huỷ buổi',
                        color: TutorColors.primary,
                        onTap: () => _soon(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _place(String? mode) {
    final m = (mode ?? '').toLowerCase();
    if (m.contains('online')) return 'Học trực tuyến';
    return 'Tại nhà học sinh';
  }

  static void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng này chưa có trên app — làm trên tutora.vn.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Status {
  const _Status(this.label, this.bg, this.fg);

  final String label;
  final Color bg;
  final Color fg;

  static _Status of(TutorLessonDto l, DateTime now) {
    if (l.isLive) {
      return const _Status(
        'Đang diễn ra',
        TutorColors.successBg,
        TutorColors.success,
      );
    }
    if (l.isAwaitingReport) {
      return const _Status('Cần báo cáo', TutorColors.primaryBg, TutorColors.primary);
    }
    if (l.isFinished) {
      return const _Status('Đã hoàn thành', TutorColors.successBg, TutorColors.success);
    }
    final end = l.endDt;
    if (end != null && end.isBefore(now)) {
      return const _Status('Đã qua', TutorColors.surfaceSunken, TutorColors.ink3);
    }
    return const _Status('Sắp diễn ra', Color(0xFFF0E3CA), Color(0xFF5C3A1A));
  }
}

class _RecordingState extends StatelessWidget {
  const _RecordingState({required this.lesson, required this.isToday});

  final TutorLessonDto lesson;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String body) = lesson.isFinished
        ? (
            Icons.check_rounded,
            'Buổi đã hoàn thành',
            'Báo cáo của buổi này đã được xử lý.',
          )
        : lesson.isAwaitingReport
        ? (
            Icons.mic_off_outlined,
            'Chưa có báo cáo',
            'Buổi đã dạy xong nhưng chưa có báo cáo gửi phụ huynh.',
          )
        : (
            Icons.mic_none_rounded,
            'Chưa ghi âm buổi này',
            isToday
                ? 'Bấm ghi khi bắt đầu dạy.'
                : 'Nút ghi âm sẽ hiện vào ngày học.',
          );
    final done = lesson.isFinished;
    final fg = done ? TutorColors.success : TutorColors.primary;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: done ? TutorColors.successBg : TutorColors.primaryBg,
        border: Border.all(
          color: done ? TutorColors.successBorder : TutorColors.primaryBorder,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TutorType.rowSub(color: fg)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: TutorType.caption(color: fg).copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(15)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: TutorColors.surface,
      border: Border.all(color: TutorColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.sub,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TutorColors.ink4),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TutorType.rowTitle()),
                if (sub != null) Text(sub!, style: TutorType.caption()),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(trailing!, style: TutorType.caption()),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TutorType.caption().copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: TutorColors.surface,
        shape: const CircleBorder(side: BorderSide(color: TutorColors.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 20, color: TutorColors.ink),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = TutorColors.ink3,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 5),
              Text(label, style: TutorType.caption(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
