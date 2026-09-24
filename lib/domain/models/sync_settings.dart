import 'sync_status.dart';

/// The single, app-wide row of Google Sheets sync configuration. Global
/// connection/run state lives here; per-transaction outcome lives on each
/// Transaction row instead (see [TransactionSyncStatus]).
class SyncSettings {
  const SyncSettings({
    required this.syncPreference,
    required this.connectionState,
    required this.autoSyncEnabled,
    required this.lastSyncRunState,
    this.googleAccountEmail,
    this.spreadsheetId,
    this.spreadsheetName,
    this.lastSuccessfulSyncAt,
  });

  final SyncPreference syncPreference;
  final GoogleConnectionState connectionState;
  final String? googleAccountEmail;
  final String? spreadsheetId;
  final String? spreadsheetName;

  /// Off by default even immediately after a successful connection — only
  /// turned on by explicit user action in Settings.
  final bool autoSyncEnabled;

  final DateTime? lastSuccessfulSyncAt;
  final SyncRunState lastSyncRunState;

  bool get isConnected => connectionState == GoogleConnectionState.connected;
}
