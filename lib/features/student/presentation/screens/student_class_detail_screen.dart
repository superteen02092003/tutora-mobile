import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/data/datasources/class_session_datasource.dart';
import 'package:tutora/features/student/data/datasources/material_datasource.dart';
import 'package:tutora/features/student/data/models/class_models.dart';
import 'package:tutora/features/student/presentation/providers/class_provider.dart';
import 'package:tutora/features/student/presentation/providers/material_provider.dart';
import 'package:tutora/features/student/presentation/screens/student_booking_detail_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_session_detail_screen.dart';
import 'package:tutora/features/student/presentation/widgets/class_widgets.dart';
import 'package:tutora/features/student/presentation/widgets/reschedule_sheet.dart';
import 'package:tutora/shared/live_session/live_session_call_screen.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';
import 'package:url_launcher/url_launcher.dart';

/// Chi tiết một lớp học (kỳ học với 1 gia sư) — header tiến độ + danh sách buổi.
class StudentClassDetailPage extends ConsumerWidget {
  const StudentClassDetailPage({required this.bookingId, super.key});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classDetailProvider(bookingId));
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Column(
            children: [
              _NavBar(title: 'Lớp học'),
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
              const _NavBar(title: 'Lớp học'),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Không tải được lớp học',
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
                                ref.invalidate(classDetailProvider(bookingId)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (klass) => _Content(
            klass: klass,
            onRefresh: () async {
              ref.invalidate(classDetailProvider(bookingId));
              await ref.read(classListProvider.notifier).refresh();
            },
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({required this.klass, required this.onRefresh});

  final StudentClassDto klass;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  StudentClassDto get klass => widget.klass;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NavBar(title: klass.title),
        _ClassTabs(
          selected: _tabs.index,
          onSelect: (i) => _tabs.animateTo(i),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _InfoTab(
                klass: klass,
                onRefresh: widget.onRefresh,
                onReschedule: _openReschedule,
                onJoin: _joinRoom,
              ),
              MaterialsTab(bookingId: klass.bookingId),
            ],
          ),
        ),
      ],
    );
  }

  /// Tham số [sheetContext] chỉ dùng để mở sheet; các thông báo sau await dùng
  /// context của chính State này (đi kèm `mounted`) để không giữ context cũ.
  Future<void> _openReschedule(
    BuildContext sheetContext,
    ClassSessionSlotDto session,
  ) async {
    final picked = await showRescheduleSheet(
      sheetContext,
      currentStart: session.startDt,
      currentEnd: session.endDt,
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(classSessionDatasourceProvider)
          .proposeReschedule(
            classSessionId: session.classSessionId,
            proposedStart: picked.start,
            reason: picked.reason,
          );
      if (!mounted) return;
      await widget.onRefresh();
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Đã gửi đề xuất đổi lịch tới gia sư.',
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

  void _joinRoom(BuildContext context, ClassSessionSlotDto session) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LiveSessionCallScreen(
            classSessionId: session.classSessionId,
            tutorName: klass.tutorName,
          ),
        ),
      ),
    );
  }
}

/// Tab "Thông tin" — tiến độ, gia sư, thông tin lớp và danh sách buổi học.
class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.klass,
    required this.onRefresh,
    required this.onReschedule,
    required this.onJoin,
  });

  final StudentClassDto klass;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext, ClassSessionSlotDto) onReschedule;
  final void Function(BuildContext, ClassSessionSlotDto) onJoin;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final upcoming = klass.sessions
        .where((s) => s.isCounted && !s.isFinished)
        .toList();
    final past = klass.sessions
        .where((s) => s.isFinished)
        .toList()
        .reversed
        .toList();
    // Buổi `reserved` chờ mở khoá tách riêng — không trộn vào "sắp tới" (chưa
    // vào học được) cũng không phải "đã hủy".
    final locked = klass.sessions.where((s) => s.isLocked).toList();
    final cancelled = klass.sessions
        .where((s) => !s.isCounted && !s.isLocked)
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.oxblood,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomInset + 24),
        children: [
          _ProgressHeader(klass: klass),
          _TutorRow(klass: klass),
          _InfoGrid(klass: klass),
          if (klass.needsRemainingPayment) _PaymentNotice(klass: klass),
          if (upcoming.isNotEmpty) ...[
            _SectionTitle(
              title: 'BUỔI SẮP TỚI',
              trailing: '${upcoming.length} buổi',
            ),
            ..._sessionCards(context, upcoming),
          ],
          if (past.isNotEmpty) ...[
            _SectionTitle(
              title: 'ĐÃ HỌC',
              trailing: '${past.length} buổi',
            ),
            ..._sessionCards(context, past),
          ],
          if (locked.isNotEmpty) ...[
            _SectionTitle(
              title: 'CHỜ MỞ KHOÁ',
              trailing: '${locked.length} buổi',
            ),
            ..._lockedCards(locked),
          ],
          if (cancelled.isNotEmpty) ...[
            const _SectionTitle(title: 'ĐÃ HỦY / VẮNG'),
            ..._sessionCards(context, cancelled),
          ],
          if (klass.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyState(
                message: klass.statusType == ClassStatusType.pendingTutor
                    ? 'Lớp đang chờ gia sư xác nhận. Các buổi học sẽ xuất hiện sau khi gia sư đồng ý.'
                    : 'Lớp chưa có buổi học nào được xếp lịch.',
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _lockedCards(List<ClassSessionSlotDto> sessions) => [
    for (final s in sessions)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _LockedSessionCard(session: s),
      ),
  ];

  List<Widget> _sessionCards(
    BuildContext context,
    List<ClassSessionSlotDto> sessions,
  ) => [
    for (final s in sessions)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SessionCard(
          session: s,
          tutorName: '${s.weekdayLabel} · ${s.timeRange}',
          onReschedule: () => onReschedule(context, s),
          onJoin: () => onJoin(context, s),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  StudentSessionDetailPage(lessonId: s.classSessionId),
            ),
          ),
        ),
      ),
  ];
}

/// Buổi `reserved` — hiển thị mờ, không bấm được, không có nút hành động.
class _LockedSessionCard extends StatelessWidget {
  const _LockedSessionCard({required this.session});

  final ClassSessionSlotDto session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  session.timeStart,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.dateLabel,
                  style: GoogleFonts.inter(fontSize: 9, color: AppColors.ink4),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.sessionIndex > 0
                      ? 'Buổi ${session.sessionIndex}'
                      : 'Buổi học',
                  style: GoogleFonts.ibmPlexSerif(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.weekdayLabel} · ${session.timeRange}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: AppColors.ink4,
          ),
        ],
      ),
    );
  }
}

// Tabs: Thông tin · Tài liệu

class _ClassTabs extends StatelessWidget {
  const _ClassTabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const _labels = ['Thông tin', 'Tài liệu'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.cream : AppColors.ink3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Tab "Tài liệu" — tài liệu và bài tập gia sư gửi cho lớp này.
class MaterialsTab extends ConsumerWidget {
  const MaterialsTab({required this.bookingId, super.key});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materialListProvider(bookingId));
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.oxblood,
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Không tải được tài liệu', style: AppTextStyles.label()),
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
                  onTap: () => ref.invalidate(materialListProvider(bookingId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (materials) {
        if (materials.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              message:
                  'Chưa có tài liệu nào. Tài liệu và bài tập gia sư gửi sẽ hiện ở đây.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(materialListProvider(bookingId)),
          color: AppColors.oxblood,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 24),
            itemCount: materials.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _MaterialCard(
              material: materials[i],
              onTap: () => unawaited(_openMaterial(context, materials[i])),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMaterial(
    BuildContext context,
    LearningMaterialDto material,
  ) async {
    final uri = Uri.tryParse(material.fileUrl);
    if (uri == null || material.fileUrl.isEmpty) {
      AppToast.show(
        context,
        message: 'Tài liệu này không có liên kết hợp lệ.',
        type: AppToastType.error,
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.show(
        context,
        message: 'Không mở được tài liệu.',
        type: AppToastType.error,
      );
    }
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material, required this.onTap});

  final LearningMaterialDto material;
  final VoidCallback onTap;

  ({Color bg, Color fg, IconData icon}) get _visual => switch (material.kind) {
    MaterialKind.pdf => (
      bg: const Color(0xFFF5E9E9),
      fg: AppColors.oxblood,
      icon: Icons.picture_as_pdf_rounded,
    ),
    MaterialKind.doc => (
      bg: const Color(0xFFE8F0FE),
      fg: const Color(0xFF3D6EEA),
      icon: Icons.description_rounded,
    ),
    MaterialKind.sheet => (
      bg: const Color(0xFFE0E7DF),
      fg: AppColors.green,
      icon: Icons.table_chart_rounded,
    ),
    MaterialKind.slide => (
      bg: const Color(0xFFF0E3CA),
      fg: const Color(0xFF5C3A1A),
      icon: Icons.slideshow_rounded,
    ),
    MaterialKind.image => (
      bg: const Color(0xFFEFF3EE),
      fg: AppColors.moss,
      icon: Icons.image_rounded,
    ),
    MaterialKind.video => (
      bg: const Color(0xFFF5E9E9),
      fg: AppColors.oxblood,
      icon: Icons.play_circle_rounded,
    ),
    MaterialKind.archive => (
      bg: AppColors.cream2,
      fg: AppColors.ink3,
      icon: Icons.folder_zip_rounded,
    ),
    MaterialKind.other => (
      bg: AppColors.cream2,
      fg: AppColors.ink3,
      icon: Icons.insert_drive_file_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final v = _visual;
    final meta = [
      if (material.extension.isNotEmpty) material.extension.toUpperCase(),
      if (material.sizeLabel != null) material.sizeLabel!,
      if (material.createdLabel.isNotEmpty) material.createdLabel,
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: v.bg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(v.icon, size: 20, color: v.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: GoogleFonts.ibmPlexSerif(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (material.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 3),
                    Text(
                      material.description!,
                      style: AppTextStyles.bodySmall(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        color: AppColors.ink3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.download_rounded,
              size: 17,
              color: AppColors.ink3,
            ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// Progress header

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.klass});
  final StudentClassDto klass;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              ProgressRing(
                progress: klass.progress,
                size: 76,
                strokeWidth: 7,
                color: AppColors.gold,
                trackColor: AppColors.cream.withValues(alpha: 0.16),
                child: Text(
                  '${klass.progressPercent}%',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.cream,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIẾN ĐỘ LỚP HỌC',
                      style: AppTextStyles.eyebrow(color: AppColors.gold),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${klass.doneSessions}',
                            style: GoogleFonts.bricolageGrotesque(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              height: 1,
                              color: AppColors.cream,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${klass.countedSessions} buổi',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cream.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      klass.remainingSessions == 0
                          ? 'Đã hoàn thành toàn bộ lớp học'
                          : 'Còn ${klass.remainingSessions} buổi nữa',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.cream.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Tutor row

class _TutorRow extends StatelessWidget {
  const _TutorRow({required this.klass});
  final StudentClassDto klass;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          UserAvatar(name: klass.tutorName ?? 'GS', size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        klass.tutorName ?? 'Gia sư',
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
                const SizedBox(height: 2),
                Text(
                  'Gia sư phụ trách lớp',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(style: classChipStyle(klass.statusType)),
        ],
      ),
    );
  }
}

// Info grid

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.klass});
  final StudentClassDto klass;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi_VN');
    final rows = <({IconData icon, String label, String value})>[
      if (klass.scheduleLabel.isNotEmpty)
        (
          icon: Icons.repeat_rounded,
          label: 'Lịch hằng tuần',
          value: klass.scheduleLabel,
        ),
      if (klass.startDateDt != null)
        (
          icon: Icons.play_circle_outline_rounded,
          label: 'Bắt đầu',
          value: DateFormat('dd/MM/yyyy').format(klass.startDateDt!),
        ),
      (
        icon: Icons.timer_outlined,
        label: 'Thời lượng mỗi buổi',
        value: '${klass.durationMinutes ?? 60} phút',
      ),
      if (klass.finalPrice != null && klass.finalPrice! > 0)
        (
          icon: Icons.payments_outlined,
          label: 'Học phí lớp',
          value: '${money.format(klass.finalPrice)} đ',
        ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('THÔNG TIN LỚP', style: AppTextStyles.eyebrow()),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudentBookingDetailScreen(
                      bookingId: klass.bookingId,
                    ),
                  ),
                ),
                child: Text(
                  'Hợp đồng & thanh toán',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: AppColors.oxblood,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 14 : 0),
              child: Row(
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

// Payment notice

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice({required this.klass});
  final StudentClassDto klass;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi_VN');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E3CA),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFE0D2A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 16,
            color: AppColors.oxblood,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa thanh toán phần còn lại',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C3A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  klass.remainingAmount != null && klass.remainingAmount! > 0
                      ? 'Còn ${money.format(klass.remainingAmount)} đ. Các buổi tiếp theo sẽ mở khi phụ huynh thanh toán xong.'
                      : 'Các buổi tiếp theo sẽ mở khi phụ huynh thanh toán xong.',
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

// Section title

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.eyebrow(color: AppColors.ink3)),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink3,
              ),
            ),
        ],
      ),
    );
  }
}
