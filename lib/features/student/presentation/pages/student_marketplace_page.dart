import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/verify_pip.dart';

// ── Placeholder data ───────────────────────────────────────────────────────
class _Tutor {
  const _Tutor({
    required this.name,
    required this.subj,
    required this.tier,
    required this.rating,
    required this.sessions,
    required this.price,
    required this.badge,
    required this.city,
  });
  final String name, subj, tier, badge, city;
  final double rating;
  final int sessions, price;
}

const _kTutors = [
  _Tutor(name: 'Cô Mai Anh',   subj: 'Toán · Lý',      tier: 'Senior',   rating: 4.96, sessions: 482, price: 280, badge: 'Top 1%',    city: 'Hà Nội'),
  _Tutor(name: 'Thầy Đức Huy', subj: 'Toán · Hóa',     tier: 'Verified', rating: 4.89, sessions: 211, price: 220, badge: 'Verified',   city: 'TP.HCM'),
  _Tutor(name: 'Cô Linh Chi',  subj: 'Tiếng Anh',       tier: 'Verified', rating: 4.92, sessions: 156, price: 250, badge: 'IELTS 8.5', city: 'Đà Nẵng'),
  _Tutor(name: 'Thầy Quang',   subj: 'Vật Lý',          tier: 'New',      rating: 4.80, sessions: 38,  price: 180, badge: 'Mới',       city: 'Hà Nội'),
];

const _kChips = ['Toán 10', 'Cánh Diều', '≤300k/giờ', 'Senior', 'Online', 'Hà Nội'];

// ── Page ───────────────────────────────────────────────────────────────────
class StudentMarketplacePage extends StatelessWidget {
  const StudentMarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            _TopBar(),
            _Header(),
            _SearchRow(),
            _FilterChips(),
            _AiCallout(),
            _TutorList(),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRoutes.studentHome),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.ink),
            ),
          ),
          const Spacer(),
          const AppLogo(size: 13),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHỢ GIA SƯ · TUTORA MARKETPLACE',
              style: AppTextStyles.eyebrow(color: AppColors.oxblood)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Tìm người đồng hành ',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1.05,
                    letterSpacing: -0.56,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: 'đúng phong cách.',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontSize: 26,
                    color: AppColors.ink,
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

// ── Search row ─────────────────────────────────────────────────────────────
class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 16, color: AppColors.ink3),
                  const SizedBox(width: 8),
                  Text('Toán · Hệ thức Vi-ét…',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.cream),
          ),
        ],
      ),
    );
  }
}

// ── Filter chips ───────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (int i = 0; i < _kChips.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            StatusChip(
              label: _kChips[i],
              tone: i == 0 ? ChipTone.ink : ChipTone.line,
            ),
          ],
        ],
      ),
    );
  }
}

// ── AI match callout ────────────────────────────────────────────────────────
class _AiCallout extends StatelessWidget {
  const _AiCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E3CA),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFE0D2A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.oxblood),
              const SizedBox(width: 8),
              Text('GỢI Ý TỪ TUTORA AI',
                  style: AppTextStyles.eyebrow(color: AppColors.oxblood)),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Dựa trên bài ',
                  style: GoogleFonts.ibmPlexSerif(fontSize: 14, height: 1.4, color: AppColors.ink),
                ),
                TextSpan(
                  text: 'Hệ thức Vi-ét',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: ' bạn vừa quét — 4 gia sư phù hợp.',
                  style: GoogleFonts.ibmPlexSerif(fontSize: 14, height: 1.4, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tutor list ─────────────────────────────────────────────────────────────
class _TutorList extends StatelessWidget {
  const _TutorList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          for (int i = 0; i < _kTutors.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < _kTutors.length - 1 ? 10 : 0),
              child: _TutorCard(tutor: _kTutors[i], index: i),
            ),
        ],
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.tutor, required this.index});

  final _Tutor tutor;
  final int index;

  ChipTone get _badgeTone => switch (tutor.tier) {
        'Senior' => ChipTone.ox,
        'New'    => ChipTone.cream,
        _        => ChipTone.moss,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/student/search/tutor/$index'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(name: tutor.name, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tutor.name,
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const VerifyPip(small: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tutor.subj} · ${tutor.city}',
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.ink3),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      const Icon(Icons.star_rounded, size: 10, color: AppColors.gold),
                      Text(
                        '${tutor.rating}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '· ${tutor.sessions} buổi',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3),
                      ),
                      StatusChip(label: tutor.badge, tone: _badgeTone),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tutor.price}k',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                Text('/ giờ', style: GoogleFonts.inter(fontSize: 10, color: AppColors.ink3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
