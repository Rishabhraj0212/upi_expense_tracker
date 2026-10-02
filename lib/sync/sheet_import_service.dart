import 'package:flutter/foundation.dart';

import '../domain/models/parsed_transaction.dart';
import '../domain/models/transaction_source.dart';
import '../domain/models/transaction_type.dart';
import '../domain/repositories/sync_settings_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import 'drive_authorization_gateway.dart';
import 'sheets_api_client.dart';

/// Result of one full import run.
sealed class SheetImportOutcome {
  const SheetImportOutcome();
}

class SheetImportSuccess extends SheetImportOutcome {
  const SheetImportSuccess({
    required this.imported,
    required this.skipped,
    required this.failed,
  });
  final int imported;
  final int skipped;
  final int failed;
}

class SheetImportAborted extends SheetImportOutcome {
  const SheetImportAborted(this.reason);
  final String reason;
}

/// A single parsed row before category application.
class _RowData {
  const _RowData({required this.parsed, this.category});
  final ParsedTransaction parsed;
  final String? category;
}

/// Reads every data row from the connected Google Sheet and inserts
/// each one into the local database (skipping rows that are already
/// present, based on referenceId from column 6 for duplicate detection).
///
/// Column layout (0-indexed) matches [transactionSheetHeaders]:
///   0  Transaction ID (the remote ID — not reused; DB assigns its own)
///   1  Date         (ISO-8601)
///   2  Type         (debit / credit)
///   3  Amount (INR) (decimal)
///   4  Merchant / UPI ID
///   5  Bank
///   6  Reference ID
///   7  Category
///   8  Note
///   9  Source       (comma-separated SourceType names)
class SheetImportService {
  SheetImportService({
    required this.driveAuthorizationGateway,
    required this.sheetsApiClient,
    required this.syncSettingsRepository,
    required this.transactionRepository,
  });

  final DriveAuthorizationGateway driveAuthorizationGateway;
  final SheetsApiClient sheetsApiClient;
  final SyncSettingsRepository syncSettingsRepository;
  final TransactionRepository transactionRepository;

  Future<SheetImportOutcome> importFromSheet({
    void Function(int done, int total)? onProgress,
  }) async {
    debugPrint('[SheetImport] SheetImportService.importFromSheet: entry');

    final settings = await syncSettingsRepository.getSettings();
    final spreadsheetId = settings.spreadsheetId;
    if (spreadsheetId == null) {
      return const SheetImportAborted('No spreadsheet is connected.');
    }

    final auth = await driveAuthorizationGateway.authorizeForCreate();
    final String accessToken;
    switch (auth) {
      case DriveAuthorizationSuccess(accessToken: final token):
        accessToken = token;
      case DriveAuthorizationCancelled():
        return const SheetImportAborted('Authorization was cancelled.');
      case DriveAuthorizationFailure(:final message):
        return SheetImportAborted(message);
    }

    final rowsResult = await sheetsApiClient.fetchAllRows(accessToken, spreadsheetId);
    final List<SheetRow> rows;
    switch (rowsResult) {
      case SheetAllRowsLoaded(rows: final r):
        rows = r;
      case SheetAllRowsFailure(:final reason):
        return SheetImportAborted(reason);
    }

    debugPrint('[SheetImport] fetched ${rows.length} data row(s) from sheet');

    var imported = 0;
    var skipped = 0;
    var failed = 0;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      try {
        final rowData = _parseRow(row);
        if (rowData == null) {
          skipped++;
          onProgress?.call(i + 1, rows.length);
          continue;
        }

        // Skip if we already have a transaction with the same reference ID.
        final refId = rowData.parsed.referenceId;
        if (refId != null && refId.isNotEmpty) {
          final existing = await transactionRepository.findByReferenceId(refId);
          if (existing.isNotEmpty) {
            skipped++;
            onProgress?.call(i + 1, rows.length);
            continue;
          }
        }

        final newId = await transactionRepository.insert(rowData.parsed);

        // Restore category if the sheet row had one.
        if (rowData.category != null && rowData.category!.isNotEmpty) {
          await transactionRepository.setCategory(newId, rowData.category, null);
        }

        imported++;
      } catch (e) {
        debugPrint('[SheetImport] row $i failed: $e');
        failed++;
      }
      onProgress?.call(i + 1, rows.length);
    }

    debugPrint(
      '[SheetImport] done — imported=$imported skipped=$skipped failed=$failed',
    );
    return SheetImportSuccess(imported: imported, skipped: skipped, failed: failed);
  }

  /// Converts one sheet row (10 columns, padded) to a [_RowData].
  /// Returns null for rows that cannot be meaningfully imported (e.g. empty
  /// amount or unrecognisable date).
  _RowData? _parseRow(SheetRow row) {
    final dateStr = row[1].trim();
    final typeStr = row[2].trim().toLowerCase();
    final amountStr = row[3].trim();
    final merchant = row[4].trim();
    final bank = row[5].trim();
    final refId = row[6].trim();
    final category = row[7].trim();
    final note = row[8].trim();
    final sourceStr = row[9].trim();

    final occurredAt = DateTime.tryParse(dateStr);
    if (occurredAt == null) return null;

    final amountDecimal = double.tryParse(amountStr);
    if (amountDecimal == null) return null;
    final amountPaise = (amountDecimal * 100).round();
    if (amountPaise <= 0) return null;

    final type = typeStr == 'credit' ? TransactionType.credit : TransactionType.debit;

    // Best-effort: use the first SourceType found in the comma-separated list.
    SourceType sourceType = SourceType.manual;
    for (final part in sourceStr.split(',')) {
      try {
        sourceType = SourceType.fromName(part.trim());
        break;
      } catch (_) {}
    }

    // Split "merchant / UPI ID" — store as merchantName if it doesn't look
    // like a UPI VPA, otherwise as upiId.
    String? merchantName;
    String? upiId;
    if (merchant.contains('@')) {
      upiId = merchant;
    } else if (merchant.isNotEmpty) {
      merchantName = merchant;
    }

    final parsed = ParsedTransaction(
      amountPaise: amountPaise,
      type: type,
      occurredAt: occurredAt,
      sourceType: sourceType,
      rawText: 'Restored from Google Sheet',
      merchantName: merchantName,
      upiId: upiId,
      bankName: bank.isNotEmpty ? bank : null,
      referenceId: refId.isNotEmpty ? refId : null,
      note: note.isNotEmpty ? note : null,
    );

    return _RowData(
      parsed: parsed,
      category: category.isNotEmpty ? category : null,
    );
  }
}
