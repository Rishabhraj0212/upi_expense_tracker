import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';

/// Builds a database with exactly the schemaVersion-1 Phase 1 shape (no sync
/// columns, no sync_settings table), pre-populated with real-looking rows,
/// then hands it to the current AppDatabase so opening it exercises the
/// *real* onUpgrade path — not a hand-simulated approximation of it.
sqlite3.Database _buildV1Database() {
  final db = sqlite3.sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount_paise INTEGER NOT NULL,
      type TEXT NOT NULL,
      occurred_at INTEGER NOT NULL,
      received_at INTEGER NOT NULL,
      merchant_name TEXT, upi_id TEXT, bank_name TEXT, account_hint TEXT, reference_id TEXT,
      merged_sources TEXT NOT NULL, source_app TEXT, source_address TEXT,
      raw_text TEXT NOT NULL, category TEXT, note TEXT,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('CREATE INDEX idx_transactions_reference_id ON transactions(reference_id)');
  db.execute('CREATE INDEX idx_transactions_amount_time ON transactions(amount_paise, occurred_at)');
  db.execute('''
    CREATE TABLE raw_captures (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      at INTEGER NOT NULL, source_type TEXT NOT NULL, origin TEXT, text TEXT NOT NULL, result TEXT NOT NULL
    )
  ''');

  final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
  db.execute('''
    INSERT INTO transactions
      (amount_paise, type, occurred_at, received_at, merged_sources, raw_text, created_at, updated_at,
       merchant_name, upi_id, reference_id, category, note)
    VALUES
      (50000, 'debit', $now, $now, 'sms', 'a real Phase 1 row', $now, $now,
       'Tea Stall', 'teastall@ybl', 'REF12345678', 'Food', 'lunch')
  ''');
  db.execute('''
    INSERT INTO transactions (amount_paise, type, occurred_at, received_at, merged_sources, raw_text, created_at, updated_at)
    VALUES (200000, 'credit', $now, $now, 'notification', 'a second Phase 1 row', $now, $now)
  ''');
  db.execute('''
    INSERT INTO raw_captures (at, source_type, origin, text, result)
    VALUES ($now, 'sms', 'HDFCBK', 'some captured text', 'ignored')
  ''');

  db.execute('PRAGMA user_version = 1');
  return db;
}

void main() {
  test('upgrading a real v1 database to v2 preserves every row and adds sync defaults', () async {
    final rawDb = _buildV1Database();
    final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
    addTearDown(db.close);

    // Trigger the migration by making the first real query.
    final transactions = await db.select(db.transactions).get();

    expect(transactions, hasLength(2), reason: 'no Phase 1 row may be lost or duplicated by the migration');

    final teaStall = transactions.firstWhere((t) => t.merchantName == 'Tea Stall');
    expect(teaStall.rawText, 'a real Phase 1 row');
    expect(teaStall.referenceId, 'REF12345678');
    expect(teaStall.category, 'Food', reason: 'Phase 1 fields must survive untouched');
    expect(teaStall.note, 'lunch');
    expect(teaStall.syncStatus, TransactionSyncStatus.pending, reason: 'every pre-existing row starts pending');
    expect(teaStall.lastSyncedAt, isNull);
    expect(teaStall.remoteRowRef, isNull);
    expect(teaStall.lastSyncError, isNull);

    final secondRow = transactions.firstWhere((t) => t.rawText == 'a second Phase 1 row');
    expect(secondRow.syncStatus, TransactionSyncStatus.pending);

    // The diagnostic capture log must survive too.
    final captures = await db.select(db.rawCaptures).get();
    expect(captures, hasLength(1));
    expect(captures.single.text_, 'some captured text');

    // An upgraded install must default to LOCAL_ONLY, never NOT_CONFIGURED —
    // the first-launch prompt must never resurface for existing users.
    final settings = await db.select(db.syncSettingsTable).getSingle();
    expect(settings.syncPreference, SyncPreference.localOnly);
    expect(settings.connectionState, GoogleConnectionState.disconnected);
    expect(settings.autoSyncEnabled, isFalse);
    expect(settings.lastSyncRunState, SyncRunState.idle);
  });

  test('a fresh (new-install) database starts as NOT_CONFIGURED', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final settings = await db.select(db.syncSettingsTable).getSingle();

    expect(settings.syncPreference, SyncPreference.notConfigured);
    expect(settings.connectionState, GoogleConnectionState.disconnected);
    expect(settings.autoSyncEnabled, isFalse);
    expect(settings.lastSyncRunState, SyncRunState.idle);
  });

  test('a fresh database has no transactions and the schema accepts a sync-aware insert', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.select(db.transactions).get(), isEmpty);

    final now = DateTime(2026, 1, 1);
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          amountPaise: 1000,
          type: TransactionType.debit,
          occurredAt: now,
          receivedAt: now,
          mergedSources: 'sms',
          rawText: 'x',
          createdAt: now,
          updatedAt: now,
          syncStatus: TransactionSyncStatus.pending,
        ));

    final rows = await db.select(db.transactions).get();
    expect(rows.single.syncStatus, TransactionSyncStatus.pending);
  });
}
