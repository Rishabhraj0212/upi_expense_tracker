import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/domain/models/transaction.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';

void main() {
  test('syncStatus defaults to pending when not specified (non-breaking for Phase 1 construction sites)', () {
    final now = DateTime(2026, 1, 1);
    final tx = Transaction(
      id: 1,
      amountPaise: 1000,
      type: TransactionType.debit,
      occurredAt: now,
      receivedAt: now,
      mergedSources: 'sms',
      rawText: 'x',
      createdAt: now,
      updatedAt: now,
    );

    expect(tx.syncStatus, TransactionSyncStatus.pending);
    expect(tx.lastSyncedAt, isNull);
    expect(tx.remoteRowRef, isNull);
    expect(tx.lastSyncError, isNull);
  });
}
