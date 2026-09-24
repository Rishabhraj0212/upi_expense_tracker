import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'sheets_api_client.dart';

/// Real [SheetsApiClient], talking to the Google Sheets REST API directly.
/// `drive.file`-scoped tokens are honored by this API for files the app
/// created or that were explicitly granted via the Picker, so no broader
/// Drive/Sheets scope is needed.
class HttpSheetsApiClient implements SheetsApiClient {
  HttpSheetsApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://sheets.googleapis.com/v4/spreadsheets';

  @override
  Future<SpreadsheetResolution> createSpreadsheet(String accessToken, String title) async {
    debugPrint('[SheetSync] HttpSheetsApiClient.createSpreadsheet: entry');
    try {
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: _headers(accessToken),
        body: jsonEncode({
          'properties': {'title': title},
        }),
      );
      debugPrint('[SheetSync] HttpSheetsApiClient.createSpreadsheet: HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        return SpreadsheetUnavailable('Could not create the spreadsheet (HTTP ${response.statusCode}).');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final id = body['spreadsheetId'] as String?;
      if (id == null) {
        return const SpreadsheetUnavailable('The spreadsheet was created without an id.');
      }
      final resolvedTitle = (body['properties'] as Map<String, dynamic>?)?['title'] as String?;
      return SpreadsheetResolved(spreadsheetId: id, title: resolvedTitle ?? title);
    } catch (e) {
      debugPrint('[SheetSync] HttpSheetsApiClient.createSpreadsheet: ${e.runtimeType}: $e');
      return SpreadsheetUnavailable('Network error while creating the spreadsheet: $e');
    }
  }

  @override
  Future<SpreadsheetResolution> verifySpreadsheet(String accessToken, String spreadsheetId) async {
    debugPrint('[SheetSync] HttpSheetsApiClient.verifySpreadsheet: entry');
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/$spreadsheetId?fields=spreadsheetId,properties.title'),
        headers: _headers(accessToken),
      );
      debugPrint('[SheetSync] HttpSheetsApiClient.verifySpreadsheet: HTTP ${response.statusCode}');
      if (response.statusCode == 404) {
        return const SpreadsheetUnavailable('That file could not be found. It may have been deleted or moved.');
      }
      if (response.statusCode == 403) {
        return const SpreadsheetUnavailable('Access to that file was denied.');
      }
      if (response.statusCode != 200) {
        return SpreadsheetUnavailable('Could not access the spreadsheet (HTTP ${response.statusCode}).');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final id = body['spreadsheetId'] as String?;
      final title = (body['properties'] as Map<String, dynamic>?)?['title'] as String?;
      if (id == null || title == null) {
        return const SpreadsheetUnavailable('The selected file is not a valid Google Sheet.');
      }
      return SpreadsheetResolved(spreadsheetId: id, title: title);
    } catch (e) {
      debugPrint('[SheetSync] HttpSheetsApiClient.verifySpreadsheet: ${e.runtimeType}: $e');
      return SpreadsheetUnavailable('Network error while verifying the spreadsheet: $e');
    }
  }

  // Google Sheets defaults a freshly created spreadsheet to a single tab
  // named "Sheet1". An existing spreadsheet picked via the Picker could in
  // principle use a different tab name; that's a known simplification for
  // this step — a mismatch here surfaces as a visible, per-row sync failure
  // (never a silent one) rather than corrupting anything.
  static const _sheetName = 'Sheet1';

  @override
  Future<SheetWriteResult> ensureHeaderRow(String accessToken, String spreadsheetId, List<String> headers) async {
    final lastColumn = _columnLetter(headers.length);
    try {
      final getResponse = await _client.get(
        Uri.parse('$_baseUrl/$spreadsheetId/values/$_sheetName!A1:$lastColumn' '1'),
        headers: _headers(accessToken),
      );
      debugPrint('[SheetSync] HttpSheetsApiClient.ensureHeaderRow: read HTTP ${getResponse.statusCode}');
      if (getResponse.statusCode == 200) {
        final body = jsonDecode(getResponse.body) as Map<String, dynamic>;
        final values = body['values'] as List<dynamic>?;
        if (values != null && values.isNotEmpty) {
          return const SheetWriteSuccess(1);
        }
      }
      final putResponse = await _client.put(
        Uri.parse('$_baseUrl/$spreadsheetId/values/$_sheetName!A1:$lastColumn' '1?valueInputOption=RAW'),
        headers: _headers(accessToken),
        body: jsonEncode({
          'values': [headers],
        }),
      );
      debugPrint('[SheetSync] HttpSheetsApiClient.ensureHeaderRow: write HTTP ${putResponse.statusCode}');
      if (putResponse.statusCode != 200) {
        return SheetWriteFailure('Could not write the header row (HTTP ${putResponse.statusCode}).');
      }
      return const SheetWriteSuccess(1);
    } catch (e) {
      debugPrint('[SheetSync] HttpSheetsApiClient.ensureHeaderRow: ${e.runtimeType}: $e');
      return SheetWriteFailure('Network error while preparing the sheet: $e');
    }
  }

  @override
  Future<RowIndexResult> fetchTransactionRowIndex(String accessToken, String spreadsheetId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/$spreadsheetId/values/$_sheetName!A2:A'),
        headers: _headers(accessToken),
      );
      debugPrint('[SheetSync] HttpSheetsApiClient.fetchTransactionRowIndex: HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        return RowIndexFailure('Could not read existing rows (HTTP ${response.statusCode}).');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final values = body['values'] as List<dynamic>? ?? const [];
      final index = <String, int>{};
      for (var i = 0; i < values.length; i++) {
        final row = values[i] as List<dynamic>;
        if (row.isEmpty) continue;
        final id = row.first?.toString();
        if (id != null && id.isNotEmpty) {
          // +2: 1-based rows, and row 1 is the header (A2 is the first data row).
          index[id] = i + 2;
        }
      }
      return RowIndexLoaded(index);
    } catch (e) {
      debugPrint('[SheetSync] HttpSheetsApiClient.fetchTransactionRowIndex: ${e.runtimeType}: $e');
      return RowIndexFailure('Network error while reading existing rows: $e');
    }
  }

  @override
  Future<SheetWriteResult> updateRow(
    String accessToken,
    String spreadsheetId, {
    required int rowNumber,
    required List<Object?> values,
  }) async {
    final lastColumn = _columnLetter(values.length);
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/$spreadsheetId/values/$_sheetName!A$rowNumber:$lastColumn$rowNumber?valueInputOption=RAW'),
        headers: _headers(accessToken),
        body: jsonEncode({
          'values': [values],
        }),
      );
      debugPrint('[SheetSync] HttpSheetsApiClient.updateRow: HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        return SheetWriteFailure('Could not update row $rowNumber (HTTP ${response.statusCode}).');
      }
      return SheetWriteSuccess(rowNumber);
    } catch (e) {
      debugPrint('[SheetSync] HttpSheetsApiClient.updateRow: ${e.runtimeType}: $e');
      return SheetWriteFailure('Network error while updating row $rowNumber: $e');
    }
  }

  @override
  Future<SheetWriteResult> appendRow(String accessToken, String spreadsheetId, {required List<Object?> values}) async {
    final lastColumn = _columnLetter(values.length);
    try {
      final response = await _client.post(
        Uri.parse(
          '$_baseUrl/$spreadsheetId/values/$_sheetName!A1:$lastColumn' '1:append'
          '?valueInputOption=RAW&insertDataOption=INSERT_ROWS',
        ),
        headers: _headers(accessToken),
        body: jsonEncode({
          'values': [values],
        }),
      );
      debugPrint('[SheetSync] HttpSheetsApiClient.appendRow: HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        return SheetWriteFailure('Could not append a new row (HTTP ${response.statusCode}).');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final updatedRange = (body['updates'] as Map<String, dynamic>?)?['updatedRange'] as String?;
      final rowNumber = _rowNumberFromRange(updatedRange);
      if (rowNumber == null) {
        return const SheetWriteFailure('The appended row\'s position could not be determined.');
      }
      return SheetWriteSuccess(rowNumber);
    } catch (e) {
      debugPrint('[SheetSync] HttpSheetsApiClient.appendRow: ${e.runtimeType}: $e');
      return SheetWriteFailure('Network error while appending a row: $e');
    }
  }

  /// 1 -> "A", 2 -> "B", ... Sufficient for this app's fixed, small column
  /// count (well under 26).
  static String _columnLetter(int oneBasedCount) => String.fromCharCode('A'.codeUnitAt(0) + oneBasedCount - 1);

  /// "Sheet1!A5:J5" -> 5.
  static int? _rowNumberFromRange(String? range) {
    if (range == null) return null;
    final match = RegExp(r'![A-Z]+(\d+)').firstMatch(range);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static Map<String, String> _headers(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };
}
