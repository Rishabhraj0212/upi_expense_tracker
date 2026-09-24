import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_sync_settings_repository.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/presentation/providers/sync_providers.dart';
import 'package:upi_expense_tracker/presentation/screens/google_sheets_setup_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/settings_screen.dart';
import 'package:upi_expense_tracker/sync/drive_authorization_gateway.dart';

import '../sync/fake_drive_authorization_gateway.dart';
import '../sync/fake_google_auth_gateway.dart';
import '../sync/fake_sheets_api_client.dart';
import 'test_harness.dart';

void main() {
  testWidgets('LOCAL_ONLY shows sync-off status and a Connect button', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await DriftSyncSettingsRepository(db).setSyncPreference(SyncPreference.localOnly);

    await pumpDriftScreen(tester, db, const SettingsScreen());

    expect(find.text('Sync is Off'), findsOneWidget);
    expect(find.text('Your expenses are stored only on this device.'), findsOneWidget);
    expect(find.text('Connect Google Sheets'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('tapping Connect Google Sheets records intent and opens the setup flow', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.localOnly);

    await pumpDriftScreen(
      tester,
      db,
      const SettingsScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway())],
    );

    await tester.tap(find.text('Connect Google Sheets'));
    await tester.pumpAndSettle();

    expect(find.byType(GoogleSheetsSetupScreen), findsOneWidget);
    expect((await settingsRepo.getSettings()).syncPreference, SyncPreference.googleSheets);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('GOOGLE_SHEETS not yet connected shows "Continue Setup" instead of "Connect"', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await DriftSyncSettingsRepository(db).setSyncPreference(SyncPreference.googleSheets);

    await pumpDriftScreen(tester, db, const SettingsScreen());

    expect(find.text('Continue Setup'), findsOneWidget);
    expect(find.text('Connect Google Sheets'), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('connected with everything synced shows account, sheet, and zero pending/failed', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);
    await settingsRepo.setGoogleAccount('user@example.com');
    await settingsRepo.setSpreadsheet('sheet-1', 'UPI Expense Tracker');
    await settingsRepo.setSyncRunState(SyncRunState.synced);
    await settingsRepo.setLastSuccessfulSync(DateTime(2026, 9, 23, 12, 42));

    final txRepo = DriftTransactionRepository(db);
    final id = await txRepo.insert(ParsedTransaction(
      amountPaise: 1000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 1),
      sourceType: SourceType.sms,
      rawText: 'x',
    ));
    await txRepo.markSynced(id, syncedAt: DateTime(2026, 9, 23));

    await pumpDriftScreen(tester, db, const SettingsScreen());

    expect(find.text('All data synced'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('UPI Expense Tracker'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // Synced count
    expect(find.text('0'), findsWidgets); // Pending and Failed counts
    expect(find.text('Disconnect Google Account'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('connected with pending/failed transactions shows an incomplete-sync status and a Retry action', (
    tester,
  ) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);
    await settingsRepo.setSyncRunState(SyncRunState.partiallySynced);

    final txRepo = DriftTransactionRepository(db);
    final failedId = await txRepo.insert(ParsedTransaction(
      amountPaise: 1000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 1),
      sourceType: SourceType.sms,
      rawText: 'x',
    ));
    await txRepo.markSyncFailed(failedId, 'network error');
    await txRepo.insert(ParsedTransaction(
      amountPaise: 2000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 2),
      sourceType: SourceType.sms,
      rawText: 'y',
    ));

    await pumpDriftScreen(tester, db, const SettingsScreen());

    expect(find.text('Some transactions are not synced'), findsOneWidget);
    expect(find.text('Retry Sync'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('toggling Auto Sync writes through to settings, and stays off until explicitly toggled', (
    tester,
  ) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);

    expect((await settingsRepo.getSettings()).autoSyncEnabled, isFalse);

    await pumpDriftScreen(tester, db, const SettingsScreen());

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect((await settingsRepo.getSettings()).autoSyncEnabled, isTrue);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('disconnect asks for confirmation, then clears Google state but keeps local data', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);
    await settingsRepo.setGoogleAccount('user@example.com');
    await settingsRepo.setSpreadsheet('sheet-1', 'UPI Expense Tracker');

    final txRepo = DriftTransactionRepository(db);
    final id = await txRepo.insert(ParsedTransaction(
      amountPaise: 1000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 1),
      sourceType: SourceType.sms,
      rawText: 'x',
    ));
    await txRepo.markSynced(id, syncedAt: DateTime(2026, 1, 1));
    final gateway = FakeGoogleAuthGateway()..existingSessionEmail = 'user@example.com';

    await pumpDriftScreen(
      tester,
      db,
      const SettingsScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(gateway)],
    );

    await tester.tap(find.text('Disconnect Google Account'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Google Sheets?'), findsOneWidget);

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(gateway.signOutCalls, 1, reason: 'the real Google session must actually be revoked, not just local state cleared');

    final settings = await settingsRepo.getSettings();
    expect(settings.syncPreference, SyncPreference.localOnly);
    expect(settings.connectionState, GoogleConnectionState.disconnected);
    expect(settings.googleAccountEmail, isNull);
    expect(settings.spreadsheetId, isNull);

    // Local data must survive disconnect untouched.
    final tx = await txRepo.getById(id);
    expect(tx, isNotNull);
    expect(tx!.amountPaise, 1000);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('canceling disconnect keeps the Google connection intact', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);
    await settingsRepo.setGoogleAccount('user@example.com');

    await pumpDriftScreen(tester, db, const SettingsScreen());

    await tester.tap(find.text('Disconnect Google Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final settings = await settingsRepo.getSettings();
    expect(settings.connectionState, GoogleConnectionState.connected);
    expect(settings.googleAccountEmail, 'user@example.com');

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('tapping Sync Now runs a real sync and the panel reflects the result', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);
    await settingsRepo.setSpreadsheet('sheet-1', 'UPI Expense Tracker');

    final txRepo = DriftTransactionRepository(db);
    final id = await txRepo.insert(ParsedTransaction(
      amountPaise: 1000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 1),
      sourceType: SourceType.sms,
      rawText: 'x',
    ));

    final driveGateway = FakeDriveAuthorizationGateway()
      ..nextCreateOutcome = const DriveAuthorizationSuccess(accessToken: 'token-1');
    final sheetsApi = FakeSheetsApiClient();

    await pumpDriftScreen(
      tester,
      db,
      const SettingsScreen(),
      extraOverrides: [
        driveAuthorizationGatewayProvider.overrideWithValue(driveGateway),
        sheetsApiClientProvider.overrideWithValue(sheetsApi),
      ],
    );

    expect(find.text('Not yet synced'), findsOneWidget);

    await tester.tap(find.text('Sync Now'));
    await tester.pumpAndSettle();

    expect(find.text('All data synced'), findsOneWidget);
    expect(sheetsApi.rowValuesForTransactionId(id.toString()), isNotNull);

    final tx = await txRepo.getById(id);
    expect(tx!.syncStatus, TransactionSyncStatus.synced);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('a failed sync shows an error dialog without claiming success', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    await settingsRepo.setConnectionState(GoogleConnectionState.connected);
    await settingsRepo.setSpreadsheet('sheet-1', 'UPI Expense Tracker');

    final txRepo = DriftTransactionRepository(db);
    await txRepo.insert(ParsedTransaction(
      amountPaise: 1000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 1),
      sourceType: SourceType.sms,
      rawText: 'x',
    ));

    final driveGateway = FakeDriveAuthorizationGateway()
      ..nextCreateOutcome = const DriveAuthorizationFailure('network unavailable');

    await pumpDriftScreen(
      tester,
      db,
      const SettingsScreen(),
      extraOverrides: [driveAuthorizationGatewayProvider.overrideWithValue(driveGateway)],
    );

    await tester.tap(find.text('Sync Now'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, 'Sync failed'), findsOneWidget);
    expect(find.textContaining('network unavailable'), findsOneWidget);

    final settings = await settingsRepo.getSettings();
    expect(settings.lastSyncRunState, SyncRunState.syncFailed);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await disposeAndFlushDriftTimer(tester);
  });
}
