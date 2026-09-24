import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/sync_status.dart';
import '../../domain/models/transaction_source.dart';
import '../../domain/models/transaction_type.dart';
import '../../parsing/common/date_extractors.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Transactions,
    RawCaptures,
    SyncSettingsTable,
    ExpenseCategories,
    CategoryRules,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by tests to inject an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX idx_transactions_reference_id ON transactions(reference_id)',
          );
          await customStatement(
            'CREATE INDEX idx_transactions_amount_time ON transactions(amount_paise, occurred_at)',
          );
          // New install: no first-launch choice has been made yet.
          await _insertDefaultSyncSettingsRow(SyncPreference.notConfigured);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // A NOT NULL column added to a table with existing rows requires
            // a DEFAULT in SQLite; every pre-existing transaction becomes
            // pending, exactly as if it had never been synced (which it hasn't).
            await customStatement(
              "ALTER TABLE transactions ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
            );
            await customStatement('ALTER TABLE transactions ADD COLUMN last_synced_at INTEGER');
            await customStatement('ALTER TABLE transactions ADD COLUMN remote_row_ref TEXT');
            await customStatement('ALTER TABLE transactions ADD COLUMN last_sync_error TEXT');

            await m.createTable(syncSettingsTable);
            // An existing Phase 1 install already made its implicit choice
            // (use the app locally) long before this concept existed —
            // never surface the first-launch prompt to these users.
            await _insertDefaultSyncSettingsRow(SyncPreference.localOnly);
          }
          if (from < 3) {
            // Fix: BOB-style YYYY:MM:DD timestamps in raw_text were previously
            // parsed as 09:24 (month:day) instead of the actual time (01:23).
            // Re-parse occurredAt from raw_text for every row so timestamps
            // are corrected in place. received_at is used as the fallback.
            final rows = await select(transactions).get();
            for (final row in rows) {
              final fixed = DateExtractors.extractDateTime(row.rawText, row.receivedAt);
              // Only update if the reparsed time is meaningfully different
              // (>= 1 minute off) to avoid unnecessary writes.
              final diff = fixed.difference(row.occurredAt).abs();
              if (diff.inMinutes >= 1) {
                await (update(transactions)..where((t) => t.id.equals(row.id))).write(
                  TransactionsCompanion(occurredAt: Value(fixed)),
                );
              }
            }
          }
          if (from < 4) {
            await m.createTable(expenseCategories);
            await m.createTable(categoryRules);
            await _seedDefaultCategories();
          }
        },
      );

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      'Food',
      'Grocery',
      'Travel',
      'Shopping',
      'Bills',
      'Fuel',
      'Healthcare',
      'Entertainment',
      'Education',
      'Hotel',
      'Personal',
      'Other',
    ];

    final now = DateTime.now();
    for (final name in defaults) {
      await into(expenseCategories).insert(
        ExpenseCategoriesCompanion.insert(
          name: name,
          normalizedName: name.toLowerCase(),
          isDefault: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  Future<void> _insertDefaultSyncSettingsRow(SyncPreference preference) {
    return into(syncSettingsTable).insert(
      SyncSettingsTableCompanion.insert(
        id: const Value(0),
        syncPreference: preference,
        connectionState: GoogleConnectionState.disconnected,
        autoSyncEnabled: false,
        lastSyncRunState: SyncRunState.idle,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'upi_expense_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
