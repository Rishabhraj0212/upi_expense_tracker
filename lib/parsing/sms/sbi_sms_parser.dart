import '../../domain/models/parsed_transaction.dart';
import '../../domain/models/raw_event.dart';
import '../../domain/models/transaction_source.dart';
import '../../domain/models/transaction_type.dart';
import '../common/month_names.dart';
import '../common/text_extractors.dart';
import '../common/text_normalizer.dart';
import '../transaction_parser.dart';

/// SBI's UPI SMS template breaks several assumptions the generic parser
/// relies on:
///   "Dear UPI user A/C X1234 debited by 500.0 on date 12Jan24 trf to
///    merchant@ybl Refno 302615478321. If not u? call 1800111109 -SBI"
/// - no "Rs./INR/₹" before the amount ("debited by 500.0", not "Rs.500.0")
/// - "Refno" has no space before the digits
/// - the date has no separator at all ("12Jan24")
/// This is exactly the kind of quirk the architecture is meant to isolate:
/// one small parser, tried before the generic fallback.
class SbiSmsParser implements TransactionParser {
  static final RegExp _debitRx = RegExp(r'debited\s+by\s+([\d,]+(?:\.\d+)?)', caseSensitive: false);
  static final RegExp _creditRx = RegExp(r'credited\s+by\s+([\d,]+(?:\.\d+)?)', caseSensitive: false);

  static final RegExp _refRx = RegExp(r'ref\s*no\.?\s*(\d{9,16})', caseSensitive: false);

  static final RegExp _dateRx = RegExp(
    r'\bon\s+date\s+(\d{1,2})(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(\d{2,4})\b',
    caseSensitive: false,
  );

  static final RegExp _trfToRx = RegExp(
    r'trf\s+to\s+([^\s][^.]{1,40}?)(?=\s+ref\s*no|\.|$)',
    caseSensitive: false,
  );

  @override
  bool canHandle(RawEvent event) =>
      event.sourceType == SourceType.sms && event.origin.toUpperCase().contains('SBI');

  @override
  ParsedTransaction? tryParse(RawEvent event) {
    final text = normalizeMessageText(event.text);

    final debitMatch = _debitRx.firstMatch(text);
    final creditMatch = _creditRx.firstMatch(text);
    if (debitMatch == null && creditMatch == null) return null;

    final match = debitMatch ?? creditMatch!;
    final amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    final vpa = TextExtractors.extractVpa(text);
    final name = TextExtractors.cleanName(_trfToRx.firstMatch(text)?.group(1), vpa);

    return ParsedTransaction(
      amountPaise: (amount * 100).round(),
      type: debitMatch != null ? TransactionType.debit : TransactionType.credit,
      occurredAt: _extractDate(text) ?? event.receivedAt,
      sourceType: SourceType.sms,
      rawText: event.text,
      merchantName: name,
      upiId: vpa,
      bankName: 'State Bank of India',
      accountHint: TextExtractors.extractAccountHint(text),
      referenceId: _refRx.firstMatch(text)?.group(1),
      sourceAddress: event.origin,
      balancePaise: TextExtractors.extractBalancePaise(text),
      note: TextExtractors.extractNote(text),
    );
  }

  static DateTime? _extractDate(String text) {
    final m = _dateRx.firstMatch(text);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    final month = monthAbbreviations[m.group(2)!.toLowerCase()];
    if (month == null) return null;
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    return DateTime(year, month, day);
  }
}
