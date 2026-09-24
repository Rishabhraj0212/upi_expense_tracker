import '../../domain/models/parsed_transaction.dart';
import '../../domain/models/raw_event.dart';
import '../../domain/models/transaction_source.dart';
import '../../domain/models/transaction_type.dart';
import '../common/text_extractors.dart';
import '../common/text_normalizer.dart';
import '../transaction_parser.dart';
import 'upi_apps.dart';

/// Parses payment notifications from known UPI apps (see [upiNotificationApps]).
/// Notifications rarely carry a separate transaction timestamp in their text,
/// so [ParsedTransaction.occurredAt] falls back to when the notification
/// arrived on the device.
class GenericUpiNotificationParser implements TransactionParser {
  static final RegExp _debitRx = RegExp(
    r'\b(?:paid|sent|debited|payment (?:of )?(?:rs\.?|inr|₹)?\s*[\d,.]+\s+(?:is )?successful)\b',
    caseSensitive: false,
  );

  static final RegExp _creditRx = RegExp(
    r'\b(?:received|credited|money received)\b',
    caseSensitive: false,
  );

  /// Wording that means this is not a completed transaction.
  static final RegExp _rejectRx = RegExp(
    r'\b(?:requested|request for|fail(?:ed|ure)?|declined|pending|reminder|'
    r'due|offer|reward|scratch card|won|get up to)\b',
    caseSensitive: false,
  );

  static final RegExp _toRx = RegExp(
    r'\bto\s+([^\n.!,(]{2,40}?)(?=\s+(?:on|via|using|from|with|successfully|ref|utr|rrn)\b|[.!,(\n]|$)',
    caseSensitive: false,
  );

  static final RegExp _fromRx = RegExp(
    r'\bfrom\s+([^\n.!,(]{2,40}?)(?=\s+(?:on|via|using|with|successfully|ref|utr|rrn)\b|[.!,(\n]|$)',
    caseSensitive: false,
  );

  @override
  bool canHandle(RawEvent event) =>
      event.sourceType == SourceType.notification && upiNotificationApps.containsKey(event.origin);

  @override
  ParsedTransaction? tryParse(RawEvent event) {
    final text = normalizeMessageText(event.text);
    if (_rejectRx.hasMatch(text)) return null;

    final isDebit = _debitRx.hasMatch(text);
    final isCredit = _creditRx.hasMatch(text);
    if (isDebit == isCredit) return null;

    final amountPaise = TextExtractors.extractAmountPaise(text);
    if (amountPaise == null) return null;

    final vpa = TextExtractors.extractVpa(text);
    final nameMatch = (isDebit ? _toRx : _fromRx).firstMatch(text)?.group(1);
    final name = TextExtractors.cleanName(nameMatch, vpa);

    return ParsedTransaction(
      amountPaise: amountPaise,
      type: isDebit ? TransactionType.debit : TransactionType.credit,
      occurredAt: event.receivedAt,
      sourceType: SourceType.notification,
      rawText: event.text,
      merchantName: name,
      upiId: vpa,
      referenceId: TextExtractors.extractReferenceId(text),
      sourceApp: upiNotificationApps[event.origin],
    );
  }
}
