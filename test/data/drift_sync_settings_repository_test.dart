import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_sync_settings_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';

void main() {
  late AppDatabase db;
  late DriftSyncSettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftSyncSettingsRepository(db);
  });

  tearDown(() => db.close());

  test('a fresh database starts NOT_CONFIGURED, disconnected, auto-sync off', () async {
    final settings = await repo.getSettings();

    expect(settings.syncPreference, SyncPreference.notConfigured);
    expect(settings.connectionState, GoogleConnectionState.disconnected);
    expect(settings.autoSyncEnabled, isFalse);
    expect(settings.lastSyncRunState, SyncRunState.idle);
    expect(settings.googleAccountEmail, isNull);
    expect(settings.spreadsheetId, isNull);
    expect(settings.spreadsheetName, isNull);
    expect(settings.lastSuccessfulSyncAt, isNull);
  });

  test('setSyncPreference updates only that field', () async {
    await repo.setSyncPreference(SyncPreference.localOnly);

    final settings = await repo.getSettings();
    expect(settings.syncPreference, SyncPreference.localOnly);
    expect(settings.connectionState, GoogleConnectionState.disconnected, reason: 'unrelated fields stay put');
  });

  test('setConnectionState is independent of setSyncRunState (the two-axis requirement)', () async {
    await repo.setConnectionState(GoogleConnectionState.connected);

    final connectedButIdle = await repo.getSettings();
    expect(connectedButIdle.connectionState, GoogleConnectionState.connected);
    expect(
      connectedButIdle.lastSyncRunState,
      SyncRunState.idle,
      reason: 'being connected must not itself imply anything got synced',
    );

    await repo.setSyncRunState(SyncRunState.syncFailed);

    final stillConnected = await repo.getSettings();
    expect(stillConnected.connectionState, GoogleConnectionState.connected, reason: 'a failed sync run does not disconnect the account');
    expect(stillConnected.lastSyncRunState, SyncRunState.syncFailed);
  });

  test('setGoogleAccount stores and clears the account email', () async {
    await repo.setGoogleAccount('user@example.com');
    expect((await repo.getSettings()).googleAccountEmail, 'user@example.com');

    await repo.setGoogleAccount(null);
    expect((await repo.getSettings()).googleAccountEmail, isNull);
  });

  test('setSpreadsheet stores and clears id and name together', () async {
    await repo.setSpreadsheet('sheet-123', 'UPI Expense Tracker');

    final settings = await repo.getSettings();
    expect(settings.spreadsheetId, 'sheet-123');
    expect(settings.spreadsheetName, 'UPI Expense Tracker');

    await repo.setSpreadsheet(null, null);
    final cleared = await repo.getSettings();
    expect(cleared.spreadsheetId, isNull);
    expect(cleared.spreadsheetName, isNull);
  });

  test('setAutoSyncEnabled defaults to false and only changes on explicit call', () async {
    expect((await repo.getSettings()).autoSyncEnabled, isFalse);

    await repo.setAutoSyncEnabled(true);
    expect((await repo.getSettings()).autoSyncEnabled, isTrue);
  });

  test('setLastSuccessfulSync records the timestamp', () async {
    final at = DateTime(2026, 9, 23, 12, 42);
    await repo.setLastSuccessfulSync(at);

    expect((await repo.getSettings()).lastSuccessfulSyncAt, at);
  });

  test('watchSettings emits an updated value after a write', () async {
    final emissions = <SyncPreference>[];
    final sub = repo.watchSettings().listen((s) => emissions.add(s.syncPreference));

    await Future<void>.delayed(Duration.zero);
    await repo.setSyncPreference(SyncPreference.googleSheets);
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(emissions, [SyncPreference.notConfigured, SyncPreference.googleSheets]);
  });
}
