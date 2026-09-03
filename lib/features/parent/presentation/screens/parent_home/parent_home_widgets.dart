import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/shared/providers/notification_provider.dart';

class ParentHomeGradientPanel extends StatelessWidget {
  const ParentHomeGradientPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: ColoredBox(
        color: AppColors.ink,
        child: child,
      ),
    );
  }
}

class ParentHomeHeader extends StatelessWidget {
  const ParentHomeHeader({required this.onNotif, super.key});

  final VoidCallback onNotif;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          GestureDetector(
            onTap: onNotif,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final count =
                            ref.watch(unreadCountProvider).valueOrNull ?? 0;
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFD166),
                            border: Border.all(
                              color: const Color(0xFF2F5FBF),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParentConfirmBanner extends StatelessWidget {
  const ParentConfirmBanner({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFBE9D8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBC9A8)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.oxblood,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  size: 20,
                  color: Color(0xFFFFF1E6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cần xác nhận $count buổi học',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Xác nhận để gia sư được thanh toán',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.oxblood,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentQuickStats extends StatelessWidget {
  const ParentQuickStats({
    required this.weekCount,
    required this.childrenCount,
    required this.pendingCount,
    super.key,
  });

  final int weekCount;
  final int childrenCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('$weekCount', 'Buổi tuần này'),
      ('$childrenCount', 'Con đang học'),
      ('$pendingCount', 'Chờ xác nhận'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // IntrinsicHeight: 3 thẻ cao bằng nhau để ảnh nền phủ kín, không lệch.
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      children: [
                        // Ảnh tạm: neo đáy vì phần giữa gần trắng, không thấy gì.
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.45,
                            child: Image.asset(
                              'assets/images/common/backgroud_tutor.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                              cacheWidth: 360,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // Lớp trắng phía trên ảnh giữ số/nhãn luôn đọc rõ.
                        Positioned.fill(
                          child: ColoredBox(
                            color: AppColors.paper.withValues(alpha: 0.55),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].$1,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 27,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[i].$2,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  // ink3 thay ink4: nền ảnh làm chữ nhạt bị chìm.
                                  color: AppColors.ink3,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ParentQuickAccessGrid extends StatelessWidget {
  const ParentQuickAccessGrid({
    required this.onCalendar,
    required this.onMessages,
    required this.onBookings,
    required this.onFindTutor,
    super.key,
  });

  final VoidCallback onCalendar;
  final VoidCallback onMessages;
  final VoidCallback onBookings;
  final VoidCallback onFindTutor;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('assets/images/parent/calendar.png', 'Lịch học', onCalendar),
      ('assets/images/parent/chat.png', 'Tin nhắn', onMessages),
      ('assets/images/parent/cash.png', 'Thanh toán', onBookings),
      ('assets/images/parent/search.png', 'Tìm gia sư', onFindTutor),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                onTap: item.$3,
                child: Column(
                  children: [
                    Image.asset(item.$1, width: 28, height: 28),
                    const SizedBox(height: 7),
                    Text(
                      item.$2,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// CTA shown when the selected child has no upcoming lessons.
class ParentNoLessonCta extends StatelessWidget {
  const ParentNoLessonCta({required this.onFindTutor, super.key});

  final VoidCallback onFindTutor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 40, color: AppColors.ink3),
            const SizedBox(height: 12),
            Text(
              'Con chưa có lịch học nào',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bắt đầu hành trình học tập cùng gia sư phù hợp ngay hôm nay.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.ink3,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onFindTutor,
                child: Text(
                  'Tìm gia sư cho con',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
