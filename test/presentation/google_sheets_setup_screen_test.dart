import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_sync_settings_repository.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/presentation/providers/sync_providers.dart';
import 'package:upi_expense_tracker/presentation/screens/google_sheets_setup_screen.dart';
import 'package:upi_expense_tracker/sync/drive_authorization_gateway.dart';
import 'package:upi_expense_tracker/sync/google_auth_gateway.dart';
import 'package:upi_expense_tracker/sync/sheets_api_client.dart';

import '../sync/fake_drive_authorization_gateway.dart';
import '../sync/fake_google_auth_gateway.dart';
import '../sync/fake_sheets_api_client.dart';
import 'test_harness.dart';

void main() {
  testWidgets('shows all four setup steps; only step 1 is active before signing in', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway())],
    );

    expect(find.text('Connect Google Account'), findsWidgets);
    expect(find.text('Create or Select Sheet'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Initial Sync'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('successful sign-in records the account and never sets connectionState = connected', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setSyncPreference(SyncPreference.googleSheets);
    final gateway = FakeGoogleAuthGateway()..nextSignInOutcome = const GoogleSignInSuccess('user@example.com');

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(gateway)],
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Connect Google Account'));
    await tester.pumpAndSettle();

    expect(gateway.signInCalls, 1);
    expect(find.text('Connected as user@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    final settings = await settingsRepo.getSettings();
    expect(settings.googleAccountEmail, 'user@example.com');
    expect(
      settings.connectionState,
      GoogleConnectionState.disconnected,
      reason: 'signing in must never by itself imply a spreadsheet connection',
    );

    // Step 2 becomes visually active once signed in.
    expect(find.text('Create New Sheet'), findsOneWidget);
    expect(find.text('Select Existing Sheet'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('a cancelled sign-in shows no error and records nothing', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    final gateway = FakeGoogleAuthGateway()..nextSignInOutcome = const GoogleSignInCancelled();

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(gateway)],
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Connect Google Account'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t sign in'), findsNothing, reason: 'a deliberate cancel is not an error');
    expect(find.text('Connect Google Account'), findsWidgets, reason: 'still showing the connect action, not signed in');

    final settings = await settingsRepo.getSettings();
    expect(settings.googleAccountEmail, isNull);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('a failed sign-in shows a clear, user-friendly error and records nothing', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    final gateway = FakeGoogleAuthGateway()..nextSignInOutcome = const GoogleSignInFailure('clientConfigurationError');

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(gateway)],
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Connect Google Account'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t sign in'), findsOneWidget);
    expect(find.textContaining('clientConfigurationError'), findsOneWidget);

    final settings = await settingsRepo.getSettings();
    expect(settings.googleAccountEmail, isNull);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('re-authentication: an existing Google session is adopted silently, with no picker shown', (
    tester,
  ) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    final gateway = FakeGoogleAuthGateway()..existingSessionEmail = 'returning@example.com';

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(gateway)],
    );

    expect(find.text('Connected as returning@example.com'), findsOneWidget);
    expect(gateway.signInCalls, 0, reason: 'must not prompt the interactive picker for a restorable session');

    final settings = await settingsRepo.getSettings();
    expect(settings.googleAccountEmail, 'returning@example.com');

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('re-authentication does not override an already-recorded account', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setGoogleAccount('already-recorded@example.com');
    final gateway = FakeGoogleAuthGateway()..existingSessionEmail = 'different@example.com';

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(gateway)],
    );

    expect(find.text('Connected as already-recorded@example.com'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('signing out clears the recorded account and reverts to the connect action', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setGoogleAccount('user@example.com');
    final gateway = FakeGoogleAuthGateway()..existingSessionEmail = 'user@example.com';

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(gateway)],
    );
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(gateway.signOutCalls, 1);
    expect(find.text('Connect Google Account'), findsWidgets);

    final settings = await settingsRepo.getSettings();
    expect(settings.googleAccountEmail, isNull);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('"Skip for now" sets the preference back to LOCAL_ONLY', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftSyncSettingsRepository(db);
    await repo.setSyncPreference(SyncPreference.googleSheets);

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway())],
    );

    await tester.tap(find.text('Skip for now — keep my data local'));
    await tester.pumpAndSettle();

    final settings = await repo.getSettings();
    expect(settings.syncPreference, SyncPreference.localOnly);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('creating a new sheet connects and pops back, without ever showing the picker', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setGoogleAccount('user@example.com');
    final driveGateway = FakeDriveAuthorizationGateway()
      ..nextCreateOutcome = const DriveAuthorizationSuccess(accessToken: 'token-1');
    final sheetsApi = FakeSheetsApiClient()
      ..nextCreateResolution = const SpreadsheetResolved(spreadsheetId: 'sheet-1', title: 'UPI Expense Tracker');

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [
        googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway()),
        driveAuthorizationGatewayProvider.overrideWithValue(driveGateway),
        sheetsApiClientProvider.overrideWithValue(sheetsApi),
      ],
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create New Sheet'));
    await tester.pumpAndSettle();

    expect(driveGateway.createCalls, 1);
    expect(driveGateway.pickerCalls, 0);
    final settings = await settingsRepo.getSettings();
    expect(settings.connectionState, GoogleConnectionState.connected);
    expect(settings.spreadsheetId, 'sheet-1');
    expect(settings.spreadsheetName, 'UPI Expense Tracker');

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('selecting an existing sheet via the picker connects using the picked id', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setGoogleAccount('user@example.com');
    final driveGateway = FakeDriveAuthorizationGateway()
      ..nextPickerOutcome = const DriveAuthorizationSuccess(accessToken: 'token-2', pickedFileId: 'picked-id');
    final sheetsApi = FakeSheetsApiClient()
      ..nextVerifyResolution = const SpreadsheetResolved(spreadsheetId: 'picked-id', title: 'My Old Sheet');

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [
        googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway()),
        driveAuthorizationGatewayProvider.overrideWithValue(driveGateway),
        sheetsApiClientProvider.overrideWithValue(sheetsApi),
      ],
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Select Existing Sheet'));
    await tester.pumpAndSettle();

    expect(driveGateway.pickerCalls, 1);
    expect(sheetsApi.lastVerifiedSpreadsheetId, 'picked-id');
    final settings = await settingsRepo.getSettings();
    expect(settings.connectionState, GoogleConnectionState.connected);
    expect(settings.spreadsheetId, 'picked-id');
    expect(settings.spreadsheetName, 'My Old Sheet');

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('cancelling sheet authorization shows no error and stays disconnected', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setGoogleAccount('user@example.com');
    final driveGateway = FakeDriveAuthorizationGateway()..nextCreateOutcome = const DriveAuthorizationCancelled();

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [
        googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway()),
        driveAuthorizationGatewayProvider.overrideWithValue(driveGateway),
      ],
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create New Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t connect the sheet'), findsNothing);
    final settings = await settingsRepo.getSettings();
    expect(settings.connectionState, GoogleConnectionState.disconnected);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('an invalid/unavailable selected spreadsheet shows an error and stays disconnected', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setGoogleAccount('user@example.com');
    final driveGateway = FakeDriveAuthorizationGateway()
      ..nextPickerOutcome = const DriveAuthorizationSuccess(accessToken: 'token-3', pickedFileId: 'gone-id');
    final sheetsApi = FakeSheetsApiClient()
      ..nextVerifyResolution = const SpreadsheetUnavailable(
        'That file could not be found. It may have been deleted or moved.',
      );

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [
        googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway()),
        driveAuthorizationGatewayProvider.overrideWithValue(driveGateway),
        sheetsApiClientProvider.overrideWithValue(sheetsApi),
      ],
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Select Existing Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t connect the sheet'), findsOneWidget);
    expect(find.textContaining('could not be found'), findsOneWidget);
    final settings = await settingsRepo.getSettings();
    expect(settings.connectionState, GoogleConnectionState.disconnected);
    expect(settings.spreadsheetId, isNull);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('sheet authorization failure shows a clear error and stays disconnected', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final settingsRepo = DriftSyncSettingsRepository(db);
    await settingsRepo.setGoogleAccount('user@example.com');
    final driveGateway = FakeDriveAuthorizationGateway()
      ..nextCreateOutcome = const DriveAuthorizationFailure('network unavailable');

    await pumpDriftScreen(
      tester,
      db,
      const GoogleSheetsSetupScreen(),
      extraOverrides: [
        googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway()),
        driveAuthorizationGatewayProvider.overrideWithValue(driveGateway),
      ],
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create New Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t connect the sheet'), findsOneWidget);
    expect(find.textContaining('network unavailable'), findsOneWidget);
    final settings = await settingsRepo.getSettings();
    expect(settings.connectionState, GoogleConnectionState.disconnected);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await disposeAndFlushDriftTimer(tester);
  });
}
