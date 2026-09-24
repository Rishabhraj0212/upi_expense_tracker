import '../domain/models/parsed_transaction.dart';
import '../domain/models/raw_event.dart';

/// Strategy interface for one parsing ruleset (a specific bank's SMS format,
/// a specific UPI app's notification format, or a broad fallback).
///
/// Implementations are pure Dart: regex/keyword rules only, no AI, no
/// Flutter/Android dependency, so they run in `flutter test` on the host.
abstract class TransactionParser {
  /// Cheap pre-check (source type + sender/package) run before the more
  /// expensive regex work in [tryParse].
  bool canHandle(RawEvent event);

  /// Returns a parsed transaction, or null if the message isn't a
  /// recognizable completed debit/credit (OTP, promo, pending request,
  /// failed payment, balance alert, etc. all yield null).
  ParsedTransaction? tryParse(RawEvent event);
}
