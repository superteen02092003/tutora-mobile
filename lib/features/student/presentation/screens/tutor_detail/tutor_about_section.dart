import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

class TutorAboutSection extends StatefulWidget {
  const TutorAboutSection({required this.profile, super.key});
  final TutorFullProfileDto profile;

  @override
  State<TutorAboutSection> createState() => _TutorAboutSectionState();
}

class _TutorAboutSectionState extends State<TutorAboutSection> {
  static const int _collapsedLines = 4;
  bool _expanded = false;

  Map<String, List<SubjectGradePriceDto>> _pricesBySubject(
    List<SubjectGradePriceDto> prices,
  ) {
    final map = <String, List<SubjectGradePriceDto>>{};
    for (final p in prices) {
      final name = p.subjectName.isEmpty ? 'Môn học' : p.subjectName;
      map.putIfAbsent(name, () => []).add(p);
    }
    return map;
  }

  String _priceLabel(double pricePerHour) {
    if (pricePerHour <= 0) return 'Thương lượng';
    if (pricePerHour >= 1000) {
      return '${(pricePerHour / 1000).round()}.000đ/giờ';
    }
    return '${pricePerHour.toStringAsFixed(0)}đ/giờ';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final firstName = profile.displayName.split(' ').last;
    final fullText = [
      if (profile.bio != null) profile.bio!,
      if (profile.experience != null) profile.experience!,
    ].join('\n\n');

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
          if (fullText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              fullText,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.ink2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Thu gọn ▲' : 'Xem thêm ▼',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.ink,
                ),
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
          if (profile.subjectGradePrices != null &&
              profile.subjectGradePrices!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'CẤP LỚP GIẢNG DẠY & HỌC PHÍ',
              style: AppTextStyles.eyebrow(),
            ),
            const SizedBox(height: 10),
            ..._pricesBySubject(profile.subjectGradePrices!).entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...entry.value.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream2,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                p.gradeLevelName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _priceLabel(p.pricePerHour),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
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
