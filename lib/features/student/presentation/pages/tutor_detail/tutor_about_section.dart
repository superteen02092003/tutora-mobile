import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

class TutorAboutSection extends StatelessWidget {
  const TutorAboutSection({required this.profile, super.key});
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.displayName.split(' ').last;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Về Mentor $firstName',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          if (profile.bio != null) ...[
            const SizedBox(height: 10),
            Text(
              profile.bio!,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.ink2,
                height: 1.6,
              ),
            ),
          ],
          if (profile.experience != null) ...[
            const SizedBox(height: 8),
            Text(
              profile.experience!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.ink3,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (profile.education != null)
                Expanded(
                  child: _CredentialCard(
                    icon: Icons.school_outlined,
                    label: 'Học vấn',
                    value: profile.education!,
                    sub: profile.gpaText.isNotEmpty
                        ? 'GPA ${profile.gpaText}'
                        : '',
                  ),
                ),
              if (profile.education != null && profile.teachingMode != null)
                const SizedBox(width: 8),
              if (profile.teachingMode != null)
                Expanded(
                  child: _CredentialCard(
                    icon: Icons.location_on_outlined,
                    label: 'Khu vực',
                    value: profile.teachingMode!,
                    sub: profile.teachingAreaCity ?? '',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.ink3),
              const SizedBox(width: 5),
              Text(label, style: AppTextStyles.eyebrow()),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink4),
            ),
          ],
        ],
      ),
    );
  }
}
