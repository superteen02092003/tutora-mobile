import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/jwt_utils.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/user_avatar.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(secureStorageProvider).getAccessToken(),
      builder: (context, snap) {
        final claims = snap.hasData ? parseJwt(snap.data!) : null;
        final firstName = _firstName(claims?.name ?? '');
        return _HomeContent(firstName: firstName);
      },
    );
  }

  String _firstName(String fullName) {
    if (fullName.isEmpty) return 'bạn';
    final parts = fullName.trim().split(' ');
    return parts.last;
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.firstName});

  final String firstName;

  // Placeholder recent AI solutions
  static const _recents = [
    (sub: 'Toán 10', topic: 'Hệ thức Vi-ét', book: 'Cánh Diều · §3.4', time: '5p trước'),
    (sub: 'Vật Lý 10', topic: 'Định luật II Newton', book: 'Chân trời · §9.2', time: 'Hôm qua'),
    (sub: 'Hóa 10', topic: 'Cấu hình electron', book: 'Kết nối · §4.1', time: '2 ngày'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _TopBar(name: firstName),
            _Greeting(firstName: firstName),
            const SizedBox(height: AppSpacing.sm),
            const _HeroCapture(),
            const SizedBox(height: AppSpacing.xs),
            _ShortcutGrid(
              onFindTutor: () => context.go(AppRoutes.studentSearch),
            ),
            _SectionHeader(
              title: 'Gần đây',
              onSeeAll: () {},
            ),
            ..._recents.map((r) => _RecentItem(
                  subject: r.sub,
                  topic: r.topic,
                  book: r.book,
                  time: r.time,
                  onTap: () {},
                )),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const AppLogo(size: 15),
          const Spacer(),
          // Bell icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_outlined, size: 18, color: AppColors.ink),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.oxblood,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          UserAvatar(name: name, size: 36),
        ],
      ),
    );
  }
}

// ── Greeting ───────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HỌC SINH',
            style: AppTextStyles.eyebrow(color: AppColors.oxblood),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Chào, $firstName.\n',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    letterSpacing: -0.02 * 30,
                    height: 1.05,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: 'Hôm nay học gì?',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontSize: 28,
                    color: AppColors.ink2,
                    height: 1.1,
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

// ── Hero AI capture card ────────────────────────────────────────────────

class _HeroCapture extends StatelessWidget {
  const _HeroCapture();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            // Radial gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const RadialGradient(
                    center: Alignment(0.9, -1.0),
                    radius: 1.2,
                    colors: [Color(0x2ED4B483), Colors.transparent],
                    stops: [0.0, 0.55],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI HỖ TRỢ',
                  style: AppTextStyles.eyebrow(color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chụp một bài toán.\n',
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.1,
                          color: AppColors.cream,
                        ),
                      ),
                      TextSpan(
                        text: 'Hiểu trong 8 giây.',
                        style: GoogleFonts.ibmPlexSerif(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          fontSize: 21,
                          color: AppColors.gold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đọc bài toán → phân loại → gợi ý theo SGK Việt Nam.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                _CameraButton(
                  onTap: () => context.go(AppRoutes.studentCapture),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(
              'Mở camera quét',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shortcut grid ───────────────────────────────────────────────────────

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.onFindTutor});

  final VoidCallback onFindTutor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _ShortcutCard(
              title: 'Lịch sử AI',
              subtitle: '12 bài tuần này',
              isGold: false,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ShortcutCard(
              title: 'Tìm gia sư',
              subtitle: '4 phù hợp mới',
              isGold: true,
              onTap: onFindTutor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.isGold,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isGold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isGold ? const Color(0xFFF0E3CA) : AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.bodySmall()),
          ],
        ),
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppTextStyles.eyebrow()),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Xem tất cả',
              style: GoogleFonts.ibmPlexSerif(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: AppColors.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent item ─────────────────────────────────────────────────────────

class _RecentItem extends StatelessWidget {
  const _RecentItem({
    required this.subject,
    required this.topic,
    required this.book,
    required this.time,
    required this.onTap,
  });

  final String subject;
  final String topic;
  final String book;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              // Subject thumbnail placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFE9DA), Color(0xFFE5DDC9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  subject.substring(0, 1),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: AppColors.ink2.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$book · $time',
                      style: AppTextStyles.bodySmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
