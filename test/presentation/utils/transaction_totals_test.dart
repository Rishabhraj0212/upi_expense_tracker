import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/transaction.dart' as domain;
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/presentation/utils/transaction_totals.dart';

domain.Transaction _tx(int amountPaise, TransactionType type) {
  final now = DateTime(2026, 1, 1);
  return domain.Transaction(
    id: 1,
    amountPaise: amountPaise,
    type: type,
    occurredAt: now,
    receivedAt: now,
    mergedSources: 'sms',
    rawText: 'x',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('sums debits and credits separately', () {
    final totals = computeTransactionTotals([
      _tx(10000, TransactionType.debit),
      _tx(5000, TransactionType.debit),
      _tx(20000, TransactionType.credit),
    ]);

    expect(totals.debitPaise, 15000);
    expect(totals.creditPaise, 20000);
    expect(totals.netBalancePaise, 5000);
  });

  test('returns zero totals for an empty list', () {
    final totals = computeTransactionTotals([]);

    expect(totals.debitPaise, 0);
    expect(totals.creditPaise, 0);
    expect(totals.netBalancePaise, 0);
  });
}
