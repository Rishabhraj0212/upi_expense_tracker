import '../dedup/duplicate_detector.dart';
import '../domain/models/parsed_transaction.dart';
import '../domain/models/raw_event.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import '../parsing/parser_registry.dart';
import 'ingestion_result.dart';

/// Orchestrates a single [RawEvent] from either capture channel through the
/// whole pipeline: parse -> log -> dedup -> insert/merge.
///
/// This is the one place that ties Milestones 1-3 together; the native
/// bridge (Milestone 6/7) will call [process] for every SMS/notification it
/// captures, whether the app is in the foreground or running headless.
class IngestionService {
  IngestionService({
    required ParserRegistry parserRegistry,
    required DuplicateDetector duplicateDetector,
    required TransactionRepository repository,
    required CategoryRepository categoryRepository,
  })  : _parserRegistry = parserRegistry,
        _duplicateDetector = duplicateDetector,
        _repository = repository,
        _categoryRepository = categoryRepository;

  final ParserRegistry _parserRegistry;
  final DuplicateDetector _duplicateDetector;
  final TransactionRepository _repository;
  final CategoryRepository _categoryRepository;

  Future<IngestionResult> process(RawEvent event) async {
    ParsedTransaction? parsed;
    try {
      parsed = _parserRegistry.parse(event);
    } catch (e) {
      // A bug in one parser (current or, as more banks/apps are added,
      // future) must not take down the whole pipeline for every other
      // message — degrade to "ignored" but keep the failure visible.
      await _repository.logCapture(
        sourceType: event.sourceType.name,
        origin: event.origin,
        text: event.text,
        result: 'parser error: $e',
        at: event.receivedAt,
      );
      return const IngestionResult.ignored();
    }

    // Every event is logged, parsed or not — this is what lets the parser
    // rules get tuned against real messages later without AI involved.
    await _repository.logCapture(
      sourceType: event.sourceType.name,
      origin: event.origin,
      text: event.text,
      result: parsed == null ? 'ignored' : 'parsed ₹${parsed.amountPaise / 100} (${parsed.type.name})',
      at: event.receivedAt,
    );

    if (parsed == null) return const IngestionResult.ignored();

    final duplicate = await _duplicateDetector.findDuplicate(parsed);
    final id = duplicate != null ? duplicate.id : await _repository.insert(parsed);
    
    if (duplicate != null) {
      await _repository.mergeInto(duplicate.id, parsed);
    }
    
    // Check for memory/rule matches before returning
    final merchantKey = parsed.merchantName ?? parsed.upiId;
    if (merchantKey != null && merchantKey.isNotEmpty) {
      final category = await _categoryRepository.getCategoryForMerchant(merchantKey);
      if (category != null) {
        // If this is a new transaction (duplicate == null), or if it's a duplicate but
        // its existing category is still null, set the category.
        final tx = await _repository.getById(id);
        if (tx != null && tx.category == null) {
          await _repository.setCategory(id, category, tx.note);
        }
      }
    }

    if (duplicate != null) {
      return IngestionResult.merged(duplicate.id, parsed);
    }
    return IngestionResult.inserted(id, parsed);
  }
}
