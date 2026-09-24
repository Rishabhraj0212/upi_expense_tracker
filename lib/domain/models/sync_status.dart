/// Per-transaction sync outcome, stored directly on the Transactions row.
enum TransactionSyncStatus {
  pending,
  synced,
  failed;

  static TransactionSyncStatus fromName(String name) =>
      TransactionSyncStatus.values.firstWhere((s) => s.name == name);
}

/// The user's top-level choice, made once at first launch (or later from
/// Settings) and persisted in SyncSettings.
enum SyncPreference {
  notConfigured,
  localOnly,
  googleSheets;

  static SyncPreference fromName(String name) => SyncPreference.values.firstWhere((s) => s.name == name);
}

/// Whether a Google account is authenticated and a spreadsheet is selected —
/// says nothing about whether any transaction has actually been written.
/// Deliberately a separate axis from [SyncRunState].
enum GoogleConnectionState {
  disconnected,
  connecting,
  connected,
  connectionFailed;

  static GoogleConnectionState fromName(String name) =>
      GoogleConnectionState.values.firstWhere((s) => s.name == name);
}

/// The outcome of the most recent (or in-progress) sync attempt. Separate
/// from [GoogleConnectionState]: a fully connected account can still have a
/// failed or partial sync run.
enum SyncRunState {
  idle,
  syncing,
  synced,
  partiallySynced,
  syncFailed;

  static SyncRunState fromName(String name) => SyncRunState.values.firstWhere((s) => s.name == name);
}
