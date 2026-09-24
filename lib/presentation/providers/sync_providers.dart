import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/drift_sync_settings_repository.dart';
import '../../domain/models/sync_settings.dart';
import '../../domain/repositories/sync_settings_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../sync/auto_sync_controller.dart';
import '../../sync/drive_authorization_gateway.dart';
import '../../sync/drive_authorization_native_gateway.dart';
import '../../sync/google_auth_gateway.dart';
import '../../sync/google_sign_in_auth_gateway.dart';
import '../../sync/http_sheets_api_client.dart';
import '../../sync/sheets_api_client.dart';
import '../../sync/spreadsheet_connection_service.dart';
import '../../sync/transaction_sync_service.dart';
import 'app_providers.dart';

final syncSettingsRepositoryProvider = Provider<SyncSettingsRepository>((ref) {
  return DriftSyncSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Reactive: emits whenever the single sync-settings row changes — the
/// first-launch choice being made, and later (once the sync layer exists)
/// connection/run-state changes too.
final syncSettingsStreamProvider = StreamProvider<SyncSettings>((ref) {
  return ref.watch(syncSettingsRepositoryProvider).watchSettings();
});

/// Recomputed whenever the transaction list changes, so Settings/dashboard
/// sync counts stay live without any manual refresh.
final transactionSyncCountsProvider = FutureProvider.autoDispose<TransactionSyncCounts>((ref) {
  ref.watch(transactionsStreamProvider);
  return ref.watch(transactionRepositoryProvider).getSyncCounts();
});

final googleAuthGatewayProvider = Provider<GoogleAuthGateway>((ref) => GoogleSignInAuthGateway());

/// Checked once when the setup screen loads, to support re-authentication:
/// a returning user who already granted access shouldn't be asked to sign
/// in again just because they revisited this screen.
final currentGoogleAccountEmailProvider = FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(googleAuthGatewayProvider).currentAccountEmail();
});

final driveAuthorizationGatewayProvider = Provider<DriveAuthorizationGateway>(
  (ref) => DriveAuthorizationNativeGateway(),
);

final sheetsApiClientProvider = Provider<SheetsApiClient>((ref) => HttpSheetsApiClient());

final spreadsheetConnectionServiceProvider = Provider<SpreadsheetConnectionService>((ref) {
  return SpreadsheetConnectionService(
    driveAuthorizationGateway: ref.watch(driveAuthorizationGatewayProvider),
    sheetsApiClient: ref.watch(sheetsApiClientProvider),
    syncSettingsRepository: ref.watch(syncSettingsRepositoryProvider),
  );
});

final transactionSyncServiceProvider = Provider<TransactionSyncService>((ref) {
  return TransactionSyncService(
    driveAuthorizationGateway: ref.watch(driveAuthorizationGatewayProvider),
    sheetsApiClient: ref.watch(sheetsApiClientProvider),
    syncSettingsRepository: ref.watch(syncSettingsRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

/// Watches the transaction repository stream and sync settings stream,
/// fires a debounced, non-blocking sync whenever auto-sync is enabled and
/// a Google Sheet is connected. Must be read once at startup (in main.dart).
final autoSyncControllerProvider = Provider<AutoSyncController>((ref) {
  // Use the underlying repository streams directly to avoid the deprecated
  // StreamProvider.stream API (.stream is removed in Riverpod 3.0).
  final controller = AutoSyncController(
    transactionStream: ref.watch(transactionRepositoryProvider).watchAll(),
    settingsStream: ref.watch(syncSettingsRepositoryProvider).watchSettings(),
    syncService: ref.watch(transactionSyncServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
