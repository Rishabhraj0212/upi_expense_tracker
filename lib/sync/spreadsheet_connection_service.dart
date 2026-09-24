import 'package:flutter/foundation.dart';

import '../domain/models/sync_status.dart';
import '../domain/repositories/sync_settings_repository.dart';
import 'drive_authorization_gateway.dart';
import 'sheets_api_client.dart';

sealed class SpreadsheetConnectionOutcome {
  const SpreadsheetConnectionOutcome();
}

class SpreadsheetConnectionSuccess extends SpreadsheetConnectionOutcome {
  const SpreadsheetConnectionSuccess();
}

class SpreadsheetConnectionCancelled extends SpreadsheetConnectionOutcome {
  const SpreadsheetConnectionCancelled();
}

class SpreadsheetConnectionFailure extends SpreadsheetConnectionOutcome {
  const SpreadsheetConnectionFailure(this.message);
  final String message;
}

/// Orchestrates connecting a Google Sheet: authorize `drive.file` access
/// (separately from account sign-in), then either create a brand-new
/// spreadsheet or verify a picked existing one — and only once that
/// resolves successfully does [SyncSettingsRepository.setConnectionState]
/// get called with [GoogleConnectionState.connected]. This is the ONLY place
/// in the app that makes that transition; it never happens as a side effect
/// of [GoogleAuthGateway] sign-in.
///
/// No transaction data is written here — connecting only creates/verifies
/// the destination sheet. Initial sync of existing transactions is a later
/// step.
class SpreadsheetConnectionService {
  SpreadsheetConnectionService({
    required this.driveAuthorizationGateway,
    required this.sheetsApiClient,
    required this.syncSettingsRepository,
  });

  final DriveAuthorizationGateway driveAuthorizationGateway;
  final SheetsApiClient sheetsApiClient;
  final SyncSettingsRepository syncSettingsRepository;

  Future<SpreadsheetConnectionOutcome> createNewSheet({String title = 'UPI Expense Tracker'}) async {
    debugPrint('[SheetSync] createNewSheet: entry');
    final auth = await driveAuthorizationGateway.authorizeForCreate();
    debugPrint('[SheetSync] createNewSheet: authorization outcome=${auth.runtimeType}');
    final outcome = switch (auth) {
      DriveAuthorizationCancelled() => const SpreadsheetConnectionCancelled(),
      DriveAuthorizationFailure(:final message) => SpreadsheetConnectionFailure(message),
      DriveAuthorizationSuccess(:final accessToken) => await _resolveAndConnect(
        () => sheetsApiClient.createSpreadsheet(accessToken, title),
      ),
    };
    debugPrint('[SheetSync] createNewSheet: final outcome=${outcome.runtimeType}');
    return outcome;
  }

  Future<SpreadsheetConnectionOutcome> selectExistingSheet() async {
    debugPrint('[SheetSync] selectExistingSheet: entry');
    final auth = await driveAuthorizationGateway.authorizeForPicker();
    debugPrint('[SheetSync] selectExistingSheet: authorization outcome=${auth.runtimeType}');
    final outcome = switch (auth) {
      DriveAuthorizationCancelled() => const SpreadsheetConnectionCancelled(),
      DriveAuthorizationFailure(:final message) => SpreadsheetConnectionFailure(message),
      DriveAuthorizationSuccess(pickedFileId: null) => const SpreadsheetConnectionFailure('No file was selected.'),
      DriveAuthorizationSuccess(accessToken: final accessToken, pickedFileId: final pickedFileId?) =>
        await _resolveAndConnect(() => sheetsApiClient.verifySpreadsheet(accessToken, pickedFileId)),
    };
    debugPrint('[SheetSync] selectExistingSheet: final outcome=${outcome.runtimeType}');
    return outcome;
  }

  Future<SpreadsheetConnectionOutcome> _resolveAndConnect(
    Future<SpreadsheetResolution> Function() resolve,
  ) async {
    final resolution = await resolve();
    debugPrint('[SheetSync] _resolveAndConnect: sheets API resolution=${resolution.runtimeType}');
    return switch (resolution) {
      SpreadsheetUnavailable(:final reason) => SpreadsheetConnectionFailure(reason),
      SpreadsheetResolved(:final spreadsheetId, :final title) => await _connect(spreadsheetId, title),
    };
  }

  Future<SpreadsheetConnectionOutcome> _connect(String spreadsheetId, String title) async {
    await syncSettingsRepository.setSpreadsheet(spreadsheetId, title);
    await syncSettingsRepository.setConnectionState(GoogleConnectionState.connected);
    debugPrint('[SheetSync] _connect: connectionState set to connected, spreadsheetId set');
    return const SpreadsheetConnectionSuccess();
  }
}
