import 'package:flutter/foundation.dart';

import '../domain/models/sync_status.dart';
import '../domain/models/transaction.dart';
import '../domain/repositories/sync_settings_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import 'drive_authorization_gateway.dart';
import 'sheets_api_client.dart';

/// The sheet's column layout, in order. Row 1. Kept in one place since both
/// the header write and every data row must agree on it.
const List<String> transactionSheetHeaders = [
  'Transaction ID',
  'Date',
  'Type',
  'Amount (INR)',
  'Merchant / UPI ID',
  'Bank',
  'Reference ID',
  'Category',
  'Note',
  'Source',
];

class SyncProgress {
  const SyncProgress({required this.completed, required this.total});
  final int completed;
  final int total;
}

/// Result of one full sync attempt. [SyncRunCompleted] covers both "fully
/// synced" and "partially synced" — [SyncRunCompleted.isFullySynced]
/// distinguishes them; [SyncRunAborted] is for failures before any
/// individual transaction could even be attempted (no spreadsheet
/// connected, authorization itself failed, or the sheet couldn't be read).
sealed class SyncRunOutcome {
  const SyncRunOutcome();
}

class SyncRunCompleted extends SyncRunOutcome {
  const SyncRunCompleted({required this.succeeded, required this.failed});
  final int succeeded;
  final int failed;

  bool get isFullySynced => failed == 0;
}

class SyncRunAborted extends SyncRunOutcome {
  const SyncRunAborted(this.reason);
  final String reason;
}

/// Syncs locally PENDING/FAILED transactions to the connected Google Sheet.
///
/// [Transaction.id] is the only trusted identity for matching a local
/// transaction to a sheet row — a fresh [SheetsApiClient.fetchTransactionRowIndex]
/// read is taken at the start of every run and used to decide update-in-place
/// vs. append, rather than trusting [Transaction.remoteRowRef] (which is only
/// ever a locate-faster hint). This is what keeps re-running a sync
/// (including a full retry after a partial failure) duplicate-safe even if
/// local sync state and the sheet's actual contents have drifted apart.
///
/// A transaction's local fields (amount, category, etc.) are never touched
/// here — only its sync-status fields are, via [TransactionRepository.markSynced]
/// / [markSyncFailed]. If the Sheets API is unreachable, local data is
/// simply left as-is.
class TransactionSyncService {
  TransactionSyncService({
    required this.driveAuthorizationGateway,
    required this.sheetsApiClient,
    required this.syncSettingsRepository,
    required this.transactionRepository,
  });

  final DriveAuthorizationGateway driveAuthorizationGateway;
  final SheetsApiClient sheetsApiClient;
  final SyncSettingsRepository syncSettingsRepository;
  final TransactionRepository transactionRepository;

  Future<SyncRunOutcome> syncPendingTransactions({void Function(SyncProgress)? onProgress}) async {
    final pending = await transactionRepository.getTransactionsNeedingSync();
    debugPrint('[SheetSync] TransactionSyncService.syncPendingTransactions: ${pending.length} transaction(s) to sync');
    if (pending.isEmpty) {
      // Nothing to do is a fully-synced state, not a no-op idle state — it's
      // exactly as true as if every (zero) required transaction succeeded.
      await syncSettingsRepository.setSyncRunState(SyncRunState.synced);
      await syncSettingsRepository.setLastSuccessfulSync(DateTime.now());
      return const SyncRunCompleted(succeeded: 0, failed: 0);
    }

    await syncSettingsRepository.setSyncRunState(SyncRunState.syncing);

    final settings = await syncSettingsRepository.getSettings();
    final spreadsheetId = settings.spreadsheetId;
    if (spreadsheetId == null) {
      await syncSettingsRepository.setSyncRunState(SyncRunState.syncFailed);
      return const SyncRunAborted('No spreadsheet is connected.');
    }

    final auth = await driveAuthorizationGateway.authorizeForCreate();
    final String accessToken;
    switch (auth) {
      case DriveAuthorizationSuccess(accessToken: final token):
        accessToken = token;
      case DriveAuthorizationCancelled():
        await syncSettingsRepository.setSyncRunState(SyncRunState.syncFailed);
        return const SyncRunAborted('Authorization was cancelled.');
      case DriveAuthorizationFailure(:final message):
        await syncSettingsRepository.setSyncRunState(SyncRunState.syncFailed);
        return SyncRunAborted(message);
    }

    final headerResult = await sheetsApiClient.ensureHeaderRow(accessToken, spreadsheetId, transactionSheetHeaders);
    if (headerResult is SheetWriteFailure) {
      await syncSettingsRepository.setSyncRunState(SyncRunState.syncFailed);
      return SyncRunAborted(headerResult.reason);
    }

    final rowIndexResult = await sheetsApiClient.fetchTransactionRowIndex(accessToken, spreadsheetId);
    final Map<String, int> rowIndex;
    switch (rowIndexResult) {
      case RowIndexLoaded(:final rowNumberByTransactionId):
        rowIndex = Map<String, int>.from(rowNumberByTransactionId);
      case RowIndexFailure(:final reason):
        await syncSettingsRepository.setSyncRunState(SyncRunState.syncFailed);
        return SyncRunAborted(reason);
    }

    var succeeded = 0;
    var failed = 0;
    for (var i = 0; i < pending.length; i++) {
      final tx = pending[i];
      final key = tx.id.toString();
      final values = _rowValuesFor(tx);
      final existingRow = rowIndex[key];

      final writeResult = existingRow != null
          ? await sheetsApiClient.updateRow(accessToken, spreadsheetId, rowNumber: existingRow, values: values)
          : await sheetsApiClient.appendRow(accessToken, spreadsheetId, values: values);

      switch (writeResult) {
        case SheetWriteSuccess(:final rowNumber):
          await transactionRepository.markSynced(tx.id, remoteRowRef: rowNumber.toString(), syncedAt: DateTime.now());
          rowIndex[key] = rowNumber;
          succeeded++;
        case SheetWriteFailure(:final reason):
          await transactionRepository.markSyncFailed(tx.id, reason);
          failed++;
      }

      onProgress?.call(SyncProgress(completed: i + 1, total: pending.length));
    }

    if (failed == 0) {
      await syncSettingsRepository.setSyncRunState(SyncRunState.synced);
      await syncSettingsRepository.setLastSuccessfulSync(DateTime.now());
    } else {
      await syncSettingsRepository.setSyncRunState(SyncRunState.partiallySynced);
    }
    return SyncRunCompleted(succeeded: succeeded, failed: failed);
  }

  List<Object?> _rowValuesFor(Transaction tx) => [
    tx.id.toString(),
    tx.occurredAt.toIso8601String(),
    tx.type.name,
    tx.amountPaise / 100,
    tx.displayName,
    tx.bankName ?? '',
    tx.referenceId ?? '',
    tx.category ?? '',
    tx.note ?? '',
    tx.sourceList.join(','),
  ];
}
