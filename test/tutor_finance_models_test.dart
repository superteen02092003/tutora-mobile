import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';

void main() {
  test('transaction detail parses reconciliation fields', () {
    final transaction = TutorTransaction.fromJson({
      'transactionId': 42,
      'amount': -47500,
      'transactionType': 'Withdrawal',
      'description': 'Rút tiền về ngân hàng',
      'createdAt': '2026-08-17T08:00:00Z',
      'referenceId': 12,
      'referenceTable': 'withdrawal_requests',
      'providerTransactionId': 'bank-transaction-42',
      'paidAt': '2026-08-17T09:00:00Z',
      'proofImageUrl': 'https://example.com/proof.jpg',
    });

    expect(transaction.transactionId, 42);
    expect(transaction.isCredit, isFalse);
    expect(transaction.typeLabel, 'Rút tiền');
    expect(transaction.referenceId, 12);
    expect(transaction.providerTransactionId, 'bank-transaction-42');
    expect(transaction.paidAt, isNotNull);
    expect(transaction.proofImageUrl, 'https://example.com/proof.jpg');
  });

  test('transaction page reports whether another page exists', () {
    final page = TutorTransactionPage.fromJson({
      'transactions': <Map<String, dynamic>>[],
      'totalCount': 41,
      'page': 2,
      'pageSize': 20,
    });

    expect(page.hasMore, isTrue);
  });
}
