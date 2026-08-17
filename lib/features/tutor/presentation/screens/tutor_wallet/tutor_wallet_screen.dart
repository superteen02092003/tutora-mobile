import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/transaction_type_labels.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_finance_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_bank_account_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_transaction_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_transactions_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/withdraw_sheet.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_transaction_list.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

/// Ví gia sư — rút được bao nhiêu → làm gì với nó → gần đây có gì.
class TutorWalletScreen extends ConsumerWidget {
  const TutorWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorWalletProvider);

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => ListView(
            padding: TutorSurface.screenPadding,
            children: const [
              SizedBox(height: 60),
              TutorSkeleton(height: 190, radius: TutorSurface.radius),
              SizedBox(height: TutorSurface.rowGap),
              TutorSkeleton(height: 76, radius: TutorSurface.radius),
            ],
          ),
          error: (e, _) => _ErrorView(
            onRetry: () => ref.invalidate(tutorWalletProvider),
          ),
          data: (data) => RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () async => ref.invalidate(tutorWalletProvider),
            child: ListView(
              padding: const EdgeInsets.only(
                bottom: kTutorNavTotalHeight + 16,
              ),
              children: [
                const TutorScreenHeader(title: 'Ví của tôi'),
                Padding(
                  padding: TutorSurface.screenPadding,
                  child: _BalanceHero(summary: data.summary),
                ),
                const SizedBox(height: 14),
                _ActionRow(
                  canWithdraw: data.summary.availableBalance > 0,
                  onWithdraw: () => _openWithdraw(context, ref, data),
                  onBank: () => _openBank(context, ref),
                  onHistory: () => _openTransactions(context),
                ),
                const SizedBox(height: TutorSurface.sectionGap),
                Padding(
                  padding: TutorSurface.screenPadding,
                  child: _BankCard(
                    bank: data.bank,
                    onTap: () => _openBank(context, ref),
                  ),
                ),
                const SizedBox(height: TutorSurface.sectionGap),
                _TransactionSection(
                  page: data.transactions,
                  onSeeAll: () => _openTransactions(context),
                  onTransactionTap: (transaction) =>
                      _openTransactionDetail(context, transaction),
                ),
              ],
            ),
          ),
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

  void _openTransactions(BuildContext context) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const TutorTransactionsScreen()),
      ),
    );
  }

  void _openTransactionDetail(
    BuildContext context,
    TutorTransaction transaction,
  ) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TutorTransactionDetailScreen(
            transaction: transaction,
          ),
        ),
      ),
    );
  }
}

// Số dư
/// Thẻ số dư — ô trắng lồng bên trong tách tiền đang giữ khỏi tiền rút được.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary});

  final TutorFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return TutorCard(
      color: TutorColors.heroInk,
      borderColor: TutorColors.heroInk,
      shadow: TutorColors.heroShadow(TutorColors.heroInk),
      backgroundImage: const DecorationImage(
        image: AssetImage('assets/images/common/backgroud_tutor.png'),
        fit: BoxFit.cover,
        alignment: Alignment.topRight,
        opacity: 0.28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Số dư khả dụng',
                  style: TutorType.caption(color: TutorColors.surface),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TutorColors.surface.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 19,
                  color: TutorColors.surface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmtMoney(summary.availableBalance),
            style: TutorType.numeralLarge(color: TutorColors.surface),
          ),
          const SizedBox(height: 16),
          // Ô trắng lồng trong thẻ màu — mẫu ví hiện đại dùng để nhóm chỉ số phụ.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: TutorColors.surface,
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InnerStat(
                    icon: Icons.lock_clock_rounded,
                    tone: TutorColors.warning,
                    label: 'Đang giữ',
                    value: fmtMoney(summary.frozenBalance),
                  ),
                ),
                Container(width: 1, height: 34, color: TutorColors.line),
                Expanded(
                  child: _InnerStat(
                    icon: Icons.trending_up_rounded,
                    tone: TutorColors.success,
                    label: 'Đã nhận',
                    value: fmtMoney(summary.totalEarned),
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

class _InnerStat extends StatelessWidget {
  const _InnerStat({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: tone),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TutorType.caption(color: TutorColors.ink2)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TutorType.rowTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}

// Hàng hành động
/// Ba ô hành động — mẫu ví đặt ngay dưới số dư vì đó là việc kế tiếp.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.canWithdraw,
    required this.onWithdraw,
    required this.onBank,
    required this.onHistory,
  });

  final bool canWithdraw;
  final VoidCallback onWithdraw;
  final VoidCallback onBank;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: TutorSurface.screenPadding,
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.arrow_outward_rounded,
              label: 'Rút tiền',
              // Không đủ số dư thì làm nhạt thay vì ẩn.
              enabled: canWithdraw,
              primary: true,
              onTap: onWithdraw,
            ),
          ),
          const SizedBox(width: TutorSurface.rowGap),
          Expanded(
            child: _ActionTile(
              icon: Icons.account_balance_rounded,
              label: 'Ngân hàng',
              onTap: onBank,
            ),
          ),
          const SizedBox(width: TutorSurface.rowGap),
          Expanded(
            child: _ActionTile(
              icon: Icons.receipt_long_rounded,
              label: 'Lịch sử',
              onTap: onHistory,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = primary && enabled;
    final fg = !enabled
        ? TutorColors.ink4
        : (primary ? TutorColors.surface : TutorColors.ink);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? TutorColors.primary : TutorColors.surface,
          borderRadius: BorderRadius.circular(TutorSurface.radius),
          border: Border.all(
            color: active ? TutorColors.primary : TutorColors.line,
          ),
          boxShadow: TutorColors.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 6),
            Text(label, style: TutorType.caption(color: fg)),
          ],
        ),
      ),
    );
  }
}

// Tài khoản ngân hàng
class _BankCard extends StatelessWidget {
  const _BankCard({required this.bank, required this.onTap});

  final TutorBankInfo bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBank = bank.isComplete;
    final tail = (bank.accountNumber ?? '').length > 4
        ? bank.accountNumber!.substring(bank.accountNumber!.length - 4)
        : (bank.accountNumber ?? '');

    return TutorCard(
      shadow: TutorColors.cardShadow,
      color: hasBank ? null : TutorColors.warningBg,
      borderColor: hasBank ? null : TutorColors.warningBorder,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasBank
                  ? TutorColors.primaryBg
                  : TutorColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
            ),
            child: Icon(
              hasBank ? Icons.account_balance_rounded : Icons.add_rounded,
              size: 20,
              color: hasBank ? TutorColors.primary : TutorColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasBank ? bank.bankName! : 'Chưa có tài khoản nhận tiền',
                  style: TutorType.rowTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasBank
                      ? '•••• $tail · ${bank.accountHolderName}'
                      : 'Thêm để rút tiền về',
                  style: TutorType.caption(color: TutorColors.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            hasBank ? 'Đổi' : 'Thêm',
            style: TutorType.action(color: TutorColors.primary),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: TutorColors.ink4,
          ),
        ],
      ),
    );
  }
}

// Giao dịch
class _TransactionSection extends StatelessWidget {
  const _TransactionSection({
    required this.page,
    required this.onSeeAll,
    required this.onTransactionTap,
  });

  final TutorTransactionPage page;
  final VoidCallback onSeeAll;
  final ValueChanged<TutorTransaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final txs = page.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TutorSectionHeader(
          title: 'Giao dịch gần đây',
          trailingLabel: 'Xem tất cả',
          onTrailingTap: onSeeAll,
        ),
        if (txs.isEmpty)
          Container(
            width: double.infinity,
            color: TutorColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: TutorSurface.gutter,
              vertical: 22,
            ),
            child: Text(
              'Chưa có giao dịch nào.',
              style: TutorType.rowSub(),
            ),
          )
        else
          TutorTransactionList(
            transactions: txs,
            onTap: onTransactionTap,
          ),
      ],
    );
  }
}

// Lỗi
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: TutorSurface.screenPadding,
      children: [
        const SizedBox(height: 60),
        TutorCard(
          color: TutorColors.dangerBg,
          borderColor: TutorColors.dangerBorder,
          onTap: onRetry,
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 17,
                color: TutorColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Không tải được ví. Chạm để thử lại.',
                  style: TutorType.rowSub(color: TutorColors.danger),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
