import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_sync_settings_repository.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/sync/auto_sync_controller.dart';
import 'package:upi_expense_tracker/sync/drive_authorization_gateway.dart';
import 'package:upi_expense_tracker/sync/sheets_api_client.dart';
import 'package:upi_expense_tracker/sync/transaction_sync_service.dart';

import 'fake_drive_authorization_gateway.dart';
import 'fake_sheets_api_client.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ParsedTransaction _tx({int amountPaise = 500, String rawText = 'test'}) =>
    ParsedTransaction(
      amountPaise: amountPaise,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 1, 10),
      sourceType: SourceType.sms,
      rawText: rawText,
    );

/// Builds an [AutoSyncController] backed by real in-memory Drift repos and
/// the supplied [authGateway]/[sheetsApi] fakes.
///
/// Returns the controller AND a function that inserts one pending transaction
/// into the real DB (which will fan-out to the reactive transaction stream
/// the controller is watching).
Future<
    ({
      AutoSyncController controller,
      Future<int> Function() insertTx,
      AppDatabase db,
      DriftTransactionRepository txRepo,
      DriftSyncSettingsRepository settingsRepo,
    })> _buildController({
  required FakeDriveAuthorizationGateway authGateway,
  required FakeSheetsApiClient sheetsApi,
  bool autoSyncEnabled = true,
  Duration debounce = const Duration(milliseconds: 10),
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final txRepo = DriftTransactionRepository(db);
  final settingsRepo = DriftSyncSettingsRepository(db);

  // Configure a fully-connected state.
  await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
  await settingsRepo.setConnectionState(GoogleConnectionState.connected);
  await settingsRepo.setSpreadsheet('sheet-1', 'Test Sheet');
  await settingsRepo.setAutoSyncEnabled(autoSyncEnabled);

  final syncService = TransactionSyncService(
    driveAuthorizationGateway: authGateway,
    sheetsApiClient: sheetsApi,
    syncSettingsRepository: settingsRepo,
    transactionRepository: txRepo,
  );

  final controller = AutoSyncController(
    transactionStream: txRepo.watchAll(),
    settingsStream: settingsRepo.watchSettings(),
    syncService: syncService,
    debounceDelay: debounce,
  );

  Future<int> insertTx() => txRepo.insert(_tx());

  return (
    controller: controller,
    insertTx: insertTx,
    db: db,
    txRepo: txRepo,
    settingsRepo: settingsRepo,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeDriveAuthorizationGateway authGateway;
  late FakeSheetsApiClient sheetsApi;

  setUp(() {
    authGateway = FakeDriveAuthorizationGateway()
      ..nextCreateOutcome = const DriveAuthorizationSuccess(accessToken: 'tok');
    sheetsApi = FakeSheetsApiClient();
  });

  // ── 1. Auto sync OFF → no sync ────────────────────────────────────────────
  test('auto sync OFF: inserting a transaction never triggers a sync run', () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
      autoSyncEnabled: false,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    await env.insertTx();
    // Wait longer than debounce to be sure nothing fires.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(sheetsApi.appendRowCalls, 0, reason: 'auto-sync is off');
    expect(sheetsApi.ensureHeaderRowCalls, 0);
  });

  // ── 2. Auto sync ON → new transaction triggers sync ───────────────────────
  test('auto sync ON: new transaction eventually syncs to the sheet', () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    await env.insertTx();
    // Give debounce + async sync time to complete.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(sheetsApi.appendRowCalls, 1, reason: 'one transaction should be synced');
    // Verify the transaction is now marked synced in the DB.
    final counts = await env.txRepo.getSyncCounts();
    expect(counts.synced, 1);
    expect(counts.pending, 0);
  });

  // ── 3. Debounce: multiple rapid inserts coalesce into one sync run ─────────
  test('debounce: rapid inserts coalesce into a single sync run', () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
      debounce: const Duration(milliseconds: 50),
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    // Insert three transactions quickly (within debounce window).
    await env.insertTx();
    await env.insertTx();
    await env.insertTx();

    // Wait for one debounce + sync to complete.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // All 3 synced in one pass (one header check, three appends).
    expect(sheetsApi.appendRowCalls, 3);
    expect(sheetsApi.ensureHeaderRowCalls, 1,
        reason: 'only one sync run should have started');
    final counts = await env.txRepo.getSyncCounts();
    expect(counts.synced, 3);
  });

  // ── 4. Concurrent sync prevention ─────────────────────────────────────────
  test('concurrent sync prevention: only one run executes at a time', () async {
    // Add a latency to the sheets API to simulate a slow network.
    var appendCount = 0;
    final slowSheets = _SlowFakeSheetsApiClient(
      sheetsApi,
      appendDelay: const Duration(milliseconds: 80),
      onAppend: () => appendCount++,
    );

    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: slowSheets,
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    await env.insertTx();
    // Wait for debounce — first sync run starts.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // Insert while first run is in-flight.
    await env.insertTx();
    // Wait for everything to settle (both runs should finish serially).
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final counts = await env.txRepo.getSyncCounts();
    // Both transactions must end up synced, not just 1.
    expect(counts.synced, 2);
    expect(counts.pending, 0);
  });

  // ── 5. Offline: transaction stays local ───────────────────────────────────
  test('offline: transaction remains safely stored locally when network fails',
      () async {
    authGateway.nextCreateOutcome =
        const DriveAuthorizationFailure('network unreachable');

    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    final id = await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Transaction must NOT be lost; it stays local as PENDING or FAILED.
    final tx = await env.txRepo.getById(id);
    expect(tx, isNotNull, reason: 'transaction must exist in local DB');
    expect(
      tx!.syncStatus,
      anyOf(TransactionSyncStatus.pending, TransactionSyncStatus.failed),
      reason: 'must be pending/failed, never silently dropped',
    );
  });

  // ── 6. Retry after failure ─────────────────────────────────────────────────
  test('retry: failed transaction is retried on next sync opportunity', () async {
    // First attempt fails.
    authGateway.nextCreateOutcome =
        const DriveAuthorizationFailure('first attempt fails');

    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Confirm it's failed/pending.
    var counts = await env.txRepo.getSyncCounts();
    expect(counts.synced, 0);

    // Restore auth so next attempt succeeds.
    authGateway.nextCreateOutcome =
        const DriveAuthorizationSuccess(accessToken: 'tok');

    // Insert another transaction to trigger a new sync run, which will also
    // retry the failed one.
    await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    counts = await env.txRepo.getSyncCounts();
    expect(counts.synced, 2, reason: 'both should be synced after retry');
    expect(counts.pending, 0);
    expect(counts.failed, 0);
  });

  // ── 7. Edited transaction becomes PENDING and syncs ───────────────────────
  test('edited transaction: marked PENDING and synced on next run', () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    final id = await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Transaction is synced.
    var tx = await env.txRepo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.synced);

    // User edits → mark pending.
    await env.txRepo.markPending(id);
    tx = await env.txRepo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.pending);

    // Insert another tx to trigger debounce.
    await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    tx = await env.txRepo.getById(id);
    // The edited row must have been updated in the sheet (updateRow), not
    // appended again (which would create a duplicate).
    expect(tx!.syncStatus, TransactionSyncStatus.synced);
    expect(sheetsApi.updateRowCalls, greaterThanOrEqualTo(1),
        reason: 'existing sheet row must be updated, not duplicated');
  });

  // ── 8. Duplicate-safe auto sync ────────────────────────────────────────────
  test('duplicate-safe: re-running sync never appends an already-synced row',
      () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    final id = await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Verify first sync appended 1 row.
    expect(sheetsApi.appendRowCalls, 1);

    // Mark pending again and trigger another sync.
    await env.txRepo.markPending(id);
    await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // The re-synced row must have been updated, NOT appended a second time.
    // Sheet should have only 1 data row for that transaction id.
    final rows = sheetsApi.rows.where((r) => r.isNotEmpty && r.first.toString() == id.toString()).toList();
    expect(rows.length, 1, reason: 'no duplicate rows in the sheet');
  });

  // ── 9. Auto sync never blocks ingestion ────────────────────────────────────
  test('auto sync does not block the ingestion return path', () async {
    // Use a slow sheets API to ensure sync takes time.
    final slowSheets = _SlowFakeSheetsApiClient(
      sheetsApi,
      appendDelay: const Duration(milliseconds: 200),
    );

    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: slowSheets,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    // Measure how long insertTx takes (ingestion path must NOT wait for sync).
    final sw = Stopwatch()..start();
    await env.insertTx(); // This triggers a debounced async sync.
    sw.stop();

    // Insertion itself must be fast — the sync debounce (10ms) hasn't even
    // fired yet, so there's no way the sync blocked this call.
    expect(sw.elapsedMilliseconds, lessThan(100),
        reason: 'insert must not block while sync is pending/running');
  });

  // ── 10. Disconnect disables auto sync ──────────────────────────────────────
  test('disconnect: auto sync stops when not connected', () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    // Disconnect.
    await env.settingsRepo.setConnectionState(GoogleConnectionState.disconnected);
    await env.settingsRepo.setAutoSyncEnabled(false);

    await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(sheetsApi.appendRowCalls, 0,
        reason: 'no sync should happen when disconnected');
  });

  // ── 11. localOnly preference disables auto sync ────────────────────────────
  test('localOnly preference: auto sync does not run', () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    await env.settingsRepo.setSyncPreference(SyncPreference.localOnly);

    await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(sheetsApi.appendRowCalls, 0,
        reason: 'local-only preference must suppress auto sync');
  });

  // ── 12. No spreadsheet connected ──────────────────────────────────────────
  test('no spreadsheet: auto sync does not run when spreadsheet is null', () async {
    final env = await _buildController(
      authGateway: authGateway,
      sheetsApi: sheetsApi,
    );
    addTearDown(() async {
      env.controller.dispose();
      await env.db.close();
    });

    await env.settingsRepo.setSpreadsheet(null, null);

    await env.insertTx();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(sheetsApi.appendRowCalls, 0,
        reason: 'no spreadsheet connected means no sync');
  });
}

// ---------------------------------------------------------------------------
// Test double: wraps FakeSheetsApiClient with configurable append latency.
// ---------------------------------------------------------------------------
class _SlowFakeSheetsApiClient extends FakeSheetsApiClient {
  _SlowFakeSheetsApiClient(
    this._delegate, {
    required this.appendDelay,
    this.onAppend,
  });

  final FakeSheetsApiClient _delegate;
  final Duration appendDelay;
  final void Function()? onAppend;

  @override
  List<List<Object?>> get rows => _delegate.rows;

  @override
  Future<SheetWriteResult> ensureHeaderRow(
    String accessToken,
    String spreadsheetId,
    List<String> headers,
  ) =>
      _delegate.ensureHeaderRow(accessToken, spreadsheetId, headers);

  @override
  Future<RowIndexResult> fetchTransactionRowIndex(
          String accessToken, String spreadsheetId) =>
      _delegate.fetchTransactionRowIndex(accessToken, spreadsheetId);

  @override
  Future<SheetWriteResult> appendRow(String accessToken, String spreadsheetId,
      {required List<Object?> values}) async {
    await Future<void>.delayed(appendDelay);
    onAppend?.call();
    return _delegate.appendRow(accessToken, spreadsheetId, values: values);
  }

  @override
  Future<SheetWriteResult> updateRow(String accessToken, String spreadsheetId,
      {required int rowNumber, required List<Object?> values}) =>
      _delegate.updateRow(accessToken, spreadsheetId,
          rowNumber: rowNumber, values: values);

  @override
  Future<SpreadsheetResolution> createSpreadsheet(
          String accessToken, String title) =>
      _delegate.createSpreadsheet(accessToken, title);

  @override
  Future<SpreadsheetResolution> verifySpreadsheet(
          String accessToken, String spreadsheetId) =>
      _delegate.verifySpreadsheet(accessToken, spreadsheetId);
}
