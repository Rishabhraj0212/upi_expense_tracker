import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/dedup/duplicate_detector.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/transaction.dart' as domain;
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/domain/repositories/transaction_repository.dart';

/// Minimal fake: only the two lookup methods DuplicateDetector actually
/// calls are implemented; everything else is intentionally unreachable.
class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository(this.transactions);

  final List<domain.Transaction> transactions;

  @override
  Future<List<domain.Transaction>> findByReferenceId(String referenceId) async =>
      transactions.where((t) => t.referenceId == referenceId).toList();

  @override
  Future<List<domain.Transaction>> findByAmountNear(int amountPaise, DateTime around, Duration window) async {
    final from = around.subtract(window);
    final to = around.add(window);
    return transactions
        .where((t) => t.amountPaise == amountPaise && !t.occurredAt.isBefore(from) && !t.occurredAt.isAfter(to))
        .toList();
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used by DuplicateDetector');
}

int _nextId = 1;

domain.Transaction _tx({
  int amountPaise = 15000,
  TransactionType type = TransactionType.debit,
  required DateTime occurredAt,
  String mergedSources = 'sms',
  String? referenceId,
  String? merchantName,
  String? upiId,
}) {
  return domain.Transaction(
    id: _nextId++,
    amountPaise: amountPaise,
    type: type,
    occurredAt: occurredAt,
    receivedAt: occurredAt,
    mergedSources: mergedSources,
    rawText: 'existing raw text',
    createdAt: occurredAt,
    updatedAt: occurredAt,
    referenceId: referenceId,
    merchantName: merchantName,
    upiId: upiId,
  );
}

ParsedTransaction _parsed({
  int amountPaise = 15000,
  TransactionType type = TransactionType.debit,
  required DateTime occurredAt,
  SourceType sourceType = SourceType.notification,
  String? referenceId,
  String? merchantName,
  String? upiId,
}) {
  return ParsedTransaction(
    amountPaise: amountPaise,
    type: type,
    occurredAt: occurredAt,
    sourceType: sourceType,
    rawText: 'new raw text',
    referenceId: referenceId,
    merchantName: merchantName,
    upiId: upiId,
  );
}

void main() {
  final anchor = DateTime(2026, 1, 10, 12, 0, 0);

  test('returns null when there is nothing to match against', () async {
    final detector = DuplicateDetector(_FakeTransactionRepository([]));

    final result = await detector.findDuplicate(_parsed(occurredAt: anchor));

    expect(result, isNull);
  });

  test('matches on an exact reference id regardless of timing', () async {
    final existing = _tx(occurredAt: anchor.subtract(const Duration(days: 2)), referenceId: 'UTR123456789');
    final detector = DuplicateDetector(_FakeTransactionRepository([existing]));

    final result = await detector.findDuplicate(_parsed(occurredAt: anchor, referenceId: 'UTR123456789'));

    expect(result, same(existing));
  });

  test('merges a notification into an SMS seen 2 minutes earlier for the same amount', () async {
    final smsRow = _tx(
      amountPaise: 25000,
      occurredAt: anchor,
      mergedSources: 'sms',
      upiId: 'shop@upi',
    );
    final detector = DuplicateDetector(_FakeTransactionRepository([smsRow]));

    final result = await detector.findDuplicate(_parsed(
      amountPaise: 25000,
      occurredAt: anchor.add(const Duration(minutes: 2)),
      sourceType: SourceType.notification,
      upiId: 'shop@upi',
    ));

    expect(result, same(smsRow));
  });

  test('does not merge across channels once outside the merge window', () async {
    final smsRow = _tx(amountPaise: 25000, occurredAt: anchor, mergedSources: 'sms');
    final detector = DuplicateDetector(
      _FakeTransactionRepository([smsRow]),
      mergeWindow: const Duration(minutes: 5),
    );

    final result = await detector.findDuplicate(_parsed(
      amountPaise: 25000,
      occurredAt: anchor.add(const Duration(minutes: 10)),
      sourceType: SourceType.notification,
    ));

    expect(result, isNull);
  });

  test('treats a same-channel repeat within the repeat window and same payee as a duplicate', () async {
    final notifRow = _tx(
      amountPaise: 9900,
      occurredAt: anchor,
      mergedSources: 'notification',
      merchantName: 'Tea Stall',
    );
    final detector = DuplicateDetector(_FakeTransactionRepository([notifRow]));

    final result = await detector.findDuplicate(_parsed(
      amountPaise: 9900,
      occurredAt: anchor.add(const Duration(seconds: 5)),
      sourceType: SourceType.notification,
      merchantName: 'Tea Stall',
    ));

    expect(result, same(notifRow));
  });

  test('does not merge a same-channel same-amount event with a different payee', () async {
    final notifRow = _tx(
      amountPaise: 9900,
      occurredAt: anchor,
      mergedSources: 'notification',
      merchantName: 'Tea Stall',
    );
    final detector = DuplicateDetector(_FakeTransactionRepository([notifRow]));

    final result = await detector.findDuplicate(_parsed(
      amountPaise: 9900,
      occurredAt: anchor.add(const Duration(seconds: 5)),
      sourceType: SourceType.notification,
      merchantName: 'Coffee Shop',
    ));

    expect(result, isNull, reason: 'two different merchants paying the same amount seconds apart is not a duplicate');
  });

  test('does not merge a same-channel same-amount event once outside the short repeat window', () async {
    final notifRow = _tx(
      amountPaise: 9900,
      occurredAt: anchor,
      mergedSources: 'notification',
      merchantName: 'Tea Stall',
    );
    final detector = DuplicateDetector(_FakeTransactionRepository([notifRow]));

    final result = await detector.findDuplicate(_parsed(
      amountPaise: 9900,
      occurredAt: anchor.add(const Duration(minutes: 2)),
      sourceType: SourceType.notification,
      merchantName: 'Tea Stall',
    ));

    expect(result, isNull, reason: 'two minutes apart on the same channel is two separate payments, not a repeat');
  });

  test('prefers the closest-in-time candidate when several match', () async {
    final far = _tx(amountPaise: 5000, occurredAt: anchor.subtract(const Duration(minutes: 4)), mergedSources: 'sms');
    final near = _tx(amountPaise: 5000, occurredAt: anchor.subtract(const Duration(minutes: 1)), mergedSources: 'sms');
    final detector = DuplicateDetector(_FakeTransactionRepository([far, near]));

    final result = await detector.findDuplicate(_parsed(
      amountPaise: 5000,
      occurredAt: anchor,
      sourceType: SourceType.notification,
    ));

    expect(result, same(near));
  });

  test('reference id match wins even when an amount-window candidate also exists', () async {
    final byRef = _tx(
      amountPaise: 5000,
      occurredAt: anchor.subtract(const Duration(days: 1)),
      referenceId: 'REFAAA111',
      mergedSources: 'sms',
    );
    final byAmount = _tx(amountPaise: 5000, occurredAt: anchor, mergedSources: 'sms');
    final detector = DuplicateDetector(_FakeTransactionRepository([byRef, byAmount]));

    final result = await detector.findDuplicate(_parsed(
      amountPaise: 5000,
      occurredAt: anchor,
      referenceId: 'REFAAA111',
      sourceType: SourceType.notification,
    ));

    expect(result, same(byRef));
  });
}
