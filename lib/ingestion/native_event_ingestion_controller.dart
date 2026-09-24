import 'dart:async';

import '../domain/models/raw_event.dart';
import 'ingestion_service.dart';

/// Subscribes to a stream of captured raw events (from the native bridge)
/// and feeds each one through [IngestionService]. A malformed payload or a
/// transient failure is swallowed rather than crashing the app — every
/// attempt is still visible later via the capture log.
class NativeEventIngestionController {
  NativeEventIngestionController({
    required Stream<RawEvent> events,
    required IngestionService ingestionService,
  }) {
    _subscription = events.listen(
      (event) => _processSafely(ingestionService, event),
      onError: (Object _, StackTrace __) {},
    );
  }

  late final StreamSubscription<RawEvent> _subscription;

  void dispose() => _subscription.cancel();

  /// `stream.listen((event) => someAsyncFunction(event))` does not await the
  /// callback's returned Future, so an error thrown after the first `await`
  /// inside [IngestionService.process] would otherwise become an unhandled
  /// async error rather than something [onError] above can see. Awaiting
  /// and catching here keeps one bad event from affecting the next one.
  Future<void> _processSafely(IngestionService ingestionService, RawEvent event) async {
    try {
      await ingestionService.process(event);
    } catch (_) {
      // Already logged (or attempted to be) inside IngestionService; nothing
      // further to do here except not let it propagate unhandled.
    }
  }
}
