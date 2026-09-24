import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/dedup/duplicate_detector.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/raw_event.dart';
import 'package:upi_expense_tracker/domain/models/transaction.dart' as domain;
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/repositories/category_repository.dart';
import 'package:upi_expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:upi_expense_tracker/ingestion/ingestion_result.dart';
import 'package:upi_expense_tracker/ingestion/ingestion_service.dart';
import 'package:upi_expense_tracker/parsing/parser_registry.dart';
import 'package:upi_expense_tracker/parsing/transaction_parser.dart';

class _CaptureLog {
  _CaptureLog(this.sourceType, this.origin, this.text, this.result, this.at);
  final String sourceType;
  final String? origin;
  final String text;
  final String result;
  final DateTime at;
}

/// In-memory fake covering everything IngestionService (via DuplicateDetector)
/// actually calls: insert, mergeInto, logCapture, findByReferenceId,
/// findByAmountNear. Good enough to observe end-to-end pipeline behavior
/// without spinning up Drift.
class _FakeRepository implements TransactionRepository {
  final Map<int, domain.Transaction> rows = {};
  final List<_CaptureLog> captureLog = [];
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
      merchantName: parsed.merchantName,
      upiId: parsed.upiId,
      bankName: parsed.bankName,
      accountHint: parsed.accountHint,
      referenceId: parsed.referenceId,
      sourceApp: parsed.sourceApp,
      sourceAddress: parsed.sourceAddress,
    );
    return id;
  }

  @override
  Future<void> mergeInto(int existingId, ParsedTransaction parsed) async {
    final existing = rows[existingId]!;
    final sources = existing.sourceList.toSet()..add(parsed.sourceType.name);
    rows[existingId] = domain.Transaction(
      id: existing.id,
      amountPaise: existing.amountPaise,
      type: existing.type,
      occurredAt: existing.occurredAt,
      receivedAt: existing.receivedAt,
      mergedSources: sources.join(','),
      rawText: existing.rawText,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      merchantName: existing.merchantName ?? parsed.merchantName,
      upiId: existing.upiId ?? parsed.upiId,
      bankName: existing.bankName ?? parsed.bankName,
      accountHint: existing.accountHint ?? parsed.accountHint,
      referenceId: existing.referenceId ?? parsed.referenceId,
      sourceApp: existing.sourceApp ?? parsed.sourceApp,
      sourceAddress: existing.sourceAddress ?? parsed.sourceAddress,
    );
  }

  @override
  Future<domain.Transaction?> getById(int id) async => rows[id];

  @override
  Future<List<domain.Transaction>> findByReferenceId(String referenceId) async =>
      rows.values.where((t) => t.referenceId == referenceId).toList();

  @override
  Future<List<domain.Transaction>> findByAmountNear(int amountPaise, DateTime around, Duration window) async {
    final from = around.subtract(window);
    final to = around.add(window);
    return rows.values
        .where((t) => t.amountPaise == amountPaise && !t.occurredAt.isBefore(from) && !t.occurredAt.isAfter(to))
        .toList();
  }

  @override
  Future<void> logCapture({
    required String sourceType,
    required String? origin,
    required String text,
    required String result,
    required DateTime at,
  }) async {
    captureLog.add(_CaptureLog(sourceType, origin, text, result, at));
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used by IngestionService');
}

/// Simulates a bug in a (current or future) parser to prove one broken
/// parser can't take down processing for every other message.
class _ThrowingParser implements TransactionParser {
  @override
  bool canHandle(RawEvent event) => true;

  @override
  ParsedTransaction? tryParse(RawEvent event) => throw StateError('simulated parser bug');
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
  
  @override
  Future<String?> getCategoryForMerchant(String merchantKey) async => null;
}

void main() {
  late _FakeRepository repo;
  late IngestionService service;
  final now = DateTime(2026, 1, 15, 12, 0);

  setUp(() {
    repo = _FakeRepository();
    service = IngestionService(
      parserRegistry: ParserRegistry(),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: _FakeCategoryRepository(),
    );
  });

  test('an unrecognizable message is ignored but still logged', () async {
    final result = await service.process(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Your OTP is 123456. Do not share it with anyone.',
      receivedAt: now,
    ));

    expect(result.outcome, IngestionOutcome.ignored);
    expect(repo.rows, isEmpty);
    expect(repo.captureLog, hasLength(1));
    expect(repo.captureLog.single.result, 'ignored');
  });

  test('a parser that throws degrades to ignored instead of propagating', () async {
    final throwingService = IngestionService(
      parserRegistry: ParserRegistry(parsers: [_ThrowingParser()]),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: _FakeCategoryRepository(),
    );

    final result = await throwingService.process(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'anything at all',
      receivedAt: now,
    ));

    expect(result.outcome, IngestionOutcome.ignored);
    expect(repo.rows, isEmpty);
    expect(repo.captureLog.single.result, contains('parser error'));
  });

  test('a recognizable SMS is parsed and inserted as a new transaction', () async {
    final result = await service.process(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.500.00 debited from A/c XX1234 on 15-01-26 to merchant@ybl '
          'UPI Ref No 302615478321 -HDFC Bank',
      receivedAt: now,
    ));

    expect(result.outcome, IngestionOutcome.inserted);
    expect(repo.rows, hasLength(1));
    expect(repo.rows[result.transactionId]!.amountPaise, 50000);
    expect(repo.captureLog.single.result, contains('parsed'));
  });

  test('the same payment arriving as SMS then notification merges into one row', () async {
    final smsResult = await service.process(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.250.00 debited from A/c XX1234 on 15-01-26 to shop@upi UPI '
          'Ref No 111122223333 -HDFC Bank',
      receivedAt: now,
    ));

    final notifResult = await service.process(RawEvent(
      sourceType: SourceType.notification,
      origin: 'com.google.android.apps.nbu.paisa.user',
      text: 'Payment successful | ₹250 paid to shop@upi',
      receivedAt: now.add(const Duration(seconds: 30)),
    ));

    expect(smsResult.outcome, IngestionOutcome.inserted);
    expect(notifResult.outcome, IngestionOutcome.merged);
    expect(notifResult.transactionId, smsResult.transactionId);
    expect(repo.rows, hasLength(1), reason: 'must not create a second row for the same payment');
    expect(repo.rows[smsResult.transactionId]!.sourceList, containsAll(['sms', 'notification']));
  });

  test('two genuinely separate transactions of the same amount stay separate', () async {
    final first = await service.process(RawEvent(
      sourceType: SourceType.notification,
      origin: 'com.phonepe.app',
      text: 'Payment successful | ₹100 paid to Tea Stall',
      receivedAt: now,
    ));

    final second = await service.process(RawEvent(
      sourceType: SourceType.notification,
      origin: 'com.phonepe.app',
      text: 'Payment successful | ₹100 paid to Coffee Shop',
      receivedAt: now.add(const Duration(seconds: 10)),
    ));

    expect(first.outcome, IngestionOutcome.inserted);
    expect(second.outcome, IngestionOutcome.inserted);
    expect(repo.rows, hasLength(2));
  });

  test('every event is captured, whether or not it produced a transaction', () async {
    await service.process(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.500.00 debited from A/c XX1234 to merchant@ybl',
      receivedAt: now,
    ));
    await service.process(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Your OTP is 999999.',
      receivedAt: now,
    ));

    expect(repo.captureLog, hasLength(2));
  });
}
