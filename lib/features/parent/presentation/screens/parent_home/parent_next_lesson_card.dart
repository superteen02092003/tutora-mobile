import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';

/// Dark hero card highlighting the parent's single next lesson — used at the
/// top of the home dashboard only.
class ParentNextLessonCard extends StatelessWidget {
  const ParentNextLessonCard({
    required this.lesson,
    required this.onReschedule,
    required this.onViewInfo,
    super.key,
  });

  final ParentLessonDto lesson;
  final VoidCallback onReschedule;
  final VoidCallback onViewInfo;

  String _h(int v) => v.toString().padLeft(2, '0');

  static const _months = [
    '',
    'Th1',
    'Th2',
    'Th3',
    'Th4',
    'Th5',
    'Th6',
    'Th7',
    'Th8',
    'Th9',
    'Th10',
    'Th11',
    'Th12',
  ];

  String _relativeLabel(DateTime start) {
    final diff = start.difference(DateTime.now());
    if (diff.isNegative) return '● Đang diễn ra';
    if (diff.inMinutes < 60) return '● Trong ${diff.inMinutes} phút';
    if (diff.inHours < 24) return '● Trong ${diff.inHours} giờ';
    return '● ${diff.inDays} ngày nữa';
  }

  @override
  Widget build(BuildContext context) {
    final start = lesson.startDt;
    final end = lesson.endDt;
    final isOnline = lesson.teachingMode == 'online';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: const Border(
            bottom: BorderSide(color: AppColors.gold, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.oxblood.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.ink),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.3,
                  colors: [Color(0x3AD4B483), Color(0x00D4B483)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'BUỔI HỌC SẮP TỚI',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.14,
                            color: AppColors.gold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.oxblood,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _relativeLabel(start),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.32),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _months[start.month],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.gold,
                                  letterSpacing: 0.06,
                                ),
                              ),
                              Text(
                                _h(start.day),
                                style: GoogleFonts.bricolageGrotesque(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 23,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.subjectName ?? 'Buổi học',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${lesson.tutorName ?? 'Gia sư'} · ${lesson.studentName ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_outlined,
                                    size: 13,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_h(start.hour)}:${_h(start.minute)}–${_h(end.hour)}:${_h(end.minute)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    isOnline
                                        ? Icons.videocam_outlined
                                        : Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOnline ? 'Trực tuyến' : 'Tại lớp',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
                          child: _ActionButton(
                            label: 'Đổi lịch',
                            textColor: AppColors.oxblood,
                            borderColor: AppColors.gold.withValues(alpha: 0.6),
                            onTap: onReschedule,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _ActionButton(
                            label: 'Xem thông tin',
                            textColor: AppColors.ink,
                            borderColor: AppColors.gold,
                            bold: true,
                            onTap: onViewInfo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
    this.bold = false,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              top: BorderSide(color: borderColor),
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor, width: 3),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
