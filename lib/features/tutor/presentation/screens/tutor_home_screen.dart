import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_booking_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dashboard_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_class_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/notification_bell.dart';

/// Trang chủ gia sư — bản tối giản theo prototype "Home":
/// lời chào + avatar, "Hôm nay · N buổi" (buổi kế tiếp có nút ghi âm),
/// và "Lớp của bạn" để quản lý lớp.
class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  static String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? '' : parts.last;
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(tutorBookingsProvider)
      ..invalidate(tutorClassesProvider)
      ..invalidate(recorderStudentsProvider)
      ..invalidate(recorderPendingReviewsProvider)
      ..invalidate(recorderTodayLessonsProvider);
    await ref.read(tutorDashboardProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(tutorProfileProvider);
    final dash = ref.watch(tutorDashboardProvider);

    final name = profile.user?.fullName ?? '';
    final first = _firstName(name);
    final data = dash.data;
    final loading = dash.isLoading && data == null;
    final studentCount =
        (ref.watch(recorderStudentsProvider).valueOrNull ?? const []).length;
    // Buổi hôm nay của học sinh ngoài nền tảng, chưa ghi âm xong.
    final offPlatformToday =
        (ref.watch(recorderTodayLessonsProvider).valueOrNull ?? const [])
            .where(
              (s) => const {
                'scheduled',
                'recording',
                'uploading',
              }.contains(s.recorderStatus),
            )
            .toList();

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: TutorColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TutorSurface.gutter,
              20,
              TutorSurface.gutter,
              32,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: CanvasKicker(
                      [
                        if (first.isNotEmpty) 'Gia sư $first',
                        '$studentCount học sinh',
                      ].join(' · '),
                      color: TutorColors.ink,
                    ),
                  ),
                  // Chuông thông báo: số chưa đọc hiện ngay trên icon.
                  IconButton(
                    tooltip: 'Thông báo',
                    onPressed: () => context.push(AppRoutes.tutorNotifications),
                    icon: const NotificationBadge(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 26,
                        color: TutorColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _AvatarButton(
                    initial: first.isEmpty ? '?' : first[0].toUpperCase(),
                    badge: false,
                    onTap: () => context.push(AppRoutes.tutorProfile),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Tiến độ của bạn', style: TutorType.display()),
              const SizedBox(height: 20),
              // Báo cáo AI chờ duyệt — gửi phụ huynh càng sớm càng tốt.
              const _PendingReviewsSection(),
              const _ProgressSection(),
              const SizedBox(height: 20),
              CanvasOutlineCard(
                onTap: () => context.go(AppRoutes.tutorPath),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CanvasKicker(
                            'Lộ trình của bạn · 3 chặng',
                            color: TutorColors.warning,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tới chuẩn TopTutor',
                            style: TutorType.display(
                              size: 22,
                              weight: FontWeight.w700,
                              color: TutorColors.ink,
                              height: 1.2,
                            ).copyWith(letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Xem bạn đang ở đâu và bước tiếp theo',
                            style: TutorType.rowSub().copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const CanvasChevron(),
                  ],
                ),
              ),
              const _FocusSection(),
              const SizedBox(height: 28),
              if (loading)
                const TutorSkeleton(height: 200, radius: 14)
              else
                _TodaySection(
                  sessions: [
                    ...sessionsToday(data?.todaySessions ?? const []),
                    ...offPlatformToday,
                  ],
                ),
              const SizedBox(height: 28),
              const _ClassesSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.initial,
    required this.badge,
    required this.onTap,
  });

  final String initial;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tôi',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Initial(text: initial, size: 38, fontSize: 14),
              if (badge)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: TutorColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: TutorColors.bg, width: 2),
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

/// Vòng tròn chữ cái đầu (nền #F2F0E4, viền line).
class _Initial extends StatelessWidget {
  const _Initial({required this.text, this.size = 42, this.fontSize = 15});

  final String text;
  final double size;
  final double fontSize;

  static String of(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.split(' ').last.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TutorColors.surfaceSunken,
        shape: BoxShape.circle,
        border: Border.all(color: TutorColors.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: TutorColors.ink,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: TutorColors.ink,
              ),
            ),
          ),
          if (action != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: TutorColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDeco() => BoxDecoration(
  color: TutorColors.surface,
  border: Border.all(color: TutorColors.line),
  borderRadius: BorderRadius.circular(14),
);

// ── Hôm nay ────────────────────────────────────────────────────────────────

enum _Chip { next, later, live, done }

class _TodaySection extends StatelessWidget {
  const _TodaySection({required this.sessions});

  final List<TutorTodaySessionDto> sessions;

  static DateTime? _t(String iso) => DateTime.tryParse(iso)?.toLocal();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final list = [...sessions]
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

    // Buổi nổi bật = buổi đang dạy, hoặc buổi chưa kết thúc sớm nhất.
    TutorTodaySessionDto? featured;
    for (final s in list) {
      final end = _t(s.scheduledEnd);
      if (end == null || end.isAfter(now)) {
        featured = s;
        break;
      }
    }

    _Chip chipOf(TutorTodaySessionDto s) {
      final start = _t(s.scheduledStart);
      final end = _t(s.scheduledEnd);
      if (end != null && !end.isAfter(now)) return _Chip.done;
      if (start != null && !start.isAfter(now)) return _Chip.live;
      if (identical(s, featured)) return _Chip.next;
      return _Chip.later;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: list.isEmpty ? 'Hôm nay' : 'Hôm nay · ${list.length} buổi',
          action: 'Xem lịch',
          onAction: () => context.go(AppRoutes.tutorSchedule),
        ),
        if (list.isEmpty)
          Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _cardDeco(),
            child: Text('Hôm nay bạn rảnh.', style: TutorType.rowSub()),
          ),
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          if (identical(list[i], featured))
            _FeaturedCard(session: list[i], chip: chipOf(list[i]))
          else
            _CompactCard(session: list[i], chip: chipOf(list[i])),
        ],
      ],
    );
  }
}

String _timeRange(TutorTodaySessionDto s) => [
  if (s.subjectName.isNotEmpty) s.subjectName,
  if (s.timeStart.isNotEmpty)
    s.timeEnd.isEmpty ? s.timeStart : '${s.timeStart} – ${s.timeEnd}',
].join(' · ');

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.session, required this.chip});

  final TutorTodaySessionDto session;
  final _Chip chip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SessionHead(session: session, chip: chip),
          const SizedBox(height: 14),
          const Divider(height: 1, color: TutorColors.line),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: TutorColors.ink4,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Báo cáo sẽ gửi cho phụ huynh của ${session.studentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: TutorColors.ink4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Gợi ý Topi cho buổi này (từ buổi có báo cáo gần nhất), ngay trước
          // nút ghi âm — lúc gia sư chuẩn bị vào dạy.
          if (session.recorderStudentId != null)
            TopiStudentBeforeLessonEntry(
              studentId: session.recorderStudentId!,
              studentName: session.studentName,
              nextLessonAt: DateTime.tryParse(
                session.scheduledStart,
              )?.toLocal(),
              padding: const EdgeInsets.only(bottom: 14),
            ),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => context.push(
                AppRoutes.tutorRecording,
                extra: RecordingTarget.fromSession(session),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: TutorColors.primary,
                foregroundColor: TutorColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.mic_none_rounded, size: 18),
              label: const Text('Bắt đầu ghi âm'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.session, required this.chip});

  final TutorTodaySessionDto session;
  final _Chip chip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.tutorSchedule),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _SessionHead(session: session, chip: chip),
        ),
      ),
    );
  }
}

class _SessionHead extends StatelessWidget {
  const _SessionHead({required this.session, required this.chip});

  final TutorTodaySessionDto session;
  final _Chip chip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Initial(text: _Initial.of(session.studentName)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: TutorColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _timeRange(session),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: TutorColors.ink3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusChip(chip: chip),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.chip});

  final _Chip chip;

  @override
  Widget build(BuildContext context) {
    final (label, bg, border, fg) = switch (chip) {
      _Chip.next => (
        'Sắp tới',
        TutorColors.primaryBg,
        TutorColors.primaryBorder,
        TutorColors.primary,
      ),
      _Chip.later => (
        'Chờ',
        TutorColors.surfaceSunken,
        TutorColors.line,
        TutorColors.ink3,
      ),
      _Chip.live => (
        'Đang dạy',
        TutorColors.successBg,
        TutorColors.successBorder,
        TutorColors.success,
      ),
      _Chip.done => (
        'Xong',
        TutorColors.successBg,
        TutorColors.successBorder,
        TutorColors.success,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

// ── Lớp của bạn ────────────────────────────────────────────────────────────

class _ClassesSection extends ConsumerWidget {
  const _ClassesSection();

  static const _maxInline = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorClassesProvider);
    final all = async.valueOrNull?.items ?? const <TutorClassDto>[];
    final sorted = _teachable(all);
    final students =
        ref.watch(recorderStudentsProvider).valueOrNull ??
        const <RecorderStudentDto>[];
    final active = sorted.length + students.length;
    final shown = sorted.take(_maxInline).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: active > 0 ? 'Lớp của bạn · $active' : 'Lớp của bạn',
          action: sorted.length > _maxInline ? 'Xem tất cả' : null,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _AllClassesPage()),
          ),
        ),
        if (async.isLoading && all.isEmpty)
          const TutorSkeleton(height: 140, radius: 14)
        else if (async.hasError && all.isEmpty)
          _EmptyCard(
            text: 'Không tải được danh sách lớp. Chạm để thử lại.',
            onTap: () => ref.invalidate(tutorClassesProvider),
          )
        else if (sorted.isNotEmpty)
          _ClassList(items: shown),
        if (sorted.isNotEmpty) const SizedBox(height: 10),
        // Học sinh ngoài nền tảng — danh bạ riêng của gia sư.
        _StudentList(students: students),
      ],
    );
  }
}

/// Chỉ lớp còn buổi để dạy (chưa kết thúc và đã có buổi kế tiếp được mở),
/// xếp theo buổi tới sớm nhất.
List<TutorClassDto> _teachable(List<TutorClassDto> all) =>
    all.where((c) => !c.isFinished && c.nextStartLocal != null).toList()
      ..sort((a, b) => a.nextStartLocal!.compareTo(b.nextStartLocal!));

class _ClassList extends StatelessWidget {
  const _ClassList({required this.items});

  final List<TutorClassDto> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: TutorColors.line, indent: 70),
              _ClassRow(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.item});

  final TutorClassDto item;

  static const _dows = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _sub() {
    if (item.isFinished) {
      return [
        if (item.subjectName.isNotEmpty) item.subjectName,
        'Đã kết thúc',
      ].join(' · ');
    }
    final next = item.nextStartLocal;
    final String when;
    if (next != null) {
      final hm =
          '${next.hour.toString().padLeft(2, '0')}:'
          '${next.minute.toString().padLeft(2, '0')}';
      when =
          'Buổi tới ${_dows[next.weekday - 1]} ${next.day}/${next.month} $hm';
    } else if (item.isWaitingRemainingPayment) {
      when = 'Chờ phụ huynh thanh toán';
    } else {
      when = item.schedule;
    }
    return [
      if (item.subjectName.isNotEmpty) item.subjectName,
      if (when.isNotEmpty) when,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final total = item.totalWithReserved;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorClassDetailScreen(item: item),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            _Initial(text: _Initial.of(item.studentName)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: item.isFinished
                          ? TutorColors.ink4
                          : TutorColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _sub(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: TutorColors.ink3,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.progress.clamp(0, 1).toDouble(),
                        minHeight: 4,
                        backgroundColor: TutorColors.surfaceSunken,
                        color: item.isFinished
                            ? TutorColors.ink4
                            : TutorColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  total > 0 ? '${item.completedSessions}/$total' : '—',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TutorColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'buổi',
                  style: TextStyle(fontSize: 12, color: TutorColors.ink4),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: TutorColors.ink4,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: TutorType.rowSub()),
        ),
      ),
    );
  }
}

/// Toàn bộ lớp — mở từ "Xem tất cả".
class _AllClassesPage extends ConsumerWidget {
  const _AllClassesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(tutorClassesProvider).valueOrNull?.items ??
        const <TutorClassDto>[];
    final active = _teachable(items);
    return Scaffold(
      backgroundColor: TutorColors.bg,
      appBar: AppBar(
        backgroundColor: TutorColors.bg,
        surfaceTintColor: Colors.transparent,
        title: const Text('Lớp của bạn'),
      ),
      body: RefreshIndicator(
        color: TutorColors.primary,
        onRefresh: () => ref.refresh(tutorClassesProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (active.isNotEmpty)
              _ClassList(items: active)
            else
              const _EmptyCard(text: 'Chưa có lớp nào đang dạy.'),
          ],
        ),
      ),
    );
  }
}

// ── Học sinh ngoài nền tảng ─────────────────────────────────────────────────

class _StudentList extends StatelessWidget {
  const _StudentList({required this.students});

  final List<RecorderStudentDto> students;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (final s in students) ...[
              InkWell(
                onTap: () =>
                    TutorStudentDetailScreen.open(context, s.studentId),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      _Initial(text: _Initial.of(s.fullName)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                color: TutorColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (s.subtitle.isNotEmpty) s.subtitle,
                                if (!s.hasConsent)
                                  'Chưa có đồng ý ghi âm'
                                else
                                  'Ngoài TopTutor',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: s.hasConsent
                                    ? TutorColors.ink3
                                    : TutorColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${s.lessonCount}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TutorColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'buổi',
                            style: TextStyle(
                              fontSize: 12,
                              color: TutorColors.ink4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: TutorColors.ink4,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: TutorColors.line, indent: 70),
            ],
            InkWell(
              onTap: () => TutorStudentFormScreen.open(context),
              child: const SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: TutorColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Thêm học sinh ngoài TopTutor',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: TutorColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Báo cáo chờ duyệt ────────────────────────────────────────────────────────

class _PendingReviewsSection extends ConsumerWidget {
  const _PendingReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(recorderPendingReviewsProvider).valueOrNull ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    // Canvas T2: mỗi báo cáo chờ duyệt là một thẻ đồng "CẦN DUYỆT", trên cùng.
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ReviewRow(lesson: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.lesson});

  final RecorderLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    final label = switch (lesson.status) {
      'awaiting_approval' => 'Cần duyệt',
      'failed' => 'AI lỗi · tự viết báo cáo',
      _ => 'AI đang viết báo cáo…',
    };
    final ready = lesson.status == 'awaiting_approval';
    final d = lesson.when;
    final date = d == null ? '' : ' · báo cáo ngày ${d.day}/${d.month}';
    return Material(
      color: ready ? TutorColors.accent : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TutorSurface.radius),
        side: ready ? BorderSide.none : TutorSurface.rule,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(context).push(
          AppRoutes.tutorReportReview,
          extra: ReportReviewArgs(
            recordingId: lesson.lessonId,
            studentName: lesson.studentName,
            subtitle: [
              if (lesson.subject != null && lesson.subject!.isNotEmpty)
                lesson.subject!,
              if (lesson.grade != null) 'Lớp ${lesson.grade}',
            ].join(' · '),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CanvasKicker(label, color: TutorColors.ink),
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.studentName}$date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TutorColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const CanvasChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tiến độ học sinh (canvas T2) ─────────────────────────────────────────────

/// Canvas: "Tiến độ học sinh · tháng N" — sao mới, kỹ năng thành thạo. Số này
/// cần Topi chạy chính thức trên mọi buổi (backend #380 chưa merge); chưa có
/// thì nói rõ, không đặt số giả.
class _ProgressSection extends StatelessWidget {
  const _ProgressSection();

  @override
  Widget build(BuildContext context) {
    final m = DateTime.now().month;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CanvasKicker('Tiến độ học sinh · tháng $m'),
          ),
          CanvasRow(
            lastRule: true,
            child: Text(
              'Số sao mới và kỹ năng đạt thành thạo sẽ hiện ở đây khi Topi chạy chính thức trên các buổi ghi âm.',
              style: TutorType.rowSub().copyWith(fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Đang tập trung · từng học sinh (canvas T2) ──────────────────────────────

/// Mỗi học sinh một thẻ: lỗ hổng đang tập trung trong kế hoạch Topi của buổi có
/// báo cáo gần nhất. Thẻ đầu tối (một khối tối mỗi màn), các thẻ sau viền mực.
/// Học sinh chưa có kế hoạch thì không hiện.
class _FocusSection extends ConsumerWidget {
  const _FocusSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(topiFlagsNowProvider).plan) return const SizedBox.shrink();
    final students =
        ref.watch(recorderStudentsProvider).valueOrNull ?? const [];
    if (students.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: CanvasKicker('Đang tập trung · từng học sinh'),
          ),
          for (var i = 0; i < students.length; i++)
            _FocusCard(student: students[i], dark: i == 0),
        ],
      ),
    );
  }
}

class _FocusCard extends ConsumerWidget {
  const _FocusCard({required this.student, required this.dark});

  final RecorderStudentDto student;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons =
        ref
            .watch(recorderStudentLessonsProvider(student.studentId))
            .valueOrNull ??
        const <RecorderLessonDto>[];
    final now = DateTime.now();
    final recorded = lessons.where((l) => l.status != 'scheduled').toList()
      ..sort((a, b) => (b.when ?? now).compareTo(a.when ?? now));
    final latest = latestReportedLesson(recorded);
    if (latest == null) return const SizedBox.shrink();
    final plan = ref
        .watch(lessonTopiProvider(latest.lessonId))
        .valueOrNull
        ?.plan;
    if (plan == null || plan.gaps.isEmpty) return const SizedBox.shrink();
    final focus = plan.gaps.firstWhere(
      (g) => g.role == 'focus',
      orElse: () => plan.gaps.first,
    );
    final upcoming =
        lessons
            .where(
              (l) => l.status == 'scheduled' && (l.when?.isAfter(now) ?? false),
            )
            .toList()
          ..sort((a, b) => a.when!.compareTo(b.when!));
    final next = upcoming.firstOrNull?.when;
    final sub = [
      if (focus.seenInLessons != null) 'Gặp trong ${focus.seenInLessons} buổi',
      if (next != null) 'buổi tới ${next.day}/${next.month}',
    ].join(' · ');
    final who = [
      student.fullName,
      if (student.grade != null) 'Lớp ${student.grade}',
    ].join(' · ');
    void open() => TopiBeforeLessonScreen.open(
      context,
      BeforeLessonArgs(
        lessonId: latest.lessonId,
        studentName: student.fullName,
        nextLessonAt: next,
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CanvasKicker(who, color: dark ? TutorColors.accent : TutorColors.ink3),
        const SizedBox(height: 2),
        Text(
          focus.title ?? focus.node ?? '',
          style: dark
              ? TutorType.display(
                  size: 22,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ).copyWith(letterSpacing: -0.5)
              : const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: TutorColors.ink,
                ),
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 14,
              color: dark ? const Color(0xFFDCE8E0) : TutorColors.ink3,
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: dark
          ? CanvasDarkCard(onTap: open, child: body)
          : CanvasOutlineCard(onTap: open, child: body),
    );
  }
}
