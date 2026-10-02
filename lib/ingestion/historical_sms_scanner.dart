import 'dart:async';

import '../ingestion/ingestion_result.dart';
import '../ingestion/ingestion_service.dart';
import '../platform/sms_inbox_reader.dart';

/// Progress snapshot emitted while a historical SMS scan is running.
class ScanProgress {
  const ScanProgress({
    required this.totalMessages,
    required this.processedMessages,
    required this.transactionsFound,
    required this.newTransactions,
    required this.duplicates,
    required this.failed,
  });

  final int totalMessages;
  final int processedMessages;
  final int transactionsFound;
  final int newTransactions;
  final int duplicates;
  final int failed;

  bool get isComplete => processedMessages >= totalMessages;
}

/// Final result of a completed scan.
class ScanResult {
  const ScanResult({
    required this.totalMessages,
    required this.transactionsFound,
    required this.newTransactions,
    required this.duplicates,
    required this.failed,
    required this.duration,
  });

  final int totalMessages;
  final int transactionsFound;
  final int newTransactions;
  final int duplicates;
  final int failed;
  final Duration duration;
}

/// Scans historical SMS from the Android inbox, feeds each through the
/// existing [IngestionService] pipeline (parse → dedup → insert/merge), and
/// reports progress as it goes.
///
/// The scanner is an *additional input source* into the existing pipeline —
/// it does not create a second parser or a second ingestion path. Messages
/// that have already been captured in real time are automatically handled
/// by the existing [DuplicateDetector] and appear as duplicates.
class HistoricalSmsScanner {
  HistoricalSmsScanner({
    required SmsInboxReader smsInboxReader,
    required IngestionService ingestionService,
  })  : _smsInboxReader = smsInboxReader,
        _ingestionService = ingestionService;

  final SmsInboxReader _smsInboxReader;
  final IngestionService _ingestionService;

  /// Batch size for reading SMS from the content provider.
  static const _batchSize = 100;

  bool _running = false;
  bool get isRunning => _running;

  /// Runs a full scan of the SMS inbox within [since] .. [until].
  ///
  /// [onProgress] is called after each batch with the current progress.
  /// A malformed or unsupported SMS never stops the scan — it's counted
  /// as ignored/failed and processing continues.
  ///
  /// Throws [StateError] if a scan is already running.
  Future<ScanResult> scan({
    required DateTime since,
    required DateTime until,
    void Function(ScanProgress progress)? onProgress,
  }) async {
    if (_running) {
      throw StateError('A scan is already in progress');
    }
    _running = true;
    final stopwatch = Stopwatch()..start();

    try {
      final totalMessages = await _smsInboxReader.getCount(
        since: since,
        until: until,
      );

      int processed = 0;
      int transactionsFound = 0;
      int newTransactions = 0;
      int duplicates = 0;
      int failed = 0;

      void emitProgress() {
        onProgress?.call(ScanProgress(
          totalMessages: totalMessages,
          processedMessages: processed,
          transactionsFound: transactionsFound,
          newTransactions: newTransactions,
          duplicates: duplicates,
          failed: failed,
        ));
      }

      // Emit initial progress immediately (0 / N)
      emitProgress();

      int offset = 0;
      while (offset < totalMessages) {
        final batch = await _smsInboxReader.readBatch(
          since: since,
          until: until,
          offset: offset,
          limit: _batchSize,
        );

        if (batch.isEmpty) break;

        for (final event in batch) {
          try {
            final result = await _ingestionService.process(event);
            switch (result.outcome) {
              case IngestionOutcome.inserted:
                transactionsFound++;
                newTransactions++;
              case IngestionOutcome.merged:
                transactionsFound++;
                duplicates++;
              case IngestionOutcome.ignored:
                break; // Not a transaction — normal
            }
          } catch (_) {
            failed++;
          }
          processed++;
        }

        emitProgress();

        offset += batch.length;

        // Yield to the UI thread between batches so progress updates render.
        await Future<void>.delayed(Duration.zero);
      }

      stopwatch.stop();
      return ScanResult(
        totalMessages: totalMessages,
        transactionsFound: transactionsFound,
        newTransactions: newTransactions,
        duplicates: duplicates,
        failed: failed,
        duration: stopwatch.elapsed,
      );
    } finally {
      _running = false;
    }
  }
}
