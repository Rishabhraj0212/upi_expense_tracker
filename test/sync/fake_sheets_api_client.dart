import 'package:upi_expense_tracker/sync/sheets_api_client.dart';

/// Simulates a real Google Sheet well enough to exercise
/// [TransactionSyncService] end-to-end: row 1 is the header (once written),
/// each subsequent row is data, [updateRow]/[appendRow] actually mutate an
/// in-memory table, and [fetchTransactionRowIndex] is derived from that
/// table's current contents — exactly mirroring how a real duplicate-safe
/// sync run would re-derive row positions from the live sheet.
class FakeSheetsApiClient implements SheetsApiClient {
  SpreadsheetResolution nextCreateResolution = const SpreadsheetResolved(
    spreadsheetId: 'new-sheet-id',
    title: 'UPI Expense Tracker',
  );
  SpreadsheetResolution nextVerifyResolution = const SpreadsheetUnavailable('not configured for this test');

  String? lastAccessTokenUsed;
  String? lastVerifiedSpreadsheetId;
  int createCalls = 0;
  int verifyCalls = 0;

  @override
  Future<SpreadsheetResolution> createSpreadsheet(String accessToken, String title) async {
    createCalls++;
    lastAccessTokenUsed = accessToken;
    return nextCreateResolution;
  }

  @override
  Future<SpreadsheetResolution> verifySpreadsheet(String accessToken, String spreadsheetId) async {
    verifyCalls++;
    lastAccessTokenUsed = accessToken;
    lastVerifiedSpreadsheetId = spreadsheetId;
    return nextVerifyResolution;
  }

  // --- In-memory "sheet" (index 0 == row 1) ---
  final List<List<Object?>> rows = [];

  bool get _hasHeader => rows.isNotEmpty;

  int ensureHeaderRowCalls = 0;
  int fetchTransactionRowIndexCalls = 0;
  int updateRowCalls = 0;
  int appendRowCalls = 0;

  /// Override points for forcing a systemic (whole-run) failure.
  SheetWriteResult? forcedHeaderResult;
  RowIndexResult? forcedRowIndexResult;

  /// Transaction ids (column A values, as strings) that should fail to
  /// write, so partial-failure/retry scenarios can be simulated precisely.
  final Set<String> failWritesForIds = {};
  String writeFailureReason = 'simulated write failure';

  @override
  Future<SheetWriteResult> ensureHeaderRow(String accessToken, String spreadsheetId, List<String> headers) async {
    ensureHeaderRowCalls++;
    if (forcedHeaderResult != null) return forcedHeaderResult!;
    if (!_hasHeader) rows.add(List<Object?>.from(headers));
    return const SheetWriteSuccess(1);
  }

  @override
  Future<RowIndexResult> fetchTransactionRowIndex(String accessToken, String spreadsheetId) async {
    fetchTransactionRowIndexCalls++;
    if (forcedRowIndexResult != null) return forcedRowIndexResult!;
    final index = <String, int>{};
    for (var i = 1; i < rows.length; i++) {
      final id = rows[i].isNotEmpty ? rows[i].first?.toString() : null;
      if (id != null && id.isNotEmpty) index[id] = i + 1; // 1-based row number
    }
    return RowIndexLoaded(index);
  }

  @override
  Future<SheetWriteResult> updateRow(
    String accessToken,
    String spreadsheetId, {
    required int rowNumber,
    required List<Object?> values,
  }) async {
    updateRowCalls++;
    final id = values.isNotEmpty ? values.first?.toString() : null;
    if (id != null && failWritesForIds.contains(id)) {
      return SheetWriteFailure(writeFailureReason);
    }
    final index = rowNumber - 1;
    while (rows.length <= index) {
      rows.add(const []);
    }
    rows[index] = List<Object?>.from(values);
    return SheetWriteSuccess(rowNumber);
  }

  @override
  Future<SheetWriteResult> appendRow(String accessToken, String spreadsheetId, {required List<Object?> values}) async {
    appendRowCalls++;
    final id = values.isNotEmpty ? values.first?.toString() : null;
    if (id != null && failWritesForIds.contains(id)) {
      return SheetWriteFailure(writeFailureReason);
    }
    rows.add(List<Object?>.from(values));
    return SheetWriteSuccess(rows.length);
  }

  /// Test helpers for pre-seeding sheet state (e.g. simulating a row that
  /// already exists from an earlier, partially-completed run).
  void seedHeader(List<String> headers) {
    if (!_hasHeader) rows.add(List<Object?>.from(headers));
  }

  void seedDataRow(List<Object?> values) => rows.add(List<Object?>.from(values));

  int get dataRowCount => _hasHeader ? rows.length - 1 : rows.length;

  List<Object?>? rowValuesForTransactionId(String id) {
    for (final row in rows) {
      if (row.isNotEmpty && row.first?.toString() == id) return row;
    }
    return null;
  }
}
