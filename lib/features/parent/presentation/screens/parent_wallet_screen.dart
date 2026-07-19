import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/data/datasources/wallet_datasource.dart';
import 'package:tutora/features/parent/data/models/wallet_models.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');
String formatVnd(double v) => '${_vnd.format(v.round())}đ';

class ParentWalletScreen extends ConsumerWidget {
  const ParentWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentWalletProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _NavBar(title: 'Ví của tôi'),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Không tải được ví.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
                data: (summary) => ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 24),
                  children: [
                    _BalanceCard(balance: summary.balance),
                    const SizedBox(height: 20),
                    const _SectionLabel('Lịch sử giao dịch'),
                    const SizedBox(height: 8),
                    if (summary.transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Chưa có giao dịch nào.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink3,
                            ),
                          ),
                        ),
                      )
                    else
                      ...summary.transactions.map(
                        (t) => _TransactionRow(tx: t),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSerif(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// Balance hero card: spendable balance big, frozen + total below.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final WalletBalance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SỐ DƯ KHẢ DỤNG',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatVnd(balance.availableBalance),
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Đang giữ (escrow)',
                  value: formatVnd(balance.frozenBalance),
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _MiniStat(
                    label: 'Tổng cộng',
                    value: formatVnd(balance.totalBalance),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nạp tiền — sắp ra mắt')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Nạp tiền vào ví',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.cream,
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});
  final WalletTransaction tx;

  static const _labels = <String, String>{
    'Deposit': 'Nạp tiền',
    'Payment': 'Thanh toán',
    'EscrowCredit': 'Giữ tiền',
    'EscrowRelease': 'Giải ngân',
    'Withdrawal': 'Rút tiền',
    'Refund': 'Hoàn tiền',
    'DepositPayment': 'Thanh toán buổi đầu',
    'RemainingPayment': 'Thanh toán còn lại',
    'BankVerification': 'Xác minh ngân hàng',
  };

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final icon = credit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final amountColor = credit ? AppColors.green : AppColors.oxblood;
    final sign = credit ? '+' : '−';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: amountColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 18, color: amountColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labels[tx.transactionType] ?? tx.transactionType,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.ink3,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(tx.createdAtDt),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${formatVnd(tx.amount.abs())}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.eyebrow());
  }
}
