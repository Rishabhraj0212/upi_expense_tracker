import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/sync_settings.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';

void main() {
  test('isConnected reflects connectionState only, independent of sync run state', () {
    const connected = SyncSettings(
      syncPreference: SyncPreference.googleSheets,
      connectionState: GoogleConnectionState.connected,
      autoSyncEnabled: false,
      lastSyncRunState: SyncRunState.syncFailed,
    );
    const notConnected = SyncSettings(
      syncPreference: SyncPreference.googleSheets,
      connectionState: GoogleConnectionState.connecting,
      autoSyncEnabled: false,
      lastSyncRunState: SyncRunState.synced,
    );

    expect(connected.isConnected, isTrue, reason: 'connected but sync failed is still "connected"');
    expect(notConnected.isConnected, isFalse, reason: 'a synced-looking run state does not imply connection');
  });

  test('enum fromName round-trips every value by name', () {
    for (final v in TransactionSyncStatus.values) {
      expect(TransactionSyncStatus.fromName(v.name), v);
    }
    for (final v in SyncPreference.values) {
      expect(SyncPreference.fromName(v.name), v);
    }
    for (final v in GoogleConnectionState.values) {
      expect(GoogleConnectionState.fromName(v.name), v);
    }
    for (final v in SyncRunState.values) {
      expect(SyncRunState.fromName(v.name), v);
    }
  });
}
