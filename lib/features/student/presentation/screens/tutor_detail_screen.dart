import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/presentation/providers/student_access_provider.dart';
import 'package:tutora/features/student/presentation/widgets/booking_bottom_sheet.dart';
import 'package:tutora/features/student/presentation/widgets/parent_managed_guard.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/features/tutor_search/presentation/controllers/tutor_detail_controller.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:tutora/shared/widgets/skeletons.dart';
import 'package:tutora/shared/widgets/tutor_detail/tutor_about_section.dart';
import 'package:tutora/shared/widgets/tutor_detail/tutor_certificates_section.dart';
import 'package:tutora/shared/widgets/tutor_detail/tutor_hero_section.dart';
import 'package:tutora/shared/widgets/tutor_detail/tutor_reviews_section.dart';
import 'package:tutora/shared/widgets/tutor_detail/tutor_video_section.dart';

class TutorDetailPage extends ConsumerWidget {
  const TutorDetailPage({required this.tutorId, super.key});

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorDetailControllerProvider(tutorId));

    final loaded = state is TutorDetailLoaded ? state.profile : null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: switch (state) {
        TutorDetailLoading() => const TutorDetailSkeleton(),
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
      // Fixed booking button pinned to the bottom.
      bottomNavigationBar: loaded == null
          ? null
          : _BookingBar(tutorId: tutorId, profile: loaded),
    );
  }
}

// Loaded body — layout order:
// top bar (back + share/wishlist) → video → avatar+name → key info
// → about → certificates → reviews → inline booking button at the bottom.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPad + 8),
      children: [
        _TopBar(tutorId: tutorId, profile: profile),
        if (profile.videoIntroUrl != null)
          TutorVideoSection(videoUrl: profile.videoIntroUrl!),
        TutorHeroSection(profile: profile),
        const _Divider(),
        TutorAboutSection(profile: profile),
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

// Top bar: back (left), share + wishlist (right).
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
          _CircleIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          Row(
            children: [
              _CircleIconBtn(
                icon: Icons.ios_share_rounded,
                onTap: () => _onShare(context),
              ),
              const SizedBox(width: 10),
              _CircleIconBtn(
                icon: Icons.favorite_border_rounded,
                onTap: () => _onWishlist(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onShare(BuildContext context) {
    unawaited(
      ParentManagedGuard.copyTutorLink(
        context,
        tutorName: profile.displayName,
        tutorId: tutorId,
      ),
    );
  }

  void _onWishlist(BuildContext context) {
    // Chưa có API wishlis
    AppToast.show(
      context,
      message: 'Tính năng yêu thích đang được phát triển.',
      type: AppToastType.info,
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 15, color: AppColors.ink),
      ),
    );
  }
}

// Booking button pinned to the bottom of the screen (no price — pricing is
// shown per subject/grade in the "cấp lớp giảng dạy" section).
class _BookingBar extends ConsumerWidget {
  const _BookingBar({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final isParentManaged = ref.watch(isParentManagedProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: GestureDetector(
        onTap: () => isParentManaged
            ? ParentManagedGuard.showBookingBlocked(
                context,
                tutorName: profile.fullName ?? 'này',
                tutorId: tutorId,
              )
            : showBookingSheet(context, profile, tutorId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Đặt lịch học ngay',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// Error view
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
