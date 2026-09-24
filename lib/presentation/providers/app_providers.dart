import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/drift_category_repository.dart';
import '../../data/drift_transaction_repository.dart';
import '../../data/local/app_database.dart';
import '../../dedup/duplicate_detector.dart';
import '../../domain/models/transaction.dart' as domain;
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../ingestion/ingestion_service.dart';
import '../../ingestion/native_event_ingestion_controller.dart';
import '../../parsing/parser_registry.dart';
import '../../platform/native_bridge.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return DriftTransactionRepository(ref.watch(appDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return DriftCategoryRepository(ref.watch(appDatabaseProvider));
});

final parserRegistryProvider = Provider<ParserRegistry>((ref) => ParserRegistry());

final duplicateDetectorProvider = Provider<DuplicateDetector>((ref) {
  return DuplicateDetector(ref.watch(transactionRepositoryProvider));
});

final ingestionServiceProvider = Provider<IngestionService>((ref) {
  return IngestionService(
    parserRegistry: ref.watch(parserRegistryProvider),
    duplicateDetector: ref.watch(duplicateDetectorProvider),
    repository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
});

/// Reactive: emits a new list the instant the ingestion pipeline
/// inserts/merges a row, with no polling and no manual refresh.
final transactionsStreamProvider = StreamProvider<List<domain.Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

/// Not reactive (the capture log has no watch query yet) — screens that show
/// it should invalidate this after triggering an ingestion.
final capturesProvider = FutureProvider.autoDispose<List<CaptureLogEntry>>((ref) {
  return ref.watch(transactionRepositoryProvider).getCaptures(limit: 50);
});

final nativeBridgeProvider = Provider<NativeBridge>((ref) => NativeBridge());

/// Reading this provider starts (and keeps alive) a subscription that feeds
/// every captured SMS into the ingestion pipeline. Only delivers events
/// while this engine is attached (app open/backgrounded) — Milestone 8 adds
/// headless delivery for when the app is fully closed.
final smsIngestionControllerProvider = Provider<NativeEventIngestionController>((ref) {
  final controller = NativeEventIngestionController(
    events: ref.watch(nativeBridgeProvider).smsEvents,
    ingestionService: ref.watch(ingestionServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Same idea as [smsIngestionControllerProvider], for notifications from
/// known UPI apps (Kotlin's UpiNotificationListener filters to that set
/// before forwarding anything).
final notificationIngestionControllerProvider = Provider<NativeEventIngestionController>((ref) {
  final controller = NativeEventIngestionController(
    events: ref.watch(nativeBridgeProvider).notificationEvents,
    ingestionService: ref.watch(ingestionServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
