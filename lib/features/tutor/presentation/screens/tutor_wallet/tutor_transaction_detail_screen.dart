import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_finance_datasource.dart';
import 'package:tutora/features/tutor/data/models/transaction_type_labels.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_transaction_list.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/providers/auth_headers_provider.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

class TutorTransactionDetailScreen extends ConsumerWidget {
  const TutorTransactionDetailScreen({required this.transaction, super.key});

  final TutorTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authHeaders =
        ref.watch(authImageHeadersProvider).valueOrNull ??
        const <String, String>{};

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TutorChildHeader(title: 'Chi tiết giao dịch'),
            Expanded(
              child: FutureBuilder<TutorTransaction>(
                future: ref
                    .read(tutorFinanceDatasourceProvider)
                    .getTransactionDetail(transaction.transactionId),
                builder: (context, snapshot) {
                  final detail = snapshot.data ?? transaction;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      12,
                      TutorSurface.gutter,
                      kTutorNavTotalHeight + 32,
                    ),
                    children: [
                      _TransactionHero(transaction: detail),
                      const SizedBox(height: TutorSurface.sectionGap),
                      Text(
                        'Thông tin giao dịch',
                        style: TutorType.sectionTitle(),
                      ),
                      const SizedBox(height: 10),
                      _DetailSurface(transaction: detail),
                      if (detail.proofImageUrl?.isNotEmpty ?? false) ...[
                        const SizedBox(height: TutorSurface.sectionGap),
                        Text(
                          'Chứng từ chi trả',
                          style: TutorType.sectionTitle(),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            TutorSurface.radius,
                          ),
                          // Ảnh private cần JWT — xem authImageHeadersProvider.
                          child: Image.network(
                            detail.proofImageUrl!,
                            headers: authHeaders,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 120,
                              color: TutorColors.surfaceSunken,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: TutorColors.ink4,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (snapshot.hasError) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Chưa tải được thông tin đối soát. Dữ liệu cơ bản vẫn được hiển thị.',
                          style: TutorType.caption(color: TutorColors.danger),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionHero extends StatelessWidget {
  const _TransactionHero({required this.transaction});

  final TutorTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final tone = transaction.isCredit
        ? TutorColors.success
        : TutorColors.danger;

    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction.isCredit
                ? Icons.south_west_rounded
                : Icons.arrow_outward_rounded,
            color: tone,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          fmtSignedMoney(transaction.amount),
          style: TutorType.numeralLarge(color: tone),
        ),
        const SizedBox(height: 6),
        Text(transaction.typeLabel, style: TutorType.rowTitle()),
        const SizedBox(height: 4),
        Text(
          tutorTransactionTimeLabel(transaction.createdAt),
          style: TutorType.caption(color: TutorColors.ink3),
        ),
      ],
    );
  }
}

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.transaction});

  final TutorTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Mã giao dịch', '#${transaction.transactionId}'),
      ('Loại giao dịch', transaction.typeLabel),
      if (transaction.description.isNotEmpty)
        ('Nội dung', transaction.description),
      if (transaction.referenceId != null)
        ('Mã tham chiếu', '#${transaction.referenceId}'),
      if (transaction.referenceTable?.isNotEmpty ?? false)
        ('Nguồn tham chiếu', _referenceLabel(transaction.referenceTable!)),
      if (transaction.providerTransactionId?.isNotEmpty ?? false)
        ('Mã đối soát', transaction.providerTransactionId!),
      if (transaction.paidAt != null)
        ('Hoàn tất lúc', tutorTransactionTimeLabel(transaction.paidAt)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: TutorColors.surface,
        border: Border.all(color: TutorColors.line),
        borderRadius: BorderRadius.circular(TutorSurface.radius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _DetailRow(label: rows[i].$1, value: rows[i].$2),
            if (i < rows.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: TutorColors.line,
              ),
          ],
        ],
      ),
    );
  }

  static String _referenceLabel(String value) => switch (value.toLowerCase()) {
    'withdrawalrequests' || 'withdrawal_requests' => 'Yêu cầu rút tiền',
    'bookings' => 'Đặt lịch học',
    'classsessions' || 'class_sessions' => 'Buổi học',
    _ => value,
  };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TutorType.caption(color: TutorColors.ink3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: TutorType.caption(color: TutorColors.ink2).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
