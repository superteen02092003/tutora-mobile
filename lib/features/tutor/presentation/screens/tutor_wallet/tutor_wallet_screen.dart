import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/data/models/transaction_type_labels.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_finance_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_bank_account_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_withdrawals_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/withdraw_sheet.dart';

class TutorWalletScreen extends ConsumerWidget {
  const TutorWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorWalletProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            const _AppBar(),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => _ErrorView(
                  onRetry: () => ref.invalidate(tutorWalletProvider),
                ),
                data: (data) => RefreshIndicator(
                  color: AppColors.oxblood,
                  onRefresh: () async => ref.invalidate(tutorWalletProvider),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 24),
                    children: [
                      _BalanceHero(
                        summary: data.summary,
                        bank: data.bank,
                        onWithdraw: () => _openWithdraw(context, ref, data),
                      ),
                      const SizedBox(height: 14),
                      _BankCard(
                        bank: data.bank,
                        onTap: () => _openBank(context, ref),
                      ),
                      if (data.summary.pendingSettlement > 0) ...[
                        const SizedBox(height: 14),
                        _EscrowNote(pending: data.summary.pendingSettlement),
                      ],
                      const SizedBox(height: 14),
                      _TransactionSection(
                        page: data.transactions,
                        onSeeAll: () => _openWithdrawals(context),
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

  Future<void> _openWithdraw(
    BuildContext context,
    WidgetRef ref,
    TutorWalletData data,
  ) async {
    // Backend chỉ giải ngân về TK đã lưu — chưa có TK thì dẫn sang thêm trước.
    if (!data.bank.isComplete) {
      final added = await _openBank(context, ref);
      if (added != true) return;
    }
    if (!context.mounted) return;
    final done = await showWithdrawSheet(
      context,
      available: data.summary.availableBalance,
    );
    if (done ?? false) ref.invalidate(tutorWalletProvider);
  }

  Future<bool?> _openBank(BuildContext context, WidgetRef ref) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TutorBankAccountScreen()),
    );
    if (changed ?? false) ref.invalidate(tutorWalletProvider);
    return changed;
  }

  void _openWithdrawals(BuildContext context) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const TutorWithdrawalsScreen()),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.ink,
          ),
          Expanded(
            child: Text(
              'Ví gia sư',
              style: AppTextStyles.h3(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không tải được ví.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: TextButton.styleFrom(foregroundColor: AppColors.oxblood),
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.summary,
    required this.bank,
    required this.onWithdraw,
  });
  final TutorFinanceSummary summary;
  final TutorBankInfo bank;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final canWithdraw = summary.availableBalance > 0;
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
            'SỐ DƯ KHẢ DỤNG',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmtMoney(summary.availableBalance),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.cream,
              letterSpacing: -0.02,
              height: 1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(
                label: 'Đang giữ',
                value: fmtMoney(summary.frozenBalance),
                color: AppColors.gold,
              ),
              _divider(),
              _HeroStat(
                label: 'Tổng thu nhập',
                value: fmtMoney(summary.totalEarned),
                color: AppColors.cream,
              ),
              _divider(),
              _HeroStat(
                label: 'Chờ giải ngân',
                value: fmtMoney(summary.pendingSettlement),
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: canWithdraw ? onWithdraw : null,
            child: Opacity(
              opacity: canWithdraw ? 1 : 0.4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.south_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Rút tiền về ngân hàng',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 28,
    color: Colors.white12,
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.bank, required this.onTap});
  final TutorBankInfo bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBank = bank.isComplete;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasBank ? AppColors.ink : AppColors.cream2,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.account_balance_outlined,
                size: 20,
                color: hasBank ? AppColors.cream : AppColors.ink4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasBank
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.bankName ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bank.maskedAccount} · ${bank.accountHolderName}',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: AppColors.ink4,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Thêm tài khoản ngân hàng để rút tiền',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink3,
                      ),
                    ),
            ),
            Text(
              hasBank ? 'Đổi' : 'Thêm',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.oxblood,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.ink4,
            ),
          ],
        ),
      ),
    );
  }
}

class _EscrowNote extends StatelessWidget {
  const _EscrowNote({required this.pending});
  final double pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5D4A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF7A5900)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fmtMoney(pending)} đang chờ giải ngân',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C3A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tiền các buổi đã hoàn tất sẽ vào số dư khả dụng sau khi được giải ngân.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7A5900),
                    height: 1.4,
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

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({required this.page, required this.onSeeAll});
  final TutorTransactionPage page;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final txs = page.transactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                'GIAO DỊCH GẦN ĐÂY',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: AppColors.ink4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Lịch sử rút tiền',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.oxblood,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (txs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              'Chưa có giao dịch nào.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                for (int i = 0; i < txs.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      color: AppColors.line,
                      indent: 16,
                    ),
                  _TxRow(tx: txs[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});
  final TutorTransaction tx;

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final iconBg = credit ? const Color(0xFFD5EDD9) : AppColors.cream2;
    final iconColor = credit ? const Color(0xFF1D5C2D) : AppColors.ink;
    final amountColor = credit ? const Color(0xFF1D5C2D) : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 14,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : tx.typeLabel,
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
                  '${tx.typeLabel} · ${_date(tx.createdAt)}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10.5,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fmtSignedMoney(tx.amount),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: amountColor,
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
