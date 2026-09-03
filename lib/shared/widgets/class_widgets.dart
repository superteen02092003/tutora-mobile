import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/shared/models/class_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

typedef ChipStyle = ({Color bg, Color fg, String label});

ChipStyle classChipStyle(ClassStatusType t) => switch (t) {
  ClassStatusType.unpaid => (
    bg: const Color(0xFFF5E9E9),
    fg: AppColors.oxblood,
    label: 'Chờ trả phí buổi đầu',
  ),
  ClassStatusType.pendingTutor => (
    bg: const Color(0xFFF0E3CA),
    fg: const Color(0xFF5C3A1A),
    label: 'Chờ gia sư nhận lớp',
  ),
  ClassStatusType.depositPaid => (
    bg: const Color(0xFFE0E7FF),
    fg: const Color(0xFF3730A3),
    label: 'Đã thanh toán buổi đầu',
  ),
  ClassStatusType.pendingRemaining => (
    bg: const Color(0xFFFFEDD5),
    fg: const Color(0xFF9A3412),
    label: 'Cần trả phí còn lại',
  ),
  ClassStatusType.active => (
    bg: const Color(0xFFE0E7DF),
    fg: AppColors.moss,
    label: 'Đang học',
  ),
  ClassStatusType.completed => (
    bg: AppColors.cream2,
    fg: AppColors.ink3,
    label: 'Hoàn thành',
  ),
  ClassStatusType.cancelled => (
    bg: AppColors.cream2,
    fg: AppColors.ink3,
    label: 'Đã hủy',
  ),
  ClassStatusType.expired => (
    bg: AppColors.cream2,
    fg: AppColors.ink3,
    label: 'Hết hạn',
  ),
};

ChipStyle sessionChipStyle(ClassSessionState s) => switch (s) {
  ClassSessionState.reserved => (
    bg: AppColors.cream2,
    fg: AppColors.ink4,
    label: 'Chờ mở khoá',
  ),
  ClassSessionState.scheduled => (
    bg: const Color(0xFFE0E7DF),
    fg: AppColors.moss,
    label: 'Sắp học',
  ),
  ClassSessionState.inProgress => (
    bg: const Color(0xFFE0E7DF),
    fg: AppColors.green,
    label: 'Đang diễn ra',
  ),
  ClassSessionState.pendingConfirmation => (
    bg: const Color(0xFFF0E3CA),
    fg: const Color(0xFF5C3A1A),
    label: 'Chờ xác nhận',
  ),
  ClassSessionState.completed => (
    bg: AppColors.cream2,
    fg: AppColors.ink3,
    label: 'Hoàn thành',
  ),
  ClassSessionState.cancelled => (
    bg: AppColors.cream2,
    fg: AppColors.ink3,
    label: 'Đã hủy',
  ),
  ClassSessionState.disputed => (
    bg: const Color(0xFFF5E9E9),
    fg: AppColors.oxblood,
    label: 'Khiếu nại',
  ),
  ClassSessionState.noShow => (
    bg: const Color(0xFFF5E9E9),
    fg: AppColors.oxblood,
    label: 'Vắng mặt',
  ),
};

/// Icon môn học (CMS cấu hình). Khi thiếu ảnh hoặc tải lỗi thì rơi về chữ cái
/// đầu của tên môn, để card không bao giờ trống một ô.
class SubjectIcon extends StatelessWidget {
  const SubjectIcon({
    required this.iconUrl,
    required this.subjectName,
    super.key,
    this.size = 44,
  });

  final String? iconUrl;
  final String? subjectName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = iconUrl;

    // Icon môn là ảnh PNG nền trong suốt nên vẽ thẳng, không bọc nền/viền.
    return SizedBox(
      width: size,
      height: size,
      child: url == null || url.isEmpty
          ? _fallback()
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => _fallback(),
              placeholder: (_, _) => const SizedBox.shrink(),
            ),
    );
  }

  Widget _fallback() {
    final name = subjectName?.trim() ?? '';
    return Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
          color: AppColors.ink3,
        ),
      ),
    );
  }
}

/// Chip trạng thái nhỏ dùng chung cho card lớp và card buổi.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.style, super.key, this.dense = false});

  final ChipStyle style;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 8,
        vertical: dense ? 2.5 : 3.5,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        style.label,
        style: GoogleFonts.inter(
          fontSize: dense ? 9 : 9.5,
          fontWeight: FontWeight.w700,
          color: style.fg,
          letterSpacing: 0.06,
        ),
      ),
    );
  }
}

/// Vòng tròn tiến độ — dùng ở card lớp học và thẻ stat trang chủ.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.size,
    super.key,
    this.strokeWidth = 5,
    this.color = AppColors.oxblood,
    this.trackColor = AppColors.line,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          color: color,
          trackColor: trackColor,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

/// Thanh tiến độ mảnh dạng "x / y buổi".
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.progress,
    super.key,
    this.height = 6,
    this.color = AppColors.oxblood,
  });

  final double progress;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: AppColors.line,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Card một lớp học ở trang Lịch học: môn + gia sư + tiến độ + buổi kế tiếp.
class ClassCard extends StatelessWidget {
  const ClassCard({required this.klass, required this.onTap, super.key});

  final StudentClassDto klass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = classChipStyle(klass.statusType);
    final next = klass.nextSession;
    final awaiting = klass.awaitingConfirmSession;
    final isClosed = !klass.isOngoing;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isClosed ? 0.8 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressRing(
                    progress: klass.progress,
                    size: 52,
                    color: isClosed ? AppColors.moss : AppColors.oxblood,
                    child: Text(
                      '${klass.progressPercent}%',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          klass.title,
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            height: 1.15,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            UserAvatar(
                              name: klass.tutorName ?? 'GS',
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                klass.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.ink3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(style: chip),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${klass.doneSessions}/${klass.countedSessions} buổi',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (klass.scheduleLabel.isNotEmpty)
                    // Flexible + ellipsis: lịch tuần dài (nhiều thứ) không được
                    // đẩy tràn khỏi card.
                    Flexible(
                      child: Text(
                        klass.scheduleLabel,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.ink3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ProgressBar(
                progress: klass.progress,
                color: isClosed ? AppColors.moss : AppColors.oxblood,
              ),
              if (awaiting != null) ...[
                const SizedBox(height: 12),
                _FooterNote(
                  icon: Icons.pending_actions_rounded,
                  bg: const Color(0xFFF0E3CA),
                  fg: const Color(0xFF5C3A1A),
                  text:
                      'Buổi ${awaiting.dateLabel} chờ bạn xác nhận đã học xong',
                ),
              ] else if (next != null) ...[
                const SizedBox(height: 12),
                _FooterNote(
                  icon: Icons.event_rounded,
                  bg: AppColors.cream2,
                  fg: AppColors.ink2,
                  text:
                      'Buổi tới · ${next.weekdayLabel}, ${next.dateLabel} · ${next.timeRange}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.text,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card một buổi học — dùng trong chi tiết lớp và trong lịch tháng.
class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.session,
    required this.onTap,
    super.key,
    this.subjectName,
    this.tutorName,
    this.showIndex = true,
    this.onReschedule,
    this.onJoin,
  });

  final ClassSessionSlotDto session;
  final VoidCallback onTap;

  /// Hiện tên môn thay cho "Buổi N" — dùng ở lịch tháng (nhiều lớp trộn nhau).
  final String? subjectName;
  final String? tutorName;
  final bool showIndex;

  /// Mở sheet đổi lịch ngay trên card. Nút chỉ hiện khi buổi còn đổi lịch được
  final VoidCallback? onReschedule;

  /// Vào phòng học ngay trên card, khi phòng đã mở.
  final VoidCallback? onJoin;

  /// BE chặn đề xuất đổi lịch khi còn dưới 2 giờ trước giờ học.
  static const _rescheduleCutoff = Duration(hours: 2);

  bool get _canReschedule =>
      onReschedule != null &&
      session.state == ClassSessionState.scheduled &&
      DateTime.now().isBefore(session.startDt.subtract(_rescheduleCutoff));

  bool get _canJoin => onJoin != null && session.canJoinNow;

  /// Buổi phụ dùng rail màu khác hẳn nhóm màu trạng thái: nhìn dọc danh sách
  /// là thấy ngay buổi nào không thuộc lịch gốc.
  Color get _railColor => session.isExtra
      ? AppColors.gold
      : switch (session.state) {
          ClassSessionState.inProgress => AppColors.green,
          ClassSessionState.scheduled => AppColors.moss,
          ClassSessionState.pendingConfirmation => const Color(0xFFD8B46A),
          ClassSessionState.disputed ||
          ClassSessionState.noShow => AppColors.oxblood,
          _ => AppColors.line,
        };

  @override
  Widget build(BuildContext context) {
    final chip = sessionChipStyle(session.state);
    final isPast =
        session.state == ClassSessionState.completed ||
        session.state == ClassSessionState.cancelled;

    // Buổi phụ / học lại KHÔNG có số thứ tự trong gói
    final title = session.isExtra
        ? (subjectName == null ? 'Buổi học phụ' : '$subjectName · Buổi học phụ')
        : subjectName ??
              (showIndex && session.sessionIndex > 0
                  ? 'Buổi ${session.sessionIndex}'
                  : 'Buổi học');

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isPast ? 0.78 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Row(
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
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.dateLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _railColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.ibmPlexSerif(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tutorName ?? session.timeRange,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.ink3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (session.isExtra &&
                            session.originalClassSessionId != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                size: 12,
                                color: AppColors.ink4,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Học bù cho buổi trước',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.ink4,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            StatusPill(style: chip, dense: true),
                            if (session.state == ClassSessionState.scheduled &&
                                session.isWithinJoinWindow) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Tới giờ học',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.ink3,
                  ),
                ],
              ),
              // Hàng hành động nhanh — đổi lịch / vào phòng ngay trên card,
              // không phải mở chi tiết buổi mới thao tác được.
              if (_canReschedule || _canJoin) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_canReschedule)
                      Expanded(
                        child: _CardActionButton(
                          icon: Icons.edit_calendar_outlined,
                          label: 'Đổi lịch',
                          onTap: onReschedule!,
                        ),
                      ),
                    if (_canReschedule && _canJoin) const SizedBox(width: 8),
                    if (_canJoin)
                      Expanded(
                        child: _CardActionButton(
                          icon: Icons.videocam_rounded,
                          label: 'Vào phòng',
                          filled: true,
                          onTap: onJoin!,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút hành động nhỏ trong card buổi học.
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.cream : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.moss : AppColors.cream2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: filled ? AppColors.moss : AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khối trạng thái rỗng dùng chung.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    super.key,
    this.imageAsset = 'assets/images/common/empty_calendar.png',
    this.action,
  });

  final String message;
  final String imageAsset;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imageAsset, width: 180),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.ink3,
                height: 1.5,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Nút chính (nền đậm) dùng lại trong các màn lớp/buổi học.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onTap,
    super.key,
    this.color = AppColors.oxblood,
    this.fg = const Color(0xFFFFF1E6),
    this.enabled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color fg;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút phụ (viền mảnh, nền giấy).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onTap,
    super.key,
    this.icon,
    this.fg = AppColors.ink,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
