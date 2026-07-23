import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/data/datasources/student_wallet_datasource.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');

class ProfileWalletCard extends ConsumerWidget {
  const ProfileWalletCard({required this.onDetailTap, super.key});

  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentWalletProvider);
    return async.when(
      loading: () => const _WalletShell(
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.gold,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (_, _) => _WalletShell(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Không tải được ví.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
      data: (w) => GestureDetector(
        onTap: onDetailTap,
        child: _WalletShell(
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
                '${_vnd.format(w.balance.round())} ₫',
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
              if (w.frozenBalance > 0) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${_vnd.format(w.frozenBalance.round())} ₫',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'đang giữ escrow',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletShell extends StatelessWidget {
  const _WalletShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
