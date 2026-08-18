import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/screens/parent_class_detail_screen.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_child_avatar_strip.dart';
import 'package:tutora/shared/models/class_models.dart';
import 'package:tutora/shared/widgets/class_widgets.dart';

/// Tab "Lớp học" của phụ huynh: chọn con → danh sách lớp → mở lớp xem các buổi.
/// Phụ huynh CHỈ theo dõi, không có nút vào phòng học.
class ParentClassesScreen extends ConsumerStatefulWidget {
  const ParentClassesScreen({super.key});

  @override
  ConsumerState<ParentClassesScreen> createState() =>
      _ParentClassesScreenState();
}

class _ParentClassesScreenState extends ConsumerState<ParentClassesScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() => ref.read(parentStudentsProvider.notifier).load()),
    );
  }

  /// Lớp phải xem theo con, nên luôn cần một con được chọn.
  String? _effectiveId(List<ParentStudentDto> students) {
    if (_selectedId != null) return _selectedId;
    return students.isEmpty ? null : students.first.studentId;
  }

  Future<void> _refresh(String? studentId) async {
    if (studentId != null) {
      ref.invalidate(parentChildClassesProvider(studentId));
    }
    await ref.read(parentStudentsProvider.notifier).load();
  }

  void _openClass(StudentClassDto klass) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ParentClassDetailScreen(klass: klass),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(parentStudentsProvider);
    final students = studentsState.students;
    final selectedId = _effectiveId(students);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final classesAsync = selectedId == null
        ? const AsyncValue<List<StudentClassDto>>.data([])
        : ref.watch(parentChildClassesProvider(selectedId));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
              child: Text(
                'Lớp học',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            // Màn này chỉ để xem lớp: không thêm con, không chuông, không lặp
            // lại tên con (đã có ở chip đang chọn).
            ParentChildAvatarStrip(
              students: students,
              isLoading: studentsState.isLoading,
              selectedId: selectedId,
              // Không cho bỏ chọn: danh sách lớp phải thuộc về một con cụ thể.
              onSelect: (id) => setState(() => _selectedId = id),
              onAddChild: () {},
              onNotif: () {},
              showAddChild: false,
              showNotif: false,
              showSelectedInfo: false,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.oxblood,
                backgroundColor: AppColors.paper,
                onRefresh: () => _refresh(selectedId),
                child: classesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.oxblood,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (_, _) => ListView(
                    children: const [
                      _Empty(
                        icon: Icons.wifi_off_rounded,
                        title: 'Không tải được lớp học',
                        message: 'Kéo xuống để thử lại.',
                      ),
                    ],
                  ),
                  data: (all) {
                    // Chờ gia sư nhận thì chưa thành lớp — nằm ở "Lịch đặt của
                    // tôi", không phải tab Lớp học.
                    final classes = all
                        .where((k) => !k.isAwaitingDeposit)
                        .toList();
                    if (students.isEmpty) {
                      return ListView(
                        children: const [
                          _Empty(
                            icon: Icons.person_add_alt_1_rounded,
                            title: 'Chưa có con nào',
                            message:
                                'Thêm thông tin con để bắt đầu đặt lịch học.',
                          ),
                        ],
                      );
                    }
                    if (classes.isEmpty) {
                      // Có đơn nhưng gia sư chưa nhận: nói rõ đang chờ, đừng bảo
                      // phụ huynh đi đặt lại.
                      final waiting = all.any((k) => k.isAwaitingDeposit);
                      return ListView(
                        children: [
                          _Empty(
                            icon: waiting
                                ? Icons.hourglass_empty_rounded
                                : Icons.school_outlined,
                            title: waiting
                                ? 'Đang chờ gia sư nhận lớp'
                                : 'Chưa có lớp học',
                            message: waiting
                                ? 'Lớp sẽ hiện ở đây ngay khi gia sư nhận. '
                                      'Xem đơn đã đặt ở mục Lịch đặt của tôi.'
                                : 'Tìm gia sư và đặt lịch để mở lớp đầu tiên.',
                          ),
                        ],
                      );
                    }

                    // Lớp đang học lên trước, lớp đã xong xuống dưới.
                    final sorted = [
                      ...classes.where((k) => k.isOngoing),
                      ...classes.where((k) => !k.isOngoing),
                    ];
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 24),
                      itemCount: sorted.length,
                      itemBuilder: (_, i) => _ClassCard(
                        klass: sorted[i],
                        onTap: () => _openClass(sorted[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card một lớp trong danh sách. Bấm để mở màn chi tiết lớp.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.klass, required this.onTap});

  final StudentClassDto klass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = klass;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                  SubjectIcon(
                    iconUrl: k.subjectIconUrl,
                    subjectName: k.subjectName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (k.tutorName?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Gia sư ${k.tutorName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.ink4,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(style: classChipStyle(k.statusType)),
              ),
              const SizedBox(height: 14),
              _ProgressLine(klass: k),
              if (k.nextSession != null) ...[
                const SizedBox(height: 12),
                _NextRow(session: k.nextSession!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiến độ dạng "3/8 buổi" kèm thanh ngang — dễ đọc hơn vòng tròn phần trăm.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.klass});

  final StudentClassDto klass;

  @override
  Widget build(BuildContext context) {
    // countedSessions chỉ đếm buổi ĐÃ TRẢ TIỀN nên lớp mới trả cọc sẽ ra "1/1" —
    // đọc thành đã học xong. Lấy tổng buổi của lớp và tách riêng phần chờ trả phí.
    final total = klass.totalSessions ?? klass.sessions.length;
    final done = klass.doneSessions;
    final locked = klass.sessions.where((s) => s.isLocked).length;
    final label = locked > 0
        ? 'Đã học $done/$total buổi · $locked buổi chờ thanh toán'
        : 'Đã học $done/$total buổi';

    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.cream2,
            valueColor: const AlwaysStoppedAnimation(AppColors.oxblood),
          ),
        ),
      ],
    );
  }
}

/// Dòng "Buổi tới" trên card lớp.
class _NextRow extends StatelessWidget {
  const _NextRow({required this.session});

  final ClassSessionSlotDto session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_rounded,
            size: 18,
            color: AppColors.oxblood,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buổi tới: ${session.weekdayLabel} ${session.dateLabel}'
              ' · ${session.timeRange}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.ink4),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}
