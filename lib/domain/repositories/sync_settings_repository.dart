import '../models/sync_settings.dart';
import '../models/sync_status.dart';

/// Persistence for the single app-wide [SyncSettings] row. Pure data access —
/// no Google/network calls happen behind this interface; those belong to the
/// (not-yet-built) sync layer that will call through here.
abstract class SyncSettingsRepository {
  Future<SyncSettings> getSettings();

  /// Reactive: emits whenever the settings row changes.
  Stream<SyncSettings> watchSettings();

  Future<void> setSyncPreference(SyncPreference preference);

  Future<void> setConnectionState(GoogleConnectionState state);

  /// Pass null to clear (e.g. on disconnect).
  Future<void> setGoogleAccount(String? email);

  /// Pass null for both to clear (e.g. on disconnect).
  Future<void> setSpreadsheet(String? id, String? name);

  Future<void> setAutoSyncEnabled(bool enabled);

  Future<void> setLastSuccessfulSync(DateTime at);

  Future<void> setSyncRunState(SyncRunState state);

  Future<void> setLastSmsRescanAt(DateTime at);
}
