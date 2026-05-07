import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_filter_options.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';

class TutorHeroSection extends StatelessWidget {
  const TutorHeroSection({required this.profile, super.key});
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          UserAvatar(
            name: profile.displayName,
            size: 88,
            imageUrl: profile.avatarUrl,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.displayName,
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                profile.averageRating.toStringAsFixed(2),
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
              ),
              Text(
                ' · ',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              ),
              Text(
                '${profile.totalFeedbacks} đánh giá',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
              ),
              if (profile.teachingAreaCity != null) ...[
                Text(
                  ' · ',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
                ),
                Text(
                  filterLabel(cityOptions, profile.teachingAreaCity),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
