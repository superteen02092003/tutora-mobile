import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/mock/tutor_home_mock.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class TutorHomeScreen extends StatelessWidget {
  const TutorHomeScreen({super.key});

  static String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _TopBar(name: kMockTutorName),
            _Greeting(firstName: _firstName(kMockTutorName)),
            const SizedBox(height: AppSpacing.sm),
            const _StatGrid(),
            _SectionHeader(
              title: 'Hôm nay · ${kMockTutorSessions.length} buổi',
              action: 'Xem cả tuần',
              onAction: () {},
            ),
            ...kMockTutorSessions.map((s) => _SessionCard(session: s)),
            const SizedBox(height: AppSpacing.sm),
            _CopilotCard(
              onContribute: () => context.go(AppRoutes.tutorContribute),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuestionBankStrip(
              onContribute: () => context.go(AppRoutes.tutorContribute),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          // Bell with notification dot
          Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
              Positioned(
                top: 7,
                right: 7,
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
          const SizedBox(width: 10),
          UserAvatar(name: name),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BẢNG ĐIỀU KHIỂN GIA SƯ',
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
                    letterSpacing: -0.6,
                    height: 1.05,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: '3 buổi học hôm nay.',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontSize: 26,
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

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: kMockTutorStats
            .map(
              (s) => _StatCard(
                label: s.label,
                value: s.value,
                sub: s.sub,
                tone: s.tone,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.tone,
  });

  final String label;
  final String value;
  final String sub;
  final String tone; // 'ink' | 'gold' | 'cream'

  bool get _isDark => tone == 'ink';
  bool get _isGold => tone == 'gold';

  Color get _bg => _isDark
      ? AppColors.ink
      : _isGold
      ? const Color(0xFFF0E3CA)
      : AppColors.paper;

  Color get _border => _isDark
      ? Colors.transparent
      : _isGold
      ? const Color(0xFFE0D2A8)
      : AppColors.line;

  Color get _labelColor => _isDark ? AppColors.gold : AppColors.ink3;
  Color get _valueColor => _isDark ? AppColors.cream : AppColors.ink;
  Color get _subColor =>
      _isDark ? AppColors.cream.withValues(alpha: 0.55) : AppColors.ink3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.eyebrow(color: _labelColor)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: _valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: _subColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppTextStyles.eyebrow()),
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
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

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final MockTutorSession session;

  @override
  Widget build(BuildContext context) {
    final isNext = session.isNext;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: const BorderSide(color: AppColors.line),
            right: const BorderSide(color: AppColors.line),
            bottom: const BorderSide(color: AppColors.line),
            left: BorderSide(
              color: isNext ? AppColors.oxblood : AppColors.line,
              width: isNext ? 3 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Time block
            SizedBox(
              width: 50,
              child: Text(
                session.time,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.studentName,
                    style: GoogleFonts.ibmPlexSerif(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.subject,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.ink3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // CTA button
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isNext ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: isNext ? null : Border.all(color: AppColors.line),
                ),
                child: Text(
                  session.ctaLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isNext ? AppColors.cream : AppColors.ink,
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

class _CopilotCard extends StatelessWidget {
  const _CopilotCard({required this.onContribute});

  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const RadialGradient(
                    center: Alignment(1.1, -1),
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
                  'CO-PILOT · TRƯỚC BUỔI HỌC',
                  style: AppTextStyles.eyebrow(color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Linh đã quét 3 bài về Vi-ét\n',
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 1.15,
                          color: AppColors.cream,
                        ),
                      ),
                      TextSpan(
                        text: '— sai cùng một bước.',
                        style: GoogleFonts.ibmPlexSerif(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          fontSize: 17,
                          color: AppColors.gold,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'Đề xuất: bắt đầu bằng việc ôn dấu của b trong công thức Vi-ét trước khi vào bài mới.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.cream.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onContribute,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'Đóng góp lời giải · +50k',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBankStrip extends StatelessWidget {
  const _QuestionBankStrip({required this.onContribute});

  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NGÂN HÀNG CÂU HỎI', style: AppTextStyles.eyebrow()),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onContribute,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E3CA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: AppColors.oxblood,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đóng góp bài tập có lời giải',
                          style: GoogleFonts.ibmPlexSerif(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '3 bài đang chờ duyệt · 142 bài đã đăng',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.ink3,
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
