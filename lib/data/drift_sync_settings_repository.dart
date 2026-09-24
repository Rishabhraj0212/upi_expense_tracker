import 'package:drift/drift.dart';

import '../domain/models/sync_settings.dart' as domain;
import '../domain/models/sync_status.dart';
import '../domain/repositories/sync_settings_repository.dart';
import 'local/app_database.dart';

/// The settings row always has id 0 — this is a single-row table by
/// convention (see SyncSettingsTable's doc comment).
const _rowId = 0;

class DriftSyncSettingsRepository implements SyncSettingsRepository {
  DriftSyncSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<domain.SyncSettings> getSettings() async {
    final row = await (_db.select(_db.syncSettingsTable)..where((t) => t.id.equals(_rowId))).getSingle();
    return _toDomain(row);
  }

  @override
  Stream<domain.SyncSettings> watchSettings() {
    return (_db.select(_db.syncSettingsTable)..where((t) => t.id.equals(_rowId)))
        .watchSingle()
        .map(_toDomain);
  }

  @override
  Future<void> setSyncPreference(SyncPreference preference) => _write(
        SyncSettingsTableCompanion(syncPreference: Value(preference)),
      );

  @override
  Future<void> setConnectionState(GoogleConnectionState state) => _write(
        SyncSettingsTableCompanion(connectionState: Value(state)),
      );

  @override
  Future<void> setGoogleAccount(String? email) => _write(
        SyncSettingsTableCompanion(googleAccountEmail: Value(email)),
      );

  @override
  Future<void> setSpreadsheet(String? id, String? name) => _write(
        SyncSettingsTableCompanion(spreadsheetId: Value(id), spreadsheetName: Value(name)),
      );

  @override
  Future<void> setAutoSyncEnabled(bool enabled) => _write(
        SyncSettingsTableCompanion(autoSyncEnabled: Value(enabled)),
      );

  @override
  Future<void> setLastSuccessfulSync(DateTime at) => _write(
        SyncSettingsTableCompanion(lastSuccessfulSyncAt: Value(at)),
      );

  @override
  Future<void> setSyncRunState(SyncRunState state) => _write(
        SyncSettingsTableCompanion(lastSyncRunState: Value(state)),
      );

  Future<void> _write(SyncSettingsTableCompanion companion) async {
    await (_db.update(_db.syncSettingsTable)..where((t) => t.id.equals(_rowId))).write(companion);
  }

  domain.SyncSettings _toDomain(SyncSettingsRow row) => domain.SyncSettings(
        syncPreference: row.syncPreference,
        connectionState: row.connectionState,
        googleAccountEmail: row.googleAccountEmail,
        spreadsheetId: row.spreadsheetId,
        spreadsheetName: row.spreadsheetName,
        autoSyncEnabled: row.autoSyncEnabled,
        lastSuccessfulSyncAt: row.lastSuccessfulSyncAt,
        lastSyncRunState: row.lastSyncRunState,
      );
}
