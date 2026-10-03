import '../domain/models/parsed_transaction.dart';
import '../domain/models/raw_event.dart';
import 'notification/generic_upi_notification_parser.dart';
import 'sms/generic_upi_sms_parser.dart';
import 'sms/bank_startement_parser.dart';
import 'transaction_parser.dart';

/// Tries each registered [TransactionParser] in order and returns the first
/// successful parse. Order matters: bank/app-specific parsers should come
/// before generic fallbacks so their more precise rules win.
///
/// Adding support for a new bank or app is a one-line addition to
/// [defaultParsers] plus a new parser class — nothing else changes.
class ParserRegistry {
  ParserRegistry({List<TransactionParser>? parsers})
    : _parsers = parsers ?? defaultParsers();

  final List<TransactionParser> _parsers;

  static List<TransactionParser> defaultParsers() => [
    SbiSmsParser(),
    GenericUpiSmsParser(),
    GenericUpiNotificationParser(),
  ];

  ParsedTransaction? parse(RawEvent event) {
    for (final parser in _parsers) {
      if (!parser.canHandle(event)) continue;
      final result = parser.tryParse(event);
      if (result != null) return result;
    }
    return null;
  }
}
