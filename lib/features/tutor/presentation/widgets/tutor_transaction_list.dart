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
                indent: horizontalPadding + 52,
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
    final tone = credit ? TutorColors.success : TutorColors.danger;

    return Material(
      color: TutorColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  credit
                      ? Icons.south_west_rounded
                      : Icons.arrow_outward_rounded,
                  size: 18,
                  color: tone,
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
                    if (transaction.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        transaction.description,
                        style: TutorType.caption(color: TutorColors.ink3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmtSignedMoney(transaction.amount),
                    style: TutorType.rowTitle(color: tone),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tutorTransactionDateLabel(transaction.createdAt),
                    style: TutorType.caption(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String tutorTransactionDateLabel(DateTime? value) {
  if (value == null) return 'Không rõ ngày';
  final date = value.toLocal();
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days == 0) return 'Hôm nay';
  if (days == 1) return 'Hôm qua';
  return '${date.day}/${date.month}/${date.year}';
}

String tutorTransactionTimeLabel(DateTime? value) {
  if (value == null) return 'Không rõ thời gian';
  final date = value.toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute · ${date.day}/${date.month}/${date.year}';
}
