/// Outcome of resolving a spreadsheet (creating or verifying it) against the
/// real Google Sheets API.
sealed class SpreadsheetResolution {
  const SpreadsheetResolution();
}

class SpreadsheetResolved extends SpreadsheetResolution {
  const SpreadsheetResolved({required this.spreadsheetId, required this.title});
  final String spreadsheetId;
  final String title;
}

/// Covers both "doesn't exist" and "not accessible" and "not a real sheet" —
/// any reason the app cannot safely treat this as the connected spreadsheet.
class SpreadsheetUnavailable extends SpreadsheetResolution {
  const SpreadsheetUnavailable(this.reason);
  final String reason;
}

/// Outcome of a single row write (update or append).
sealed class SheetWriteResult {
  const SheetWriteResult();
}

class SheetWriteSuccess extends SheetWriteResult {
  const SheetWriteSuccess(this.rowNumber);

  /// 1-based row number the value now lives at in the sheet.
  final int rowNumber;
}

class SheetWriteFailure extends SheetWriteResult {
  const SheetWriteFailure(this.reason);
  final String reason;
}

/// Outcome of reading back which rows already exist for which transaction
/// ids. Modeled as its own result (rather than just returning an empty map
/// on any failure) so a network/auth error can't be silently mistaken for
/// "no rows exist yet" — that confusion is exactly what would risk creating
/// duplicate rows.
sealed class RowIndexResult {
  const RowIndexResult();
}

class RowIndexLoaded extends RowIndexResult {
  const RowIndexLoaded(this.rowNumberByTransactionId);

  /// Transaction id (as written in column A) -> 1-based row number.
  final Map<String, int> rowNumberByTransactionId;
}

class RowIndexFailure extends RowIndexResult {
  const RowIndexFailure(this.reason);
  final String reason;
}

/// Talks to the Google Sheets API (`sheets.googleapis.com`) using a
/// short-lived access token the caller already obtained via
/// [DriveAuthorizationGateway]. Implementations must never persist or log
/// that token — it is passed in per-call and immediately discarded.
abstract class SheetsApiClient {
  Future<SpreadsheetResolution> createSpreadsheet(String accessToken, String title);

  Future<SpreadsheetResolution> verifySpreadsheet(String accessToken, String spreadsheetId);

  /// Writes [headers] into row 1 if it's currently empty; a no-op otherwise.
  Future<SheetWriteResult> ensureHeaderRow(String accessToken, String spreadsheetId, List<String> headers);

  /// Reads column A (skipping the header row) so callers can locate an
  /// existing row by transaction id instead of trusting a possibly-stale
  /// [Transaction.remoteRowRef].
  Future<RowIndexResult> fetchTransactionRowIndex(String accessToken, String spreadsheetId);

  /// Overwrites an existing row in place.
  Future<SheetWriteResult> updateRow(
    String accessToken,
    String spreadsheetId, {
    required int rowNumber,
    required List<Object?> values,
  });

  /// Appends a brand-new row; the returned [SheetWriteSuccess.rowNumber] is
  /// whatever row Sheets actually assigned it.
  Future<SheetWriteResult> appendRow(String accessToken, String spreadsheetId, {required List<Object?> values});
}
