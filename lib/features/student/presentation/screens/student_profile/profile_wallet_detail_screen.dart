import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/presentation/screens/student_profile/profile_primitives.dart';
import 'package:tutora/mock/student_profile_mock.dart';

class ProfileWalletDetailScreen extends StatelessWidget {
  const ProfileWalletDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // api integration later
    final w = kStudentProfile.wallet;
    final transactions = kStudentProfile.transactions;

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
              child: ListView(
                padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 40),
                children: [
                  // Balance hero
                  Container(
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              fmtVnd(w.balance),
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cream,
                                letterSpacing: -0.02,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₫',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _WalletStat(
                                value: '${w.escrow ~/ 1000}k ₫',
                                label: 'Đang giữ escrow',
                                gold: true,
                              ),
                              Container(
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.1),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              _WalletStat(
                                value: '${(w.balance + w.escrow) ~/ 1000}k ₫',
                                label: 'Tổng đã nạp',
                                gold: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 15,
                                  color: AppColors.ink,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nạp tiền vào ví',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
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
                  const SizedBox(height: 14),

                  // Escrow explanation
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: AppColors.ink,
                        ),
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
                              ...[
                                'Bạn đặt lịch → tiền giữ escrow trong ví',
                                'Buổi học hoàn thành → bạn xác nhận',
                                'Tutora giải ngân cho gia sư',
                                'Huỷ lịch → hoàn tiền tự động',
                              ].asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '0${e.key + 1}',
                                        style: GoogleFonts.ibmPlexMono(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          e.value,
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Transaction list
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
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: transactions.asMap().entries.map((e) {
                        return Column(
                          children: [
                            if (e.key > 0)
                              const Divider(
                                height: 1,
                                indent: 60,
                                color: AppColors.line,
                              ),
                            _TxRow(tx: e.value),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletStat extends StatelessWidget {
  const _WalletStat({
    required this.value,
    required this.label,
    required this.gold,
  });

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
            fontSize: 16,
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

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});

  final StudentTxMock tx;

  (Color, IconData) get _iconStyle => switch (tx.type) {
    StudentTxType.topup => (
      const Color(0xFFD5EDD9),
      Icons.arrow_upward_rounded,
    ),
    StudentTxType.escrow => (
      const Color(0xFFFFF3CD),
      Icons.shield_outlined,
    ),
    StudentTxType.refund => (
      const Color(0xFFD5E8F5),
      Icons.arrow_downward_rounded,
    ),
  };

  Color get _iconFg => switch (tx.type) {
    StudentTxType.topup => const Color(0xFF1D5C2D),
    StudentTxType.escrow => const Color(0xFF7A5900),
    StudentTxType.refund => const Color(0xFF0D3F6B),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, icon) = _iconStyle;
    final isPos = tx.amount > 0;
    final amountK = tx.amount.abs() ~/ 1000;

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
            child: Icon(icon, size: 14, color: _iconFg),
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
                  '${tx.date} · ${tx.method}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPos ? '+' : ''}${isPos ? amountK : '-$amountK'}k ₫',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isPos ? const Color(0xFF1D5C2D) : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
