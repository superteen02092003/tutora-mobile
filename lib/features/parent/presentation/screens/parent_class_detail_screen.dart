import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/parent/presentation/screens/parent_session_detail_screen.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_page_header.dart';
import 'package:tutora/shared/models/class_models.dart';
import 'package:tutora/shared/widgets/class_widgets.dart';

/// Chi tiết một lớp học của con: thông tin lớp + danh sách buổi.
/// Bấm một buổi để xem chi tiết buổi đó.
class ParentClassDetailScreen extends ConsumerWidget {
  const ParentClassDetailScreen({required this.klass, super.key});

  final StudentClassDto klass;

  void _openSession(BuildContext context, int classSessionId) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ParentSessionDetailScreen(lessonId: classSessionId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // Hiện cả buổi giữ chỗ: phụ huynh đã trả cọc nên phải xem được lịch dự kiến,
    // pill trạng thái đã nói rõ buổi nào chưa mở.
    final chains = groupClassSessionChains(klass.sessions);
    final hasExtra = chains.any(
      (c) => c.parent.isExtra || c.children.isNotEmpty,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ParentPageHeader(title: 'Chi tiết lớp học'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 24),
                children: [
                  _ClassSummary(klass: klass),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Các buổi học',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (hasExtra) const _ExtraSessionLegend(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bấm vào một buổi để xem báo cáo của gia sư.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (chains.isEmpty)
                    Text(
                      'Lớp chưa có buổi nào được mở.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink3,
                      ),
                    )
                  else
                    for (final chain in chains) ...[
                      _SessionCard(
                        session: chain.parent,
                        onTap: () =>
                            _openSession(context, chain.parent.classSessionId),
                      ),
                      // Buổi phụ thụt vào để thấy rõ nó bám buổi ngay trên.
                      for (final child in chain.children)
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: _SessionCard(
                            session: child,
                            nested: true,
                            onTap: () =>
                                _openSession(context, child.classSessionId),
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khối đầu màn: môn, gia sư, trạng thái, tiến độ, buổi tới.
class _ClassSummary extends StatelessWidget {
  const _ClassSummary({required this.klass});

  final StudentClassDto klass;

  @override
  Widget build(BuildContext context) {
    final k = klass;
    return Container(
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
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.title,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (k.tutorName?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Gia sư ${k.tutorName}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(style: classChipStyle(k.statusType)),
          ),
          const SizedBox(height: 16),
          _Progress(klass: k),
          if (k.gradeName?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            _InfoLine(label: 'Khối lớp', value: k.gradeName!),
          ],
          if (k.durationMinutes != null)
            _InfoLine(
              label: 'Mỗi buổi',
              value: '${k.durationMinutes} phút',
            ),
          if (k.needsRemainingPayment)
            const _InfoLine(
              label: 'Thanh toán',
              value: 'Cần trả phí các buổi còn lại',
            ),
        ],
      ),
    );
  }
}

/// Tiến độ lớp. countedSessions chỉ đếm buổi đã trả tiền nên lớp mới trả cọc sẽ
/// ra "1/1" — lấy tổng buổi của lớp và tách riêng phần chờ trả phí.
class _Progress extends StatelessWidget {
  const _Progress({required this.klass});

  final StudentClassDto klass;

  @override
  Widget build(BuildContext context) {
    final total = klass.totalSessions ?? klass.sessions.length;
    final done = klass.doneSessions;
    final locked = klass.sessions.where((s) => s.isLocked).length;
    final label = locked > 0
        ? 'Đã học $done/$total buổi · $locked buổi chờ thanh toán'
        : 'Đã học $done/$total buổi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (done / total).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.cream2,
            valueColor: const AlwaysStoppedAnimation(AppColors.oxblood),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

/// Chú thích màu cho buổi sinh thêm, chỉ hiện khi lớp thực sự có buổi phụ.
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
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Buổi học phụ',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
        ),
      ],
    );
  }
}

/// Một buổi học trong lớp. `nested` = buổi phụ / học lại bám buổi ngay trên.
class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onTap,
    this.nested = false,
  });

  final ClassSessionSlotDto session;
  final VoidCallback onTap;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    // Buổi phụ KHÔNG có số thứ tự trong gói: đánh "Buổi 6" cho một buổi bù
    // khiến phụ huynh tưởng gói dài thêm một buổi.
    final isExtra = session.isExtra;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isExtra ? AppColors.gold : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isExtra ? AppColors.cream2 : AppColors.cream,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: isExtra
                    ? const Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 20,
                        color: AppColors.ink3,
                      )
                    : Text(
                        '${session.sessionIndex}',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink2,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.weekdayLabel}, ${session.dateLabel}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.timeRange,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink3,
                      ),
                    ),
                    // Nói rõ buổi này từ đâu ra, nếu không nó chỉ là một dòng
                    // lạ xen giữa lịch.
                    if (isExtra) ...[
                      const SizedBox(height: 3),
                      Text(
                        session.isDisputeRelearn
                            ? 'Buổi học lại sau khiếu nại'
                            : nested
                            ? 'Buổi phụ · học nốt buổi trên'
                            : 'Buổi phụ · học nốt buổi gốc',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    StatusPill(style: sessionChipStyle(session.state)),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.ink4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
