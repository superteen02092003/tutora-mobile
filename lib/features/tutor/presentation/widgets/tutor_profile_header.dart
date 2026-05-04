import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/mock/tutor_profile_mock.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class TutorProfileHeader extends StatelessWidget {
  const TutorProfileHeader({required this.notifOn, super.key});
  final bool notifOn;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.cream,
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tôi', style: AppTextStyles.h2()),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined, size: 20),
                color: AppColors.ink3,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  UserAvatar(name: kTutorProfile.name, size: 62),
                  if (kTutorProfile.verified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cream, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kTutorProfile.name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      kTutorProfile.subjects.join(' · '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < kTutorProfile.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${kTutorProfile.rating}',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· ${kTutorProfile.reviews} đánh giá',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.ink4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                StatCell(
                  label: 'Buổi dạy',
                  value: '${kTutorProfile.totalSessions}',
                  isLast: false,
                ),
                StatCell(
                  label: 'Tổng giờ',
                  value: '${kTutorProfile.totalHours}h',
                  isLast: false,
                ),
                StatCell(
                  label: 'Hoàn thành',
                  value: kTutorProfile.completionRate,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCell extends StatelessWidget {
  const StatCell({
    required this.label,
    required this.value,
    required this.isLast,
    super.key,
  });
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(right: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.ink,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.ink4),
            ),
          ],
        ),
      ),
    );
  }
}
