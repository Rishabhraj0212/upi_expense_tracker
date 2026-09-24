import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_sync_settings_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/sync/drive_authorization_gateway.dart';
import 'package:upi_expense_tracker/sync/sheets_api_client.dart';
import 'package:upi_expense_tracker/sync/spreadsheet_connection_service.dart';

import 'fake_drive_authorization_gateway.dart';
import 'fake_sheets_api_client.dart';

void main() {
  late AppDatabase db;
  late DriftSyncSettingsRepository settingsRepo;
  late FakeDriveAuthorizationGateway authGateway;
  late FakeSheetsApiClient sheetsApi;
  late SpreadsheetConnectionService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settingsRepo = DriftSyncSettingsRepository(db);
    authGateway = FakeDriveAuthorizationGateway();
    sheetsApi = FakeSheetsApiClient();
    service = SpreadsheetConnectionService(
      driveAuthorizationGateway: authGateway,
      sheetsApiClient: sheetsApi,
      syncSettingsRepository: settingsRepo,
    );
  });

  tearDown(() => db.close());

  group('createNewSheet', () {
    test('success: authorizes without the picker, creates the sheet, and connects', () async {
      authGateway.nextCreateOutcome = const DriveAuthorizationSuccess(accessToken: 'token-123');
      sheetsApi.nextCreateResolution = const SpreadsheetResolved(
        spreadsheetId: 'sheet-1',
        title: 'UPI Expense Tracker',
      );

      final outcome = await service.createNewSheet();

      expect(outcome, isA<SpreadsheetConnectionSuccess>());
      expect(authGateway.createCalls, 1);
      expect(authGateway.pickerCalls, 0, reason: 'creating a new sheet must never show the picker');
      expect(sheetsApi.createCalls, 1);
      expect(sheetsApi.lastAccessTokenUsed, 'token-123');

      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.connected);
      expect(settings.spreadsheetId, 'sheet-1');
      expect(settings.spreadsheetName, 'UPI Expense Tracker');
    });

    test('cancellation: leaves connectionState untouched and creates nothing', () async {
      authGateway.nextCreateOutcome = const DriveAuthorizationCancelled();

      final outcome = await service.createNewSheet();

      expect(outcome, isA<SpreadsheetConnectionCancelled>());
      expect(sheetsApi.createCalls, 0);
      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.disconnected);
      expect(settings.spreadsheetId, isNull);
    });

    test('authorization failure: surfaces the message and leaves connectionState untouched', () async {
      authGateway.nextCreateOutcome = const DriveAuthorizationFailure('network unavailable');

      final outcome = await service.createNewSheet();

      expect(outcome, isA<SpreadsheetConnectionFailure>());
      expect((outcome as SpreadsheetConnectionFailure).message, 'network unavailable');
      expect(sheetsApi.createCalls, 0);
      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.disconnected);
    });

    test('create-call failure (e.g. quota/network) leaves connectionState untouched', () async {
      authGateway.nextCreateOutcome = const DriveAuthorizationSuccess(accessToken: 'token-123');
      sheetsApi.nextCreateResolution = const SpreadsheetUnavailable('Could not create the spreadsheet (HTTP 500).');

      final outcome = await service.createNewSheet();

      expect(outcome, isA<SpreadsheetConnectionFailure>());
      expect((outcome as SpreadsheetConnectionFailure).message, contains('500'));
      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.disconnected);
      expect(settings.spreadsheetId, isNull);
    });
  });

  group('selectExistingSheet', () {
    test('success: authorizes via the picker, verifies the picked id, and connects', () async {
      authGateway.nextPickerOutcome = const DriveAuthorizationSuccess(
        accessToken: 'token-456',
        pickedFileId: 'picked-sheet-id',
      );
      sheetsApi.nextVerifyResolution = const SpreadsheetResolved(
        spreadsheetId: 'picked-sheet-id',
        title: 'My Existing Sheet',
      );

      final outcome = await service.selectExistingSheet();

      expect(outcome, isA<SpreadsheetConnectionSuccess>());
      expect(authGateway.pickerCalls, 1);
      expect(authGateway.createCalls, 0, reason: 'selecting an existing sheet must never use the create-only path');
      expect(sheetsApi.verifyCalls, 1);
      expect(sheetsApi.lastVerifiedSpreadsheetId, 'picked-sheet-id');
      expect(sheetsApi.lastAccessTokenUsed, 'token-456');

      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.connected);
      expect(settings.spreadsheetId, 'picked-sheet-id');
      expect(settings.spreadsheetName, 'My Existing Sheet');
    });

    test('cancellation: leaves connectionState untouched', () async {
      authGateway.nextPickerOutcome = const DriveAuthorizationCancelled();

      final outcome = await service.selectExistingSheet();

      expect(outcome, isA<SpreadsheetConnectionCancelled>());
      expect(sheetsApi.verifyCalls, 0);
      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.disconnected);
    });

    test('authorization failure: surfaces the message and leaves connectionState untouched', () async {
      authGateway.nextPickerOutcome = const DriveAuthorizationFailure('consent denied');

      final outcome = await service.selectExistingSheet();

      expect(outcome, isA<SpreadsheetConnectionFailure>());
      expect((outcome as SpreadsheetConnectionFailure).message, 'consent denied');
      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.disconnected);
    });

    test('authorized but no file was actually picked: fails without calling verify', () async {
      authGateway.nextPickerOutcome = const DriveAuthorizationSuccess(accessToken: 'token-789');

      final outcome = await service.selectExistingSheet();

      expect(outcome, isA<SpreadsheetConnectionFailure>());
      expect((outcome as SpreadsheetConnectionFailure).message, 'No file was selected.');
      expect(sheetsApi.verifyCalls, 0);
    });

    test('invalid/unavailable spreadsheet: verify rejects it and connectionState stays untouched', () async {
      authGateway.nextPickerOutcome = const DriveAuthorizationSuccess(
        accessToken: 'token-999',
        pickedFileId: 'deleted-file-id',
      );
      sheetsApi.nextVerifyResolution = const SpreadsheetUnavailable(
        'That file could not be found. It may have been deleted or moved.',
      );

      final outcome = await service.selectExistingSheet();

      expect(outcome, isA<SpreadsheetConnectionFailure>());
      expect((outcome as SpreadsheetConnectionFailure).message, contains('could not be found'));
      final settings = await settingsRepo.getSettings();
      expect(settings.connectionState, GoogleConnectionState.disconnected);
      expect(settings.spreadsheetId, isNull);
    });
  });
}
