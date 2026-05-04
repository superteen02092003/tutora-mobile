import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/mock/tutor_profile_mock.dart';

class TutorWalletScreen extends StatefulWidget {
  const TutorWalletScreen({super.key});

  @override
  State<TutorWalletScreen> createState() => _TutorWalletScreenState();
}

class _TutorWalletScreenState extends State<TutorWalletScreen> {
  bool _showWithdraw = false;

  @override
  Widget build(BuildContext context) {
    final w = kTutorProfile.wallet;
    final bank = kTutorProfile.bank;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 24),
                children: [
                  _BalanceHero(
                    w: w,
                    showWithdraw: _showWithdraw,
                    onToggleWithdraw: () {
                      setState(() => _showWithdraw = !_showWithdraw);
                    },
                  ),
                  if (_showWithdraw) ...[
                    const SizedBox(height: 12),
                    _WithdrawPanel(w: w, bank: bank),
                  ],
                  const SizedBox(height: 14),
                  _BankCard(bank: bank),
                  const SizedBox(height: 14),
                  _EscrowNote(pending: w.pending),
                  const SizedBox(height: 14),
                  _TransactionList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
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

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.w,
    required this.showWithdraw,
    required this.onToggleWithdraw,
  });
  final TutorWalletMock w;
  final bool showWithdraw;
  final VoidCallback onToggleWithdraw;

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
            '${(w.available / 1000).toStringAsFixed(0)}.000 ₫',
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
              _WalletDetailStat(
                label: 'Chờ giải ngân',
                value: '${(w.pending / 1000).toStringAsFixed(0)}k',
                color: AppColors.gold,
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _WalletDetailStat(
                label: 'Tháng này',
                value: '${(w.thisMonth / 1000).toStringAsFixed(0)}k',
                color: AppColors.cream,
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _WalletDetailStat(
                label: 'Đã rút',
                value: '${(w.withdrawn / 1000).toStringAsFixed(0)}k',
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onToggleWithdraw,
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
        ],
      ),
    );
  }
}

class _WalletDetailStat extends StatelessWidget {
  const _WalletDetailStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value ₫',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 14,
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
    );
  }
}

class _WithdrawPanel extends StatelessWidget {
  const _WithdrawPanel({required this.w, required this.bank});
  final TutorWalletMock w;
  final TutorBankMock bank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÚT VỀ TÀI KHOẢN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: AppColors.ink4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    bank.shortCode,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.bankName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        bank.accountNumber,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
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
          const SizedBox(height: 12),
          Text(
            'SỐ TIỀN RÚT',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: AppColors.ink4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${(w.available / 1000).toStringAsFixed(0)}.000',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '₫',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Xác nhận rút tiền',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.bank});
  final TutorBankMock bank;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              bank.shortCode,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.bankName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bank.accountNumber} · ${bank.holder}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Đổi',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.oxblood,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EscrowNote extends StatelessWidget {
  const _EscrowNote({required this.pending});
  final int pending;

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
                  '${(pending / 1000).toStringAsFixed(0)}k ₫ đang chờ giải ngân',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C3A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tiền sẽ được giải ngân sau khi học sinh xác nhận hoàn thành buổi học.',
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

class _TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final txs = kTutorProfile.transactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
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
                  const Divider(height: 1, color: AppColors.line, indent: 16),
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
  final TutorTransactionMock tx;

  Color get _iconBg => switch (tx.type) {
    TutorTxType.release => const Color(0xFFD5EDD9),
    TutorTxType.withdraw => AppColors.cream2,
    TutorTxType.pending => const Color(0xFFFFF3CD),
  };

  Color get _iconColor => switch (tx.type) {
    TutorTxType.release => const Color(0xFF1D5C2D),
    TutorTxType.withdraw => AppColors.ink,
    TutorTxType.pending => const Color(0xFF7A5900),
  };

  Color get _amountColor => switch (tx.type) {
    TutorTxType.release => const Color(0xFF1D5C2D),
    TutorTxType.withdraw => AppColors.ink,
    TutorTxType.pending => const Color(0xFF7A5900),
  };

  IconData get _icon => switch (tx.type) {
    TutorTxType.release => Icons.north_rounded,
    TutorTxType.withdraw => Icons.south_rounded,
    TutorTxType.pending => Icons.shield_outlined,
  };

  String get _amountText {
    final k = (tx.amount.abs() / 1000).toStringAsFixed(0);
    return switch (tx.type) {
      TutorTxType.release => '+${k}k ₫',
      TutorTxType.withdraw => '-${k}k ₫',
      TutorTxType.pending => '(${k}k ₫)',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 14, color: _iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${tx.date} · ${tx.note}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10.5,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _amountText,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
