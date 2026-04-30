import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/shared/widgets/status_chip.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';

// ── Placeholder tutor data (mirrors marketplace list by index) ─────────────
class _TutorInfo {
  const _TutorInfo({
    required this.name,
    required this.subj,
    required this.tier,
    required this.badge,
    required this.rating,
    required this.sessions,
    required this.price,
    required this.city,
    required this.experience,
    required this.quote,
  });
  final String name;
  final String subj;
  final String tier;
  final String badge;
  final String city;
  final String quote;
  final double rating;
  final int sessions;
  final int price;
  final int experience;
}

const _kTutors = [
  _TutorInfo(
    name: 'Cô Mai Anh',
    subj: 'Toán · Lý',
    tier: 'Senior',
    badge: 'Top 1% · Senior',
    rating: 4.96,
    sessions: 482,
    price: 280,
    city: 'Hà Nội',
    experience: 9,
    quote: 'Toán không khó — chỉ cần đúng hướng dẫn.',
  ),
  _TutorInfo(
    name: 'Thầy Đức Huy',
    subj: 'Toán · Hóa',
    tier: 'Verified',
    badge: 'Verified',
    rating: 4.89,
    sessions: 211,
    price: 220,
    city: 'TP.HCM',
    experience: 5,
    quote: 'Hóa học là chìa khóa hiểu thế giới xung quanh.',
  ),
  _TutorInfo(
    name: 'Cô Linh Chi',
    subj: 'Tiếng Anh',
    tier: 'Verified',
    badge: 'IELTS 8.5',
    rating: 4.92,
    sessions: 156,
    price: 250,
    city: 'Đà Nẵng',
    experience: 6,
    quote: 'Tiếng Anh là cánh cửa mở ra thế giới.',
  ),
  _TutorInfo(
    name: 'Thầy Quang',
    subj: 'Vật Lý',
    tier: 'New',
    badge: 'Mới',
    rating: 4.80,
    sessions: 38,
    price: 180,
    city: 'Hà Nội',
    experience: 2,
    quote: 'Vật lý ở khắp nơi — cùng nhau khám phá nhé.',
  ),
];

// ── Page ───────────────────────────────────────────────────────────────────
class TutorDetailPage extends StatelessWidget {
  const TutorDetailPage({required this.tutorId, super.key});

  final String tutorId;

  _TutorInfo get _tutor {
    final idx = int.tryParse(tutorId) ?? 0;
    return _kTutors[idx.clamp(0, _kTutors.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final t = _tutor;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _TopBar(badge: t.badge, tier: t.tier),
          _HeroSection(tutor: t),
          const _StatsGrid(),
          _BookingCard(tutor: t),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.badge, required this.tier});

  final String badge;
  final String tier;

  ChipTone get _chipTone => switch (tier) {
    'Senior' => ChipTone.ox,
    'New' => ChipTone.cream,
    _ => ChipTone.moss,
  };

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
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
          StatusChip(label: badge, tone: _chipTone),
        ],
      ),
    );
  }
}

// ── Hero section ───────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.tutor});

  final _TutorInfo tutor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          UserAvatar(name: tutor.name, size: 88),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tutor.name,
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              const VerifyPip(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '"${tutor.quote}"',
            style: GoogleFonts.ibmPlexSerif(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: AppColors.ink2,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                '${tutor.rating}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
              ),
              Text(
                ' · ',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              ),
              Text(
                '${tutor.sessions} buổi',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
              ),
              Text(
                ' · ',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              ),
              Text(
                '${tutor.experience} năm KN',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Tỷ lệ điểm tăng', value: '+1.8'),
      (label: 'Hoàn tiền', value: '0%'),
      (label: 'Phản hồi', value: '< 1h'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Text(
                      items[i].value,
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      style: AppTextStyles.eyebrow(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Booking card ───────────────────────────────────────────────────────────
class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.tutor});
  final _TutorInfo tutor;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  int _selectedDay = 1;
  int _selectedSlot = 2;

  static const _days = ['T2 22', 'T3 23', 'T4 24', 'T5 25', 'T6 26'];
  static const _slots = ['18:00', '19:00', '19:30', '20:00', '20:30'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐẶT BUỔI HỌC',
            style: AppTextStyles.eyebrow(color: AppColors.gold),
          ),

          // Date row
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: i == _selectedDay
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _days[i],
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: i == _selectedDay
                              ? AppColors.ink
                              : AppColors.cream,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Time slots
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < _slots.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _selectedSlot = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: i == _selectedSlot
                          ? AppColors.cream
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: i == _selectedSlot
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                    ),
                    child: Text(
                      _slots[i],
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        color: i == _selectedSlot
                            ? AppColors.ink
                            : AppColors.cream,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Escrow info line
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
            ),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text:
                        '1 giờ · ${widget.tutor.price}.000đ · Thanh toán giữ tạm qua ',
                  ),
                  TextSpan(
                    text: 'Tutora Escrow',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CTA button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng thanh toán đang phát triển…'),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tiếp tục thanh toán',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
