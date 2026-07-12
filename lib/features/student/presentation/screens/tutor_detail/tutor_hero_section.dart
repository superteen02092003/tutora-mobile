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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          UserAvatar(
            name: profile.displayName,
            size: 76,
            imageUrl: profile.avatarUrl,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.displayName,
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const VerifyPip(),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.averageRating.toStringAsFixed(2),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink2,
                      ),
                    ),
                    Text(
                      '  ·  ${profile.totalFeedbacks} đánh giá',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.ink2,
                      ),
                    ),
                    if (profile.teachingAreaCity != null)
                      Text(
                        '  ·  ${filterLabel(cityOptions, profile.teachingAreaCity)}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.ink2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
