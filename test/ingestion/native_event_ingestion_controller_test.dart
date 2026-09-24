import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/dedup/duplicate_detector.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/raw_event.dart';
import 'package:upi_expense_tracker/domain/models/transaction.dart' as domain;
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:upi_expense_tracker/domain/repositories/category_repository.dart';
import 'package:upi_expense_tracker/ingestion/ingestion_service.dart';
import 'package:upi_expense_tracker/ingestion/native_event_ingestion_controller.dart';
import 'package:upi_expense_tracker/parsing/parser_registry.dart';

/// Same minimal fake shape used in ingestion_service_test.dart.
class _FakeRepository implements TransactionRepository {
  final Map<int, domain.Transaction> rows = {};
  int _nextId = 1;

  /// Lets a test simulate a failure deep in processing (as opposed to a
  /// stream-level error), to prove it doesn't take down the listener.
  int? throwOnInsertForAmount;

  @override
  Future<int> insert(ParsedTransaction parsed) async {
    if (parsed.amountPaise == throwOnInsertForAmount) {
      throw StateError('simulated insert failure');
    }
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
  Future<List<domain.Transaction>> findByReferenceId(String referenceId) async => [];

  @override
  Future<List<domain.Transaction>> findByAmountNear(int amountPaise, DateTime around, Duration window) async => [];

  @override
  Future<void> logCapture({
    required String sourceType,
    required String? origin,
    required String text,
    required String result,
    required DateTime at,
  }) async {}

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<String?> getCategoryForMerchant(String merchantKey) async => null;
}

void main() {
  test('works the same for notification-sourced events (the controller is source-agnostic)', () async {
    final repo = _FakeRepository();
    final service = IngestionService(
      parserRegistry: ParserRegistry(),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: _FakeCategoryRepository(),
    );
    final controller = StreamController<RawEvent>();
    final ingestionController = NativeEventIngestionController(events: controller.stream, ingestionService: service);
    addTearDown(ingestionController.dispose);
    addTearDown(controller.close);

    controller.add(RawEvent(
      sourceType: SourceType.notification,
      origin: 'com.phonepe.app',
      text: 'Payment successful | ₹250 paid to Tea Stall',
      receivedAt: DateTime(2026, 1, 15),
    ));
    await Future<void>.delayed(Duration.zero);

    expect(repo.rows, hasLength(1));
    expect(repo.rows.values.single.amountPaise, 25000);
  });

  test('each event emitted by the stream is processed through the pipeline', () async {
    final repo = _FakeRepository();
    final service = IngestionService(
      parserRegistry: ParserRegistry(),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: _FakeCategoryRepository(),
    );
    final controller = StreamController<RawEvent>();
    final ingestionController = NativeEventIngestionController(events: controller.stream, ingestionService: service);
    addTearDown(ingestionController.dispose);
    addTearDown(controller.close);

    controller.add(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.500.00 debited from A/c XX1234 to merchant@ybl UPI Ref No 302615478321',
      receivedAt: DateTime(2026, 1, 15),
    ));
    await Future<void>.delayed(Duration.zero);

    expect(repo.rows, hasLength(1));
    expect(repo.rows.values.single.amountPaise, 50000);
  });

  test('an error on the stream is swallowed, not thrown', () async {
    final repo = _FakeRepository();
    final service = IngestionService(
      parserRegistry: ParserRegistry(),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: _FakeCategoryRepository(),
    );
    final controller = StreamController<RawEvent>();
    final ingestionController = NativeEventIngestionController(events: controller.stream, ingestionService: service);
    addTearDown(ingestionController.dispose);
    addTearDown(controller.close);

    controller.addError(Exception('malformed platform payload'));
    await Future<void>.delayed(Duration.zero);

    // Reaching here at all (no uncaught async error) is the assertion.
    controller.add(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.100.00 debited from A/c XX1234 to shop@ybl UPI Ref No 111122223333',
      receivedAt: DateTime(2026, 1, 15),
    ));
    await Future<void>.delayed(Duration.zero);

    expect(repo.rows, hasLength(1));
  });

  test('an exception thrown deep in processing (not just a stream error) does not stop later events', () async {
    final repo = _FakeRepository()..throwOnInsertForAmount = 50000;
    final service = IngestionService(
      parserRegistry: ParserRegistry(),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: _FakeCategoryRepository(),
    );
    final controller = StreamController<RawEvent>();
    final ingestionController = NativeEventIngestionController(events: controller.stream, ingestionService: service);
    addTearDown(ingestionController.dispose);
    addTearDown(controller.close);

    // This one throws inside insert() — after parsing and logging have
    // already completed, well past anything a stream-level onError could
    // ever see. Before the fix, this would have become an unhandled async
    // error (the .listen() callback's returned Future was never awaited).
    controller.add(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.500.00 debited from A/c XX1234 to merchant@ybl UPI Ref No 302615478321',
      receivedAt: DateTime(2026, 1, 15),
    ));
    await Future<void>.delayed(Duration.zero);

    // A different amount, not configured to throw, must still go through.
    controller.add(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.100.00 debited from A/c XX1234 to shop@ybl UPI Ref No 111122223333',
      receivedAt: DateTime(2026, 1, 15),
    ));
    await Future<void>.delayed(Duration.zero);

    // Reaching here at all, with the test framework reporting no unhandled
    // error, is as much the assertion as the row count below.
    expect(repo.rows, hasLength(1));
    expect(repo.rows.values.single.amountPaise, 10000);
  });

  test('dispose stops further processing', () async {
    final repo = _FakeRepository();
    final service = IngestionService(
      parserRegistry: ParserRegistry(),
      duplicateDetector: DuplicateDetector(repo),
      repository: repo,
      categoryRepository: _FakeCategoryRepository(),
    );
    final controller = StreamController<RawEvent>();
    final ingestionController = NativeEventIngestionController(events: controller.stream, ingestionService: service);
    addTearDown(controller.close);

    ingestionController.dispose();

    controller.add(RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.500.00 debited from A/c XX1234 to merchant@ybl UPI Ref No 302615478321',
      receivedAt: DateTime(2026, 1, 15),
    ));
    await Future<void>.delayed(Duration.zero);

    expect(repo.rows, isEmpty);
  });
}
