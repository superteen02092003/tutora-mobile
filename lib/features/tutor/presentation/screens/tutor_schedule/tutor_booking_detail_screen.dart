import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Chi tiết một buổi trong lớp — design V5.6: nút quay lại tròn, thẻ bo 20,
/// hàng khoá–giá trị kẻ mảnh, nút viên thuốc.
class TutorBookingDetailScreen extends StatelessWidget {
  const TutorBookingDetailScreen({required this.lesson, super.key});

  final TutorLessonDto lesson;

  String get _chipLabel => lessonChip(lesson.status).$1;

  // BE trả `in_progress` có gạch dưới — bản cũ so sai với 'inprogress'.
  String get _s => lesson.status.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final dt = lesson.startDt;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: bottomPad + 32),
            children: [
              CanvasHeader(
                title: 'Chi tiết buổi dạy',
                onBack: () => Navigator.of(context).pop(),
                trailing: CanvasTag(_chipLabel),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  18,
                  TutorSurface.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(lesson: lesson),
                    const SizedBox(height: 12),

                    // Buổi phụ / buổi học lại: giải thích buổi này từ đâu ra.
                    if (lesson.linkLabel != null) ...[
                      _LinkedSessionNote(lesson: lesson),
                      const SizedBox(height: 12),
                    ],

                    // Học sinh
                    _InfoCard(
                      child: Row(
                        children: [
                          _Avatar(name: lesson.studentName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.studentName,
                                  style: TutorType.rowTitle(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Học sinh · ${lesson.subjectName}',
                                  style: TutorType.rowSub(),
                                ),
                              ],
                            ),
                          ),
                          _PillBtn(label: 'Nhắn tin', onTap: () {}),
                        ],
                      ),
                    ),
                    const SizedBox(height: TutorSurface.sectionGap),

                    // Tiến trình
                    Text('Tiến trình', style: TutorType.sectionTitle()),
                    const SizedBox(height: 12),
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _TimelineStep(
                            label: 'Đã xếp lịch',
                            done: true,
                            isLast: false,
                          ),
                          _TimelineStep(
                            label: 'Đang diễn ra',
                            done: const {
                              'in_progress',
                              'inprogress',
                              'pending_confirmation',
                              'completed',
                              'disputed',
                            }.contains(_s),
                            isLast: false,
                          ),
                          // Chờ xác nhận = báo cáo đã gửi, chưa xong hẳn.
                          _TimelineStep(
                            label: 'Chờ xác nhận',
                            done: const {
                              'pending_confirmation',
                              'completed',
                            }.contains(_s),
                            isLast: false,
                          ),
                          _TimelineStep(
                            label: 'Hoàn thành',
                            done: _s == 'completed',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TutorSurface.sectionGap),

                    // Ngày / giờ / hình thức
                    _KvRow(
                      label: 'Ngày',
                      value: dt != null
                          ? '${dt.day} tháng ${dt.month}, ${dt.year}'
                          : '—',
                    ),
                    _KvRow(
                      label: 'Giờ',
                      value: '${lesson.timeStart} – ${lesson.timeEnd}',
                    ),
                    if (lesson.teachingMode != null)
                      _KvRow(label: 'Hình thức', value: lesson.teachingMode!),
                    Container(height: 1, color: TutorColors.line),
                    const SizedBox(height: 18),

                    // Bỏ ghi chú escrow: mâu thuẫn với thẻ trạng thái bên dưới.
                    if (_s == 'completed')
                      const _StatusNote(
                        icon: Icons.check_circle_outline_rounded,
                        text: 'Buổi học đã hoàn thành',
                      ),
                    // Các trạng thái này ảnh hưởng tới tiền nên phải nói rõ.
                    if (_s == 'disputed')
                      const _StatusNote(
                        icon: Icons.gavel_rounded,
                        text:
                            'Buổi học đang tranh chấp — tiền bị giữ tới khi '
                            'được xử lý.',
                        warning: true,
                      ),
                    if (const {'no_show', 'cancelled_noshow'}.contains(_s))
                      const _StatusNote(
                        icon: Icons.person_off_outlined,
                        text: 'Buổi học không diễn ra do có bên vắng mặt.',
                        warning: true,
                      ),
                    if (_s == 'cancelled')
                      const _StatusNote(
                        icon: Icons.cancel_outlined,
                        text: 'Buổi học đã bị huỷ',
                        warning: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

/// Thẻ sage nổi: môn, ngày, giờ.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.lesson});

  final TutorLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    final dt = lesson.startDt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: TutorSurface.sage(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson.subjectName, style: TutorType.display(size: 22)),
          if (dt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${dt.day} tháng ${dt.month}, ${dt.year}',
              style: TutorType.rowSub(),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: TutorColors.ink3,
              ),
              const SizedBox(width: 6),
              Text(
                '${lesson.timeStart} – ${lesson.timeEnd}',
                style: TutorType.rowTitle(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: TutorSurface.cardPadding,
      decoration: TutorSurface.card(),
      child: child,
    );
  }
}

/// Hàng "Nhãn ........ giá trị" kẻ mảnh phía trên.
class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: Border(top: TutorSurface.rule)),
      child: Row(
        children: [
          Text(label, style: TutorType.rowSub()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TutorType.rowTitle().copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghi chú trạng thái cuối trang. Màu cảnh báo chỉ cho trạng thái ảnh hưởng
/// tới tiền / buổi không diễn ra.
class _StatusNote extends StatelessWidget {
  const _StatusNote({
    required this.icon,
    required this.text,
    this.warning = false,
  });

  final IconData icon;
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final fg = warning ? TutorStatusTone.attention : TutorColors.ink;
    return Container(
      width: double.infinity,
      padding: TutorSurface.cardPadding,
      decoration: BoxDecoration(
        color: warning ? TutorStatusTone.attentionBg : TutorColors.sage,
        borderRadius: BorderRadius.circular(TutorSurface.radius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TutorType.rowTitle(color: fg)),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: TutorColors.sage,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(initials, style: TutorType.display(size: 16)),
    );
  }
}

class _PillBtn extends StatelessWidget {
  const _PillBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          // Theme app đặt minimumSize rộng vô hạn cho nút.
          minimumSize: const Size(0, 36),
          backgroundColor: TutorColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(),
          textStyle: TutorType.action(),
        ),
        child: Text(label),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.done,
    required this.isLast,
  });

  final String label;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? TutorColors.ink : null,
                border: done
                    ? null
                    : Border.all(color: const Color(0xFFA3A8A2), width: 1.6),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 20,
                color: done ? TutorColors.ink : const Color(0x241F2A24),
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 10),
          child: Text(
            label,
            style: done ? TutorType.rowTitle() : TutorType.rowSub(),
          ),
        ),
      ],
    );
  }
}

/// Ghi chú cho buổi không nằm trong lịch gốc
class _LinkedSessionNote extends StatelessWidget {
  const _LinkedSessionNote({required this.lesson});

  final TutorLessonDto lesson;

  String get _body {
    if (lesson.isDisputeRelearn) {
      return 'Buổi học được tạo ra để học lại sau khi tranh chấp được hoà giải. Không tính '
          'thêm vào số buổi của gói.';
    }
    if (lesson.skipConfirmedByBothSides) {
      return 'Buổi phụ này đã được hai bên đồng ý bỏ.';
    }
    return 'Buổi học được tạo ra để học tiếp phần còn dở của buổi bị ngắt giữa chừng. '
        'Không tính thêm vào số buổi của gói.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: TutorSurface.well().copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.link_rounded, size: 18, color: TutorColors.ink3),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.linkLabel!,
                  style: TutorType.rowTitle().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(_body, style: TutorType.rowSub()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
