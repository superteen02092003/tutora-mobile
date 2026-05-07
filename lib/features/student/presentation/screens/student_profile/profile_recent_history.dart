import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/presentation/screens/student_profile/profile_primitives.dart';
import 'package:tutora/mock/student_profile_mock.dart';

class ProfileRecentHistory extends StatelessWidget {
  const ProfileRecentHistory({required this.onViewAll, super.key});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    // api integration later
    final items = kStudentProfile.history.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          ...items.asMap().entries.map((e) {
            final h = e.value;
            return Column(
              children: [
                if (e.key > 0)
                  const Divider(height: 1, indent: 46, color: AppColors.line),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(name: h.tutorName, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.subject,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${h.tutorName} · ${h.date} · ${h.hours}h',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.ink4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        h.refunded ? 'Hoàn tiền' : '${h.amount ~/ 1000}k ₫',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: h.refunded ? AppColors.oxblood : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.cream2,
                border: Border(top: BorderSide(color: AppColors.line)),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Xem tất cả',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: AppColors.ink4,
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
