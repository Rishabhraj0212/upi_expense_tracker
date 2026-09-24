import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/domain/repositories/transaction_repository.dart';

ParsedTransaction _sample({
  int amountPaise = 15000,
  TransactionType type = TransactionType.debit,
  DateTime? occurredAt,
  String? referenceId,
  String? merchantName,
  String? upiId,
  SourceType sourceType = SourceType.sms,
  String rawText = 'sample raw text',
}) {
  return ParsedTransaction(
    amountPaise: amountPaise,
    type: type,
    occurredAt: occurredAt ?? DateTime(2026, 1, 10, 12, 0),
    sourceType: sourceType,
    rawText: rawText,
    referenceId: referenceId,
    merchantName: merchantName,
    upiId: upiId,
  );
}

void main() {
  late AppDatabase db;
  late DriftTransactionRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTransactionRepository(db);
  });

  tearDown(() => db.close());

  test('insert then getById round-trips all fields', () async {
    final id = await repo.insert(_sample(
      amountPaise: 25099,
      merchantName: 'Tea Stall',
      upiId: 'teastall@okhdfcbank',
      referenceId: 'REF123456789',
    ));

    final tx = await repo.getById(id);

    expect(tx, isNotNull);
    expect(tx!.amountPaise, 25099);
    expect(tx.type, TransactionType.debit);
    expect(tx.merchantName, 'Tea Stall');
    expect(tx.upiId, 'teastall@okhdfcbank');
    expect(tx.referenceId, 'REF123456789');
    expect(tx.mergedSources, 'sms');
    expect(tx.rawText, 'sample raw text');
  });

  test('a newly inserted transaction starts sync-pending', () async {
    final id = await repo.insert(_sample());

    final tx = await repo.getById(id);

    expect(tx!.syncStatus, TransactionSyncStatus.pending);
    expect(tx.lastSyncedAt, isNull);
    expect(tx.remoteRowRef, isNull);
    expect(tx.lastSyncError, isNull);
  });

  test('getTransactionsNeedingSync returns pending and failed rows, not synced ones', () async {
    final pendingId = await repo.insert(_sample(amountPaise: 1000));
    final failedId = await repo.insert(_sample(amountPaise: 2000));
    final syncedId = await repo.insert(_sample(amountPaise: 3000));

    await repo.markSyncFailed(failedId, 'network error');
    await repo.markSynced(syncedId, remoteRowRef: '5', syncedAt: DateTime(2026, 1, 1));

    final needingSync = await repo.getTransactionsNeedingSync();

    expect(needingSync.map((t) => t.id), containsAll([pendingId, failedId]));
    expect(needingSync.map((t) => t.id), isNot(contains(syncedId)));
  });

  test('markSynced sets synced status, timestamp, remote ref, and clears any prior error', () async {
    final id = await repo.insert(_sample());
    await repo.markSyncFailed(id, 'temporary failure');

    final syncedAt = DateTime(2026, 3, 1, 9, 30);
    await repo.markSynced(id, remoteRowRef: '42', syncedAt: syncedAt);

    final tx = await repo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.synced);
    expect(tx.lastSyncedAt, syncedAt);
    expect(tx.remoteRowRef, '42');
    expect(tx.lastSyncError, isNull, reason: 'a fresh successful sync clears any earlier error');
  });

  test('markSyncFailed sets failed status and records the error, leaving other fields untouched', () async {
    final id = await repo.insert(_sample());

    await repo.markSyncFailed(id, 'quota exceeded');

    final tx = await repo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.failed);
    expect(tx.lastSyncError, 'quota exceeded');
  });

  test('markPending resets a synced/failed row back to pending and clears the error', () async {
    final id = await repo.insert(_sample());
    await repo.markSyncFailed(id, 'some error');

    await repo.markPending(id);

    final tx = await repo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.pending);
    expect(tx.lastSyncError, isNull);
  });

  test('getSyncCounts aggregates by status correctly', () async {
    final syncedId = await repo.insert(_sample(amountPaise: 1000));
    await repo.insert(_sample(amountPaise: 2000));
    await repo.insert(_sample(amountPaise: 3000));
    final failedId = await repo.insert(_sample(amountPaise: 4000));

    await repo.markSynced(syncedId, syncedAt: DateTime(2026, 1, 1));
    await repo.markSyncFailed(failedId, 'oops');

    final counts = await repo.getSyncCounts();

    expect(counts.synced, 1);
    expect(counts.pending, 2);
    expect(counts.failed, 1);
    expect(counts.total, 4);
  });

  test('getAll returns newest first', () async {
    await repo.insert(_sample(occurredAt: DateTime(2026, 1, 1)));
    await repo.insert(_sample(occurredAt: DateTime(2026, 1, 3)));
    await repo.insert(_sample(occurredAt: DateTime(2026, 1, 2)));

    final all = await repo.getAll();

    expect(all.map((t) => t.occurredAt.day).toList(), [3, 2, 1]);
  });

  test('findByReferenceId finds an exact match', () async {
    await repo.insert(_sample(referenceId: 'AAA'));
    await repo.insert(_sample(referenceId: 'BBB'));

    final found = await repo.findByReferenceId('BBB');

    expect(found, hasLength(1));
    expect(found.single.referenceId, 'BBB');
  });

  test('findByAmountNear respects the time window', () async {
    final anchor = DateTime(2026, 1, 10, 12, 0);
    await repo.insert(_sample(amountPaise: 5000, occurredAt: anchor));
    await repo.insert(_sample(amountPaise: 5000, occurredAt: anchor.add(const Duration(minutes: 4))));
    await repo.insert(_sample(amountPaise: 5000, occurredAt: anchor.add(const Duration(minutes: 30))));

    final near = await repo.findByAmountNear(5000, anchor, const Duration(minutes: 5));

    expect(near, hasLength(2));
  });

  test('mergeInto fills gaps and records both sources without duplicating the row', () async {
    final id = await repo.insert(_sample(
      sourceType: SourceType.sms,
      merchantName: null,
      upiId: 'shop@upi',
      referenceId: null,
    ));

    await repo.mergeInto(
      id,
      _sample(
        sourceType: SourceType.notification,
        merchantName: 'Corner Shop',
        referenceId: 'UTR999',
      ),
    );

    final merged = await repo.getById(id);
    final all = await repo.getAll();

    expect(all, hasLength(1), reason: 'merge must not create a second row');
    expect(merged!.merchantName, 'Corner Shop');
    expect(merged.upiId, 'shop@upi');
    expect(merged.referenceId, 'UTR999');
    expect(merged.sourceList, containsAll(['sms', 'notification']));
  });

  test('mergeInto prefers a human name over a bare VPA from either side', () async {
    final id = await repo.insert(_sample(merchantName: 'user@okaxis'));

    await repo.mergeInto(id, _sample(merchantName: 'Real Merchant Name'));

    final merged = await repo.getById(id);
    expect(merged!.merchantName, 'Real Merchant Name');
  });

  test('setCategory updates category and note', () async {
    final id = await repo.insert(_sample());

    await repo.setCategory(id, 'Food', 'lunch with team');

    final tx = await repo.getById(id);
    expect(tx!.category, 'Food');
    expect(tx.note, 'lunch with team');
  });

  test('delete removes the row', () async {
    final id = await repo.insert(_sample());
    await repo.delete(id);

    expect(await repo.getById(id), isNull);
  });

  test('watchAll emits an updated list after an insert', () async {
    final emissions = <int>[];
    final sub = repo.watchAll().listen((rows) => emissions.add(rows.length));

    await Future<void>.delayed(Duration.zero);
    await repo.insert(_sample());
    await Future<void>.delayed(Duration.zero);
    await repo.insert(_sample());
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(emissions, [0, 1, 2]);
  });

  test('getAll filters by type', () async {
    await repo.insert(_sample(type: TransactionType.debit));
    await repo.insert(_sample(type: TransactionType.credit));

    final debitsOnly = await repo.getAll(filter: const TransactionFilter(type: TransactionType.debit));

    expect(debitsOnly, hasLength(1));
    expect(debitsOnly.single.type, TransactionType.debit);
  });

  test('capture log records entries and enforces the cap', () async {
    for (var i = 0; i < 5; i++) {
      await repo.logCapture(
        sourceType: 'sms',
        origin: 'HDFCBK',
        text: 'msg $i',
        result: 'ignored',
        at: DateTime(2026, 1, 1, 0, i),
      );
    }

    final captures = await repo.getCaptures(limit: 10);
    expect(captures, hasLength(5));
    expect(captures.first.text, 'msg 4', reason: 'newest first');

    await repo.clearCaptures();
    expect(await repo.getCaptures(), isEmpty);
  });
}
