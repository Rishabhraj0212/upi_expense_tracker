import '../../domain/models/parsed_transaction.dart';
import '../../domain/models/raw_event.dart';
import '../../domain/models/transaction_source.dart';
import '../../domain/models/transaction_type.dart';
import '../common/bank_directory.dart';
import '../common/date_extractors.dart';
import '../common/text_extractors.dart';
import '../common/text_normalizer.dart';
import '../transaction_parser.dart';

/// Fallback/general-purpose SMS parser. Covers the common template shared by
/// most Indian banks: "verb, amount, A/c, to/from name or VPA, ref". Bank-
/// specific parsers (e.g. `SbiSmsParser`) run before this one and only need
/// to exist where a bank's wording breaks these assumptions.
class GenericUpiSmsParser implements TransactionParser {
  static const _acct = r'(?:a/c|acc(?:t|ount)?|card)';

  /// A debit/credit word "anywhere" in the message — the original signal,
  /// kept as a fallback for phrasing that never mentions an account at all.
  static final RegExp _debitRx = RegExp(
    r'\b(?:debited|debit|dr\.?|withdrawn|spent|paid)\b',
    caseSensitive: false,
  );

  static final RegExp _creditRx = RegExp(
    r'\b(?:credited|credit|cr\.?|received)\b',
    caseSensitive: false,
  );

  /// A debit/credit word specifically tied to *your* account/card — either
  /// "debited from your A/c" (verb first) or "A/c X ... debited" (account
  /// first). This is what actually distinguishes direction: many banks
  /// (Bank of Baroda among them) phrase a single debit as "Dr. from A/c X
  /// and Cr. to VPA Y", where "Cr." describes the *payee's* side, not yours.
  /// Treating bare keyword presence as ambiguous there was a real bug — this
  /// message would otherwise be silently dropped.
  static final RegExp _debitNearAccountRx = RegExp(
    r'\b(?:dr|debited|debit)\b\.?(?:\s+(?:from|by|in|of))?\s*(?:your\s+)?' + _acct + r'\b' +
        r'|\b' + _acct + r'\.?\s*(?:no\.?\s*)?[Xx*\d]*\s*(?:is\s+|has\s+been\s+)?debited\b',
    caseSensitive: false,
  );

  static final RegExp _creditNearAccountRx = RegExp(
    r'\b(?:cr|credited|credit)\b\.?(?:\s+(?:to|in|by))?\s*(?:your\s+)?' + _acct + r'\b' +
        r'|\b' + _acct + r'\.?\s*(?:no\.?\s*)?[Xx*\d]*\s*(?:is\s+|has\s+been\s+)?credited\b',
    caseSensitive: false,
  );

  /// Wording that means this is not a completed transaction: an OTP, a
  /// promo, a pending due, a failed/declined attempt, etc.
  static final RegExp _rejectRx = RegExp(
    r'\b(?:otp|one time password|will be debited|due|emi|offer|cashback|'
    r'lucky draw|win up to|failed|declined|requested|reminder|'
    r'expir(?:e|y|ing)|block(?:ed)? (?:your )?card)\b',
    caseSensitive: false,
  );

  static final RegExp _payeeNameRx = RegExp(
    r'\b(?:trf to|transfer(?:red)? to|paid to|sent to|towards|to)\s+'
    r"([A-Za-z][A-Za-z0-9 &.\-']{1,40}?)"
    r'(?=\s+(?:on|ref|upi|utr|via|from|dt)\b|[.,(]|$)',
    caseSensitive: false,
  );

  static final RegExp _payerNameRx = RegExp(
    r'\bfrom\s+'
    r"([A-Za-z][A-Za-z0-9 &.\-']{1,40}?)"
    r'(?=\s+(?:on|ref|upi|utr|via|dt)\b|[.,(]|$)',
    caseSensitive: false,
  );

  @override
  bool canHandle(RawEvent event) => event.sourceType == SourceType.sms;

  @override
  ParsedTransaction? tryParse(RawEvent event) {
    final text = normalizeMessageText(event.text);
    if (_rejectRx.hasMatch(text)) return null;

    final isDebit = _resolveDirection(text);
    if (isDebit == null) return null;

    final amountPaise = TextExtractors.extractAmountPaise(text);
    if (amountPaise == null) return null;

    final vpa = TextExtractors.extractVpa(text);
    final nameMatch = (isDebit ? _payeeNameRx : _payerNameRx).firstMatch(text)?.group(1);
    final name = TextExtractors.cleanName(nameMatch, vpa);

    return ParsedTransaction(
      amountPaise: amountPaise,
      type: isDebit ? TransactionType.debit : TransactionType.credit,
      occurredAt: DateExtractors.extractDateTime(text, event.receivedAt),
      sourceType: SourceType.sms,
      rawText: event.text,
      merchantName: name,
      upiId: vpa,
      bankName: BankDirectory.fromSenderId(event.origin),
      accountHint: TextExtractors.extractAccountHint(text),
      referenceId: TextExtractors.extractReferenceId(text),
      sourceAddress: event.origin,
    );
  }

  /// true = debit, false = credit, null = couldn't tell / genuinely ambiguous.
  bool? _resolveDirection(String text) {
    final debitNearAccount = _debitNearAccountRx.hasMatch(text);
    final creditNearAccount = _creditNearAccountRx.hasMatch(text);
    if (debitNearAccount != creditNearAccount) return debitNearAccount;
    if (debitNearAccount && creditNearAccount) return null; // both your account debited and credited: unclear

    // Neither could be tied to an account/card mention (unusual phrasing) —
    // fall back to bare keyword presence anywhere in the message.
    final bareDebit = _debitRx.hasMatch(text);
    final bareCredit = _creditRx.hasMatch(text);
    if (bareDebit == bareCredit) return null;
    return bareDebit;
  }
}
