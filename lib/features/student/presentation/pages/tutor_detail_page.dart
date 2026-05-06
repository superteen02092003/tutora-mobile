import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/presentation/pages/tutor_detail/tutor_about_section.dart';
import 'package:tutora/features/student/presentation/pages/tutor_detail/tutor_certificates_section.dart';
import 'package:tutora/features/student/presentation/pages/tutor_detail/tutor_hero_section.dart';
import 'package:tutora/features/student/presentation/pages/tutor_detail/tutor_reviews_section.dart';
import 'package:tutora/features/student/presentation/widgets/booking_bottom_sheet.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/features/tutor_search/presentation/controllers/tutor_detail_controller.dart';
import 'package:tutora/shared/widgets/status_chip.dart';

class TutorDetailPage extends ConsumerWidget {
  const TutorDetailPage({required this.tutorId, super.key});

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorDetailControllerProvider(tutorId));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: switch (state) {
        TutorDetailLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        TutorDetailError(:final message) => _ErrorView(
          message: message,
          onRetry: () =>
              ref.read(tutorDetailControllerProvider(tutorId).notifier).retry(),
        ),
        TutorDetailLoaded(:final profile) => _DetailBody(
          tutorId: tutorId,
          profile: profile,
        ),
      },
    );
  }
}

// ── Loaded body ────────────────────────────────────────────────────────────
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _TopBar(tutorId: tutorId, profile: profile),
        TutorHeroSection(profile: profile),
        const _Divider(),
        const _StatsGrid(),
        const _Divider(),
        TutorAboutSection(profile: profile),
        if (profile.videoIntroUrl != null) ...[
          const _Divider(),
          _VideoSection(videoUrl: profile.videoIntroUrl!),
        ],
        if (profile.certificates != null &&
            profile.certificates!.isNotEmpty) ...[
          const _Divider(),
          TutorCertificatesSection(certificates: profile.certificates!),
        ],
        const _Divider(),
        TutorReviewsSection(
          feedbacks: profile.feedbacks ?? [],
          averageRating: profile.averageRating,
          totalFeedbacks: profile.totalFeedbacks,
        ),
        const _Divider(),
        _BookingCard(tutorId: tutorId, profile: profile),
        SizedBox(height: AppSpacing.xxl + bottomPad + 40),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    color: AppColors.line,
    indent: 16,
    endIndent: 16,
  );
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

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
          if (profile.teachingMode != null)
            StatusChip(label: profile.teachingMode!, tone: ChipTone.moss),
        ],
      ),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  static const List<({String label, String value})> _items = [
    (label: 'Tỷ lệ điểm tăng', value: '+1.8'),
    (label: 'Hoàn tiền', value: '0%'),
    (label: 'Phản hồi', value: '< 1h'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          for (int i = 0; i < _items.length; i++) ...[
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
                      _items[i].value,
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _items[i].label,
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

// ── Video section ──────────────────────────────────────────────────────────
class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.videoUrl});
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Video giới thiệu',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.oxblood.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'TUTORA Original',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oxblood,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng xem video đang phát triển…'),
              ),
            ),
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.55,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Text(
                      'Click để xem phỏng vấn học thuật',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

// ── Booking card ───────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  String get _priceText {
    final rate = profile.hourlyRate;
    if (rate == null || rate == 0) return 'Thương lượng';
    if (rate >= 1000) {
      final k = (rate / 1000).round();
      return '$k.000đ / giờ';
    }
    return '${rate.toStringAsFixed(0)}đ / giờ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _priceText,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thanh toán qua Tutora Escrow',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile.teachingMode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      profile.teachingMode!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => showBookingSheet(context, profile, tutorId),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Đặt lịch học ngay',
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

// ── Error view ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Thử lại',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
