import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/data/datasources/student_wallet_datasource.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');
String _money(double v) => '${_vnd.format(v.round())} ₫';

class ProfileWalletDetailScreen extends ConsumerWidget {
  const ProfileWalletDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final async = ref.watch(studentWalletProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Text(
                      'Ví của tôi',
                      style: AppTextStyles.h3(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Không tải được ví.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
                data: (w) => RefreshIndicator(
                  color: AppColors.oxblood,
                  onRefresh: () async => ref.invalidate(studentWalletProvider),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 40),
                    children: [
                      _BalanceHero(
                        balance: w.balance,
                        frozen: w.frozenBalance,
                        total: w.totalBalance,
                      ),
                      const SizedBox(height: 14),
                      const _EscrowExplainer(),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 6),
                        child: Text(
                          'LỊCH SỬ GIAO DỊCH',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.12,
                            color: AppColors.ink4,
                          ),
                        ),
                      ),
                      if (w.transactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            'Chưa có giao dịch nào.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink3,
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.line),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              for (
                                int i = 0;
                                i < w.transactions.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 60,
                                    color: AppColors.line,
                                  ),
                                _TxRow(tx: w.transactions[i]),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.balance,
    required this.frozen,
    required this.total,
  });
  final double balance;
  final double frozen;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SỐ DƯ VÍ',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _money(balance),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.cream,
              letterSpacing: -0.02,
              height: 1,
            ),
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              children: [
                _Stat(
                  value: _money(frozen),
                  label: 'Đang giữ escrow',
                  gold: true,
                ),
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _Stat(value: _money(total), label: 'Tổng số dư', gold: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.gold});
  final String value;
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: gold ? AppColors.gold : AppColors.cream,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _EscrowExplainer extends StatelessWidget {
  const _EscrowExplainer();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Bạn đặt lịch → tiền giữ escrow trong ví',
      'Buổi học hoàn thành → bạn xác nhận',
      'Tutora giải ngân cho gia sư',
      'Huỷ lịch → hoàn tiền tự động',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escrow hoạt động thế nào?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                for (int i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '0${i + 1}',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.ink3,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});
  final StudentWalletTx tx;

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final bg = credit ? const Color(0xFFD5EDD9) : AppColors.cream2;
    final fg = credit ? const Color(0xFF1D5C2D) : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 14,
              color: fg,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : 'Giao dịch',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _date(tx.createdAt),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${credit ? '+' : '-'}${_money(tx.amount.abs())}',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: credit ? const Color(0xFF1D5C2D) : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
