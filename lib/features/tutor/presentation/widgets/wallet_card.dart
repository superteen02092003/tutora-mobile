import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/mock/tutor_profile_mock.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = kTutorProfile.wallet;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 15,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VÍ GIA SƯ',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Chi tiết',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${(w.available / 1000).toStringAsFixed(0)}.000 ₫',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.cream,
                letterSpacing: -0.02,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Số dư có thể rút',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                WalletStat(
                  label: 'Chờ giải ngân',
                  value: '${(w.pending / 1000).toStringAsFixed(0)}k ₫',
                  valueColor: AppColors.gold,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white12,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                WalletStat(
                  label: 'Tháng này',
                  value: '${(w.thisMonth / 1000).toStringAsFixed(0)}k ₫',
                  valueColor: AppColors.cream,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: WalletBtn(
                    label: 'Rút tiền',
                    icon: Icons.south_rounded,
                    gold: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: WalletBtn(
                    label: 'Lịch sử',
                    icon: Icons.north_rounded,
                    gold: false,
                    onTap: onTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WalletStat extends StatelessWidget {
  const WalletStat({
    required this.label,
    required this.value,
    required this.valueColor,
    super.key,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white38),
        ),
      ],
    );
  }
}

class WalletBtn extends StatelessWidget {
  const WalletBtn({
    required this.label,
    required this.icon,
    required this.gold,
    required this.onTap,
    super.key,
  });
  final String label;
  final IconData icon;
  final bool gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: gold ? AppColors.gold.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: gold ? AppColors.gold : AppColors.cream,
            ),
            const SizedBox(width: 5),
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
    );
  }
}
