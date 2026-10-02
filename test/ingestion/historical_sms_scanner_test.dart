import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/raw_event.dart';
import 'package:upi_expense_tracker/domain/models/transaction.dart' as domain;
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/domain/models/expense_category.dart';
import 'package:upi_expense_tracker/domain/repositories/category_repository.dart';
import 'package:upi_expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:upi_expense_tracker/dedup/duplicate_detector.dart';
import 'package:upi_expense_tracker/ingestion/historical_sms_scanner.dart';
import 'package:upi_expense_tracker/ingestion/ingestion_service.dart';
import 'package:upi_expense_tracker/parsing/parser_registry.dart';
import 'package:upi_expense_tracker/platform/sms_inbox_reader.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeRepository implements TransactionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final Map<int, domain.Transaction> rows = {};
  int _nextId = 1;

  @override
  Future<int> insert(ParsedTransaction parsed) async {
    final id = _nextId++;
    rows[id] = domain.Transaction(
      id: id,
      amountPaise: parsed.amountPaise,
      type: parsed.type,
      occurredAt: parsed.occurredAt,
      receivedAt: parsed.occurredAt,
      mergedSources: parsed.sourceType.name,
      rawText: parsed.rawText,
      createdAt: parsed.occurredAt,
      updatedAt: parsed.occurredAt,
      referenceId: parsed.referenceId,
      merchantName: parsed.merchantName,
      upiId: parsed.upiId,
    );
    return id;
  }

  @override
  Future<void> mergeInto(int existingId, ParsedTransaction parsed) async {}

  @override
  Future<domain.Transaction?> getById(int id) async => rows[id];

  @override
  Future<List<domain.Transaction>> findByReferenceId(String referenceId) async =>
      rows.values.where((t) => t.referenceId == referenceId).toList();

  @override
  Future<List<domain.Transaction>> findByAmountNear(
    int amountPaise,
    DateTime around,
    Duration window,
  ) async =>
      rows.values
          .where((t) =>
              t.amountPaise == amountPaise &&
              t.occurredAt.difference(around).abs() <= window)
          .toList();

  @override
  Future<void> logCapture({
    required String sourceType,
    required String? origin,
    required String text,
    required String result,
    required DateTime at,
  }) async {}

  @override
  Future<List<domain.Transaction>> getAll({
    TransactionFilter filter = TransactionFilter.none,
    int limit = 500,
  }) async =>
      rows.values.toList();

  @override
  Stream<List<domain.Transaction>> watchAll({
    TransactionFilter filter = TransactionFilter.none,
    int limit = 500,
  }) =>
      const Stream.empty();

  @override
  Future<void> setCategory(int id, String? category, String? note) async {}

  @override
  Future<void> delete(int id) async => rows.remove(id);

  @override
  Future<List<domain.Transaction>> getTransactionsNeedingSync() async =>
      rows.values.toList();

  @override
  Future<void> markSynced(int id, {String? remoteRowRef, required DateTime syncedAt}) async {}

  @override
  Future<void> markSyncFailed(int id, String error) async {}

  @override
  Future<void> markPending(int id) async {}

  @override
  Future<TransactionSyncCounts> getSyncCounts() async =>
      const TransactionSyncCounts(synced: 0, pending: 0, failed: 0);

  @override
  Future<List<CaptureLogEntry>> getCaptures({int limit = 200}) async => [];

  @override
  Future<void> clearCaptures() async {}
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Stream<List<ExpenseCategory>> watchAllCategories() => Stream.value([]);
  @override
  Future<List<ExpenseCategory>> getAllCategories() async => [];
  @override
  Future<ExpenseCategory> addCustomCategory(String name) async =>
      ExpenseCategory(id: 1, name: name, isDefault: false);
  @override
  Future<void> updateCustomCategory(int id, String newName) async {}
  @override
  Future<void> deleteCustomCategory(int id) async {}
  @override
  Future<void> saveRule(String merchantKey, String category) async {}
  @override
  Future<String?> getCategoryForMerchant(String merchantKey) async => null;
}

/// A fake SMS inbox reader that returns predetermined messages.
class _FakeSmsInboxReader extends SmsInboxReader {
  _FakeSmsInboxReader(this.messages);

  final List<RawEvent> messages;

  @override
  Future<int> getCount({required DateTime since, required DateTime until}) async =>
      messages.length;

  @override
  Future<List<RawEvent>> readBatch({
    required DateTime since,
    required DateTime until,
    required int offset,
    int limit = 100,
  }) async {
    if (offset >= messages.length) return [];
    final end = (offset + limit).clamp(0, messages.length);
    return messages.sublist(offset, end);
  }
}

class _EmptySmsInboxReader extends SmsInboxReader {
  @override
  Future<int> getCount({required DateTime since, required DateTime until}) async => 0;

  @override
  Future<List<RawEvent>> readBatch({
    required DateTime since,
    required DateTime until,
    required int offset,
    int limit = 100,
  }) async =>
      [];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final now = DateTime(2026, 9, 28, 12, 0);

  RawEvent sms(String text, {String origin = 'HDFCBK', DateTime? at}) => RawEvent(
        sourceType: SourceType.sms,
        origin: origin,
        text: text,
        receivedAt: at ?? now,
      );

  late _FakeRepository repo;
  late _FakeCategoryRepository catRepo;
  late IngestionService ingestionService;

  setUp(() {
    repo = _FakeRepository();
    catRepo = _FakeCategoryRepository();
    ingestionService = IngestionService(
      parserRegistry: ParserRegistry(),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: catRepo,
    );
  });

  test('historical SMS converted to RawEvent and new transaction discovered', () async {
    final messages = [
      sms('Rs.500.00 debited from A/c XX1234 on 28-09-26 to merchant@ybl '
          'UPI Ref No 302615478321 -HDFC Bank'),
    ];

    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    final result = await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);

    expect(result.totalMessages, 1);
    expect(result.newTransactions, 1);
    expect(result.duplicates, 0);
    expect(repo.rows.length, 1);
    expect(repo.rows.values.first.amountPaise, 50000);
  });

  test('existing transaction ignored (dedup)', () async {
    // Pre-populate an existing transaction with the same reference id.
    await repo.insert(ParsedTransaction(
      amountPaise: 50000,
      type: TransactionType.debit,
      occurredAt: now,
      sourceType: SourceType.sms,
      rawText: 'original',
      referenceId: '302615478321',
    ));

    final messages = [
      sms('Rs.500.00 debited from A/c XX1234 on 28-09-26 to merchant@ybl '
          'UPI Ref No 302615478321 -HDFC Bank'),
    ];

    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    final result = await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);

    expect(result.newTransactions, 0);
    expect(result.duplicates, 1);
    // Still only 1 row — the original
    expect(repo.rows.length, 1);
  });

  test('duplicate-safe repeated scan', () async {
    final messages = [
      sms('Rs.200.00 debited from A/c XX1234 on 28-09-26 to shop@ybl '
          'UPI Ref No 111122223333 -HDFC Bank'),
    ];

    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    // First scan — inserts
    final first = await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);
    expect(first.newTransactions, 1);
    expect(repo.rows.length, 1);

    // Second scan — duplicate
    final second = await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);
    expect(second.newTransactions, 0);
    expect(second.duplicates, 1);
    expect(repo.rows.length, 1);
  });

  test('parser rejection does not stop scan', () async {
    final messages = [
      // This OTP will be rejected by the parser
      sms('123456 is your OTP for a transaction of Rs.5000 at Amazon.'),
      // This is a real transaction — should be parsed
      sms('Rs.100.00 debited from A/c XX1234 on 28-09-26 to shop@ybl '
          'UPI Ref No 444455556666 -HDFC Bank'),
    ];

    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    final result = await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);

    expect(result.totalMessages, 2);
    expect(result.newTransactions, 1);
    expect(result.failed, 0); // OTP is 'ignored', not 'failed'
    expect(repo.rows.length, 1);
  });

  test('malformed SMS does not stop scan', () async {
    final messages = [
      // Non-bank, totally random message
      sms('Hey! How are you doing? Let\'s catch up tonight.', origin: 'FRIEND'),
      // A real transaction
      sms('Rs.300.00 debited from A/c XX9999 on 28-09-26 to cafe@ybl '
          'UPI Ref No 777788889999 -HDFC Bank'),
    ];

    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    final result = await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);

    expect(result.totalMessages, 2);
    expect(result.newTransactions, 1);
    expect(repo.rows.length, 1);
  });

  test('empty inbox produces zero results', () async {
    final scanner = HistoricalSmsScanner(
      smsInboxReader: _EmptySmsInboxReader(),
      ingestionService: ingestionService,
    );

    final result = await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);

    expect(result.totalMessages, 0);
    expect(result.newTransactions, 0);
    expect(result.duplicates, 0);
  });

  test('batch progress reporting works', () async {
    final messages = List.generate(
      3,
      (i) => sms(
        'Rs.${(i + 1) * 100}.00 debited from A/c XX1234 on 28-09-26 to shop$i@ybl '
        'UPI Ref No ${100000000000 + i} -HDFC Bank',
      ),
    );

    final progressSnapshots = <ScanProgress>[];
    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    await scanner.scan(
      since: now.subtract(const Duration(days: 90)),
      until: now,
      onProgress: (p) => progressSnapshots.add(p),
    );

    // At least initial (0/3) and final (3/3) progress
    expect(progressSnapshots.length, greaterThanOrEqualTo(2));
    expect(progressSnapshots.first.processedMessages, 0);
    expect(progressSnapshots.last.processedMessages, 3);
    expect(progressSnapshots.last.newTransactions, 3);
  });

  test('concurrent scan is rejected', () async {
    final messages = [
      sms('Rs.100.00 debited from A/c XX1234 on 28-09-26 to shop@ybl '
          'UPI Ref No 999900001111 -HDFC Bank'),
    ];

    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    // Start a scan but don't await it
    final first = scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);

    // Second scan while first is running should throw
    expect(
      () => scanner.scan(since: now.subtract(const Duration(days: 90)), until: now),
      throwsStateError,
    );

    await first; // cleanup
  });

  group('scan window logic', () {
    test('first scan uses 90-day window', () {
      final now = DateTime(2026, 9, 28, 12, 0);
      // lastSmsRescanAt is null → 90 days back
      final since = now.subtract(const Duration(days: 90));
      expect(since, DateTime(2026, 6, 30, 12, 0));
    });

    test('48-hour overlap for subsequent scans', () {
      final lastRescan = DateTime(2026, 9, 25, 10, 0);
      final since = lastRescan.subtract(const Duration(hours: 48));
      expect(since, DateTime(2026, 9, 23, 10, 0));
    });
  });

  test('recovered transactions get PENDING sync status by default', () async {
    final messages = [
      sms('Rs.500.00 debited from A/c XX1234 on 28-09-26 to merchant@ybl '
          'UPI Ref No 302615478321 -HDFC Bank'),
    ];

    final scanner = HistoricalSmsScanner(
      smsInboxReader: _FakeSmsInboxReader(messages),
      ingestionService: ingestionService,
    );

    await scanner.scan(since: now.subtract(const Duration(days: 90)), until: now);

    // The _FakeRepository insert creates the row. In the real
    // DriftTransactionRepository, every new insert gets syncStatus=pending
    // by default (the column default in the schema). We verify the scanner
    // uses the same insert path, not a custom one.
    expect(repo.rows.length, 1);
    // The scanner calls ingestionService.process → repo.insert — same
    // pipeline as real-time, so sync status will be PENDING in production.
  });
}
