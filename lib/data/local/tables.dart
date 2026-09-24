import 'package:drift/drift.dart';

import '../../domain/models/sync_status.dart';
import '../../domain/models/transaction_source.dart';
import '../../domain/models/transaction_type.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get amountPaise => integer()();
  TextColumn get type => textEnum<TransactionType>()();

  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get receivedAt => dateTime()();

  TextColumn get merchantName => text().nullable()();
  TextColumn get upiId => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get accountHint => text().nullable()();
  TextColumn get referenceId => text().nullable()();

  /// Comma-separated SourceType names, e.g. "sms,notification".
  TextColumn get mergedSources => text()();
  TextColumn get sourceApp => text().nullable()();
  TextColumn get sourceAddress => text().nullable()();

  TextColumn get rawText => text()();

  TextColumn get category => text().nullable()();
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // --- Phase 2: Google Sheets sync state (schemaVersion 2) ---------------
  // id remains the identity written into the sheet; remoteRowRef below is
  // only a locate-faster hint, never trusted as identity.
  TextColumn get syncStatus => textEnum<TransactionSyncStatus>()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get remoteRowRef => text().nullable()();
  TextColumn get lastSyncError => text().nullable()();

  @override
  List<Set<Column>>? get uniqueKeys => [];
}

@DataClassName('CaptureRow')
class RawCaptures extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get at => dateTime()();
  TextColumn get sourceType => textEnum<SourceType>()();
  TextColumn get origin => text().nullable()();
  TextColumn get text_ => text().named('text')();
  TextColumn get result => text()();
}

/// Single-row table (always id = 0) holding app-wide Google Sheets sync
/// configuration. Named `SyncSettingsTable` (not `SyncSettings`) so its
/// generated row class doesn't collide with the domain `SyncSettings` model
/// — same convention as Transactions/TransactionRow vs domain Transaction.
@DataClassName('SyncSettingsRow')
class SyncSettingsTable extends Table {
  @override
  String get tableName => 'sync_settings';

  IntColumn get id => integer()();

  TextColumn get syncPreference => textEnum<SyncPreference>()();
  TextColumn get connectionState => textEnum<GoogleConnectionState>()();
  TextColumn get googleAccountEmail => text().nullable()();
  TextColumn get spreadsheetId => text().nullable()();
  TextColumn get spreadsheetName => text().nullable()();
  BoolColumn get autoSyncEnabled => boolean()();
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
  TextColumn get lastSyncRunState => textEnum<SyncRunState>()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseCategoryRow')
class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>>? get uniqueKeys => [
        {normalizedName}
      ];
}

@DataClassName('CategoryRuleRow')
class CategoryRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get merchantKey => text()();
  TextColumn get category => text()();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>>? get uniqueKeys => [
        {merchantKey}
      ];
}
