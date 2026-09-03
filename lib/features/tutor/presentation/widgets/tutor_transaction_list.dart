import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/transaction_type_labels.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';

class TutorTransactionList extends StatelessWidget {
  const TutorTransactionList({
    required this.transactions,
    required this.onTap,
    this.horizontalPadding = TutorSurface.gutter,
    super.key,
  });

  final List<TutorTransaction> transactions;
  final ValueChanged<TutorTransaction> onTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TutorColors.surface,
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            TutorTransactionRow(
              transaction: transactions[i],
              onTap: () => onTap(transactions[i]),
              horizontalPadding: horizontalPadding,
            ),
            if (i < transactions.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: horizontalPadding + 48,
                endIndent: horizontalPadding,
                color: TutorColors.line,
              ),
          ],
        ],
      ),
    );
  }
}

class TutorTransactionRow extends StatelessWidget {
  const TutorTransactionRow({
    required this.transaction,
    required this.onTap,
    this.horizontalPadding = TutorSurface.gutter,
    super.key,
  });

  final TutorTransaction transaction;
  final VoidCallback onTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    final tone = credit ? TutorColors.success : TutorColors.primary;

    return Material(
      color: TutorColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                child: Icon(
                  credit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.typeLabel,
                      style: TutorType.rowTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tutorTransactionTimeLabel(transaction.createdAt),
                      style: TutorType.caption(color: TutorColors.ink3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                fmtSignedMoney(transaction.amount),
                style: TutorType.rowTitle(color: tone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String tutorTransactionTimeLabel(DateTime? value) {
  if (value == null) return 'Không rõ thời gian';
  final date = value.toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  // Ngày trước, giờ sau
  return '${date.day}/${date.month}/${date.year} · $hour:$minute';
}
