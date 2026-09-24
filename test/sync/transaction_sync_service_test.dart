import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_sync_settings_repository.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/sync/drive_authorization_gateway.dart';
import 'package:upi_expense_tracker/sync/sheets_api_client.dart';
import 'package:upi_expense_tracker/sync/transaction_sync_service.dart';

import 'fake_drive_authorization_gateway.dart';
import 'fake_sheets_api_client.dart';

void main() {
  late AppDatabase db;
  late DriftTransactionRepository txRepo;
  late DriftSyncSettingsRepository settingsRepo;
  late FakeDriveAuthorizationGateway authGateway;
  late FakeSheetsApiClient sheetsApi;
  late TransactionSyncService service;

  Future<int> insertPending({int amountPaise = 1000, String rawText = 'x'}) {
    return txRepo.insert(
      ParsedTransaction(
        amountPaise: amountPaise,
        type: TransactionType.debit,
        occurredAt: DateTime(2026, 1, 1),
        sourceType: SourceType.sms,
        rawText: rawText,
      ),
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txRepo = DriftTransactionRepository(db);
    settingsRepo = DriftSyncSettingsRepository(db);
    authGateway = FakeDriveAuthorizationGateway()
      ..nextCreateOutcome = const DriveAuthorizationSuccess(accessToken: 'token-abc');
    sheetsApi = FakeSheetsApiClient();
    service = TransactionSyncService(
      driveAuthorizationGateway: authGateway,
      sheetsApiClient: sheetsApi,
      syncSettingsRepository: settingsRepo,
      transactionRepository: txRepo,
    );

    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);
    await settingsRepo.setSpreadsheet('sheet-1', 'UPI Expense Tracker');
  });

  tearDown(() => db.close());

  test('empty pending list: nothing to sync, immediately reports fully synced, touches nothing remote', () async {
    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunCompleted>());
    expect((outcome as SyncRunCompleted).succeeded, 0);
    expect(outcome.failed, 0);
    expect(outcome.isFullySynced, isTrue);
    expect(authGateway.createCalls, 0, reason: 'no authorization should be requested when there is nothing to sync');
    expect(sheetsApi.appendRowCalls, 0);

    final settings = await settingsRepo.getSettings();
    expect(settings.lastSyncRunState, SyncRunState.synced);
    expect(settings.lastSuccessfulSyncAt, isNotNull);
  });

  test('initial sync: writes the header row once, then every pending transaction as a new row', () async {
    final id1 = await insertPending(amountPaise: 1000, rawText: 'a');
    final id2 = await insertPending(amountPaise: 2000, rawText: 'b');

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunCompleted>());
    expect((outcome as SyncRunCompleted).succeeded, 2);
    expect(outcome.failed, 0);
    expect(sheetsApi.ensureHeaderRowCalls, 1);
    expect(sheetsApi.rows.first, transactionSheetHeaders);
    expect(sheetsApi.dataRowCount, 2);
    expect(sheetsApi.rowValuesForTransactionId(id1.toString()), isNotNull);
    expect(sheetsApi.rowValuesForTransactionId(id2.toString()), isNotNull);
  });

  test('successful sync: marks the transaction SYNCED with a remote row reference and clears any prior error', () async {
    final id = await insertPending();
    await txRepo.markSyncFailed(id, 'a previous, now-stale error');

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunCompleted>());
    expect((outcome as SyncRunCompleted).isFullySynced, isTrue);

    final tx = await txRepo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.synced);
    expect(tx.lastSyncError, isNull);
    expect(tx.lastSyncedAt, isNotNull);
    expect(tx.remoteRowRef, isNotNull);

    final settings = await settingsRepo.getSettings();
    expect(settings.lastSyncRunState, SyncRunState.synced);
    expect(settings.lastSuccessfulSyncAt, isNotNull);
  });

  test('remote row reference: matches the actual row number Sheets assigned', () async {
    final id = await insertPending();

    await service.syncPendingTransactions();

    final tx = await txRepo.getById(id);
    // Header occupies row 1, so the first data row must be row 2.
    expect(tx!.remoteRowRef, '2');
    expect(sheetsApi.rowValuesForTransactionId(id.toString())?.first, id.toString());
  });

  test('duplicate-safe sync: a transaction id already present in the sheet is updated in place, never appended twice', () async {
    final id = await insertPending(amountPaise: 1000);
    // Simulate the row already existing remotely (e.g. from a run that
    // wrote the sheet successfully but crashed before the local markSynced
    // call landed) — local status is still pending.
    sheetsApi.seedHeader(transactionSheetHeaders);
    sheetsApi.seedDataRow([id.toString(), '2026-01-01T00:00:00.000', 'debit', 5.0, 'UPI transaction', '', '', '', '', '']);

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunCompleted>());
    expect((outcome as SyncRunCompleted).succeeded, 1);
    expect(sheetsApi.appendRowCalls, 0, reason: 'must update the existing row, not append a new one');
    expect(sheetsApi.updateRowCalls, 1);
    expect(sheetsApi.dataRowCount, 1, reason: 'exactly one row for this transaction id, never duplicated');

    final tx = await txRepo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.synced);
    expect(tx.remoteRowRef, '2');
  });

  test('already-SYNCED transactions are excluded from the run and never duplicated', () async {
    final syncedId = await insertPending(amountPaise: 1000);
    await txRepo.markSynced(syncedId, remoteRowRef: '2', syncedAt: DateTime(2026, 1, 1));
    await insertPending(amountPaise: 2000);

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunCompleted>());
    expect((outcome as SyncRunCompleted).succeeded, 1, reason: 'only the still-pending transaction should be synced');
    expect(sheetsApi.dataRowCount, 1);
    expect(
      sheetsApi.rowValuesForTransactionId(syncedId.toString()),
      isNull,
      reason: 'an already-synced transaction must not be written again',
    );
  });

  test('partial failure: one transaction fails, the other succeeds, both outcomes stay visible', () async {
    final okId = await insertPending(amountPaise: 1000, rawText: 'ok');
    final failId = await insertPending(amountPaise: 2000, rawText: 'fail');
    sheetsApi.failWritesForIds.add(failId.toString());
    sheetsApi.writeFailureReason = 'HTTP 500';

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunCompleted>());
    expect((outcome as SyncRunCompleted).succeeded, 1);
    expect(outcome.failed, 1);
    expect(outcome.isFullySynced, isFalse);

    final okTx = await txRepo.getById(okId);
    expect(okTx!.syncStatus, TransactionSyncStatus.synced);

    final failTx = await txRepo.getById(failId);
    expect(failTx!.syncStatus, TransactionSyncStatus.failed);
    expect(failTx.lastSyncError, 'HTTP 500');

    final settings = await settingsRepo.getSettings();
    expect(settings.lastSyncRunState, SyncRunState.partiallySynced);
    expect(
      settings.lastSuccessfulSyncAt,
      isNull,
      reason: 'must not claim a successful sync run when something failed',
    );

    final counts = await txRepo.getSyncCounts();
    expect(counts.synced, 1);
    expect(counts.failed, 1);
    expect(counts.pending, 0);
  });

  test('retry: re-running after fixing the failure condition syncs the previously-failed transaction', () async {
    final okId = await insertPending(amountPaise: 1000, rawText: 'ok');
    final failId = await insertPending(amountPaise: 2000, rawText: 'fail');
    sheetsApi.failWritesForIds.add(failId.toString());

    final first = await service.syncPendingTransactions();
    expect((first as SyncRunCompleted).failed, 1);

    // Retry: the failure condition is gone, and getTransactionsNeedingSync
    // must still surface the FAILED row for another attempt.
    sheetsApi.failWritesForIds.clear();
    final retryOutcome = await service.syncPendingTransactions();

    expect(retryOutcome, isA<SyncRunCompleted>());
    expect((retryOutcome as SyncRunCompleted).succeeded, 1);
    expect(retryOutcome.failed, 0);
    expect(retryOutcome.isFullySynced, isTrue);

    final okTx = await txRepo.getById(okId);
    expect(okTx!.syncStatus, TransactionSyncStatus.synced, reason: 'already-synced row must be untouched by the retry');
    final failTx = await txRepo.getById(failId);
    expect(failTx!.syncStatus, TransactionSyncStatus.synced);
    expect(failTx.lastSyncError, isNull);

    final settings = await settingsRepo.getSettings();
    expect(settings.lastSyncRunState, SyncRunState.synced);
    expect(settings.lastSuccessfulSyncAt, isNotNull);

    // Retry must not create a second row for the retried transaction.
    expect(sheetsApi.dataRowCount, 2);
  });

  test('local status transitions: pending -> synced, and pending -> failed with an error recorded', () async {
    final syncedId = await insertPending(rawText: 'will succeed');
    final failedId = await insertPending(rawText: 'will fail');
    sheetsApi.failWritesForIds.add(failedId.toString());

    var before = await txRepo.getById(syncedId);
    expect(before!.syncStatus, TransactionSyncStatus.pending);
    before = await txRepo.getById(failedId);
    expect(before!.syncStatus, TransactionSyncStatus.pending);

    await service.syncPendingTransactions();

    final afterSynced = await txRepo.getById(syncedId);
    expect(afterSynced!.syncStatus, TransactionSyncStatus.synced);
    final afterFailed = await txRepo.getById(failedId);
    expect(afterFailed!.syncStatus, TransactionSyncStatus.failed);
    expect(afterFailed.lastSyncError, isNotNull);
  });

  test('progress callback reports completed/total as each transaction is written', () async {
    await insertPending(rawText: 'a');
    await insertPending(rawText: 'b');
    await insertPending(rawText: 'c');

    final seen = <SyncProgress>[];
    await service.syncPendingTransactions(onProgress: seen.add);

    expect(seen.length, 3);
    expect(seen.map((p) => p.completed).toList(), [1, 2, 3]);
    expect(seen.every((p) => p.total == 3), isTrue);
  });

  test('local Drift data is left untouched when the Sheets API is unreachable', () async {
    final id = await insertPending(amountPaise: 12345, rawText: 'unchanged');
    sheetsApi.forcedHeaderResult = const SheetWriteFailure('network unreachable');

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunAborted>());
    final tx = await txRepo.getById(id);
    expect(tx!.amountPaise, 12345);
    expect(tx.rawText, 'unchanged');
    expect(tx.syncStatus, TransactionSyncStatus.pending, reason: 'never attempted, so stays pending, not failed');

    final settings = await settingsRepo.getSettings();
    expect(settings.lastSyncRunState, SyncRunState.syncFailed);
  });

  test('aborts cleanly when no spreadsheet is connected', () async {
    await settingsRepo.setSpreadsheet(null, null);
    await insertPending();

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunAborted>());
    expect(authGateway.createCalls, 0);
  });

  test('aborts cleanly when authorization fails, without touching any transaction', () async {
    authGateway.nextCreateOutcome = const DriveAuthorizationFailure('consent revoked');
    final id = await insertPending();

    final outcome = await service.syncPendingTransactions();

    expect(outcome, isA<SyncRunAborted>());
    expect((outcome as SyncRunAborted).reason, 'consent revoked');
    final tx = await txRepo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.pending);
  });
}
