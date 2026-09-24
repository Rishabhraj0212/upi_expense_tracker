import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/drift_category_repository.dart';
import '../data/drift_transaction_repository.dart';
import '../data/local/app_database.dart';
import '../dedup/duplicate_detector.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import '../ingestion/ingestion_service.dart';
import '../parsing/parser_registry.dart';
import '../platform/native_bridge.dart';

const _headlessChannel = MethodChannel('upi_tracker/headless');

/// Entrypoint for the background FlutterEngine Kotlin's HeadlessEngineManager
/// spins up when a captured SMS/notification arrives with no live listener
/// (the app isn't running). Deliberately independent of the main app's
/// Riverpod graph — this builds its own instance of the same pipeline used
/// by [smsIngestionControllerProvider]/[notificationIngestionControllerProvider],
/// pointed at the same on-disk database, and processes exactly one queued
/// event per "ingest" call before the engine that hosts it is torn down.
///
/// Must stay a top-level (or static) function taking no arguments for
/// `PluginUtilities.getCallbackHandle` to resolve it — see
/// headless_registration.dart. The actual logic lives in
/// [runBackgroundIngestion] so it can be exercised in tests with a fake
/// channel and an in-memory database.
@pragma('vm:entry-point')
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  runBackgroundIngestion(
    channel: _headlessChannel,
    buildRepository: () => DriftTransactionRepository(db),
    buildCategoryRepository: () => DriftCategoryRepository(db),
  );
}

void runBackgroundIngestion({
  required MethodChannel channel,
  required TransactionRepository Function() buildRepository,
  required CategoryRepository Function() buildCategoryRepository,
}) {
  final repository = buildRepository();
  final ingestionService = IngestionService(
    parserRegistry: ParserRegistry(),
    duplicateDetector: DuplicateDetector(repository),
    repository: repository,
    categoryRepository: buildCategoryRepository(),
  );

  channel.setMethodCallHandler((call) async {
    if (call.method != 'ingest') return null;
    final event = headlessRawEventFromArguments(call.arguments);
    if (event != null) await ingestionService.process(event);
    return null;
  });

  channel.invokeMethod('ready');
}
