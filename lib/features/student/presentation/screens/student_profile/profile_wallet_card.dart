import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/presentation/screens/student_profile/profile_primitives.dart';
import 'package:tutora/mock/student_profile_mock.dart';

class ProfileWalletCard extends StatelessWidget {
  const ProfileWalletCard({required this.onDetailTap, super.key});

  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    // api integration later
    final w = kStudentProfile.wallet;
    final totalSessions = kStudentProfile.totalSessions;

    return GestureDetector(
      onTap: onDetailTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  'VÍ HỌC SINH',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                Text(
                  'Chi tiết',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${fmtVnd(w.balance)} ₫',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
                letterSpacing: -0.02,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Số dư khả dụng',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${w.escrow ~/ 1000}k ₫',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đang giữ escrow',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalSessions',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buổi đã học',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _WalletBtn(
                  label: 'Nạp tiền',
                  icon: Icons.add_rounded,
                  gold: true,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _WalletBtn(
                  label: 'Lịch sử',
                  icon: Icons.history_rounded,
                  gold: false,
                  onTap: onDetailTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBtn extends StatelessWidget {
  const _WalletBtn({
    required this.label,
    required this.icon,
    required this.gold,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: gold
                ? AppColors.gold.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: gold ? AppColors.gold : AppColors.cream,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: gold ? AppColors.gold : AppColors.cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
