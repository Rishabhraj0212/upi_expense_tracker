import 'transaction_source.dart';
import 'transaction_type.dart';

/// Output of a parser: a transaction extracted from a [RawEvent], before
/// duplicate detection or persistence.
class ParsedTransaction {
  const ParsedTransaction({
    required this.amountPaise,
    required this.type,
    required this.occurredAt,
    required this.sourceType,
    required this.rawText,
    this.merchantName,
    this.upiId,
    this.bankName,
    this.accountHint,
    this.referenceId,
    this.sourceApp,
    this.sourceAddress,
    this.balancePaise,
    this.note,
  });

  final int amountPaise;
  final TransactionType type;

  /// Best-effort transaction time parsed from the message; callers should
  /// fall back to the event's receivedAt when the message has no timestamp.
  final DateTime occurredAt;

  final String? merchantName;
  final String? upiId;
  final String? bankName;
  final String? accountHint;
  final String? referenceId;

  final SourceType sourceType;
  final String? sourceApp;
  final String? sourceAddress;

  final String rawText;

  /// Account balance reported in the SMS (e.g. "Avl Bal Rs.12,345.00"),
  /// in paise. Null if the message doesn't include balance info.
  final int? balancePaise;

  /// Optional remark, note, or purpose of payment extracted from notification/SMS.
  final String? note;
}
