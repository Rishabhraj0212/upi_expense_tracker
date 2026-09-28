/// Shared regex-based field extraction used by every parser. Pure text in,
/// pure values out — no Flutter/Android dependency, fully unit-testable.
class TextExtractors {
  TextExtractors._();

  static final RegExp _amountRx = RegExp(
    r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  /// Words that mean the nearby amount is a balance/limit, not the
  /// transaction amount itself (e.g. "Avl Bal Rs.4,500.00", or the equally
  /// common concatenated form "AvlBal:Rs.4,500.00" — no trailing \b here
  /// deliberately, since "Bal" immediately follows "Avl" with no boundary
  /// between them in that form).
  static final RegExp _balanceContextRx = RegExp(
    r'\b(?:avl|avail(?:able)?|clr|clear|bal(?:ance)?|limit)',
    caseSensitive: false,
  );

  /// The first amount in [text] that isn't immediately preceded by balance
  /// wording, converted to paise (integer, no float rounding surprises).
  static int? extractAmountPaise(String text) {
    for (final m in _amountRx.allMatches(text)) {
      final lookbackStart = (m.start - 20).clamp(0, text.length);
      final before = text.substring(lookbackStart, m.start);
      if (_balanceContextRx.hasMatch(before)) continue;

      final raw = m.group(1)!.replaceAll(',', '');
      final value = double.tryParse(raw);
      if (value == null || value <= 0) continue;
      return (value * 100).round();
    }
    return null;
  }

  static final RegExp _vpaRx = RegExp(r'[\w.\-]{2,}@[a-zA-Z][a-zA-Z0-9]{1,}');

  static String? extractVpa(String text) => _vpaRx.firstMatch(text)?.group(0);

  static final RegExp _refRx = RegExp(
    r'\b(?:ref(?:erence)?\.?\s*(?:no\.?)?|utr|rrn)\s*[:\-#]?\s*(\d{9,16})',
    caseSensitive: false,
  );

  static String? extractReferenceId(String text) => _refRx.firstMatch(text)?.group(1);

  static final RegExp _acctRx = RegExp(
    r'\b(?:a/c|acc(?:t|ount)?)\.?\s*(?:no\.?\s*)?([Xx*]{1,}\d{2,6}|\d{4,6})\b',
    caseSensitive: false,
  );

  static String? extractAccountHint(String text) => _acctRx.firstMatch(text)?.group(1)?.toUpperCase();

  /// Extracts the account balance from text — the complement of
  /// [extractAmountPaise]. Returns the first Rs/INR/₹ amount that IS
  /// preceded by balance wording (e.g. "Avl Bal Rs.12,345.00"), in paise.
  static int? extractBalancePaise(String text) {
    for (final m in _amountRx.allMatches(text)) {
      final lookbackStart = (m.start - 20).clamp(0, text.length);
      final before = text.substring(lookbackStart, m.start);
      if (!_balanceContextRx.hasMatch(before)) continue;

      final raw = m.group(1)!.replaceAll(',', '');
      final value = double.tryParse(raw);
      if (value == null || value < 0) continue;
      return (value * 100).round();
    }
    return null;
  }

  /// Drops a captured name if it's just a truncated prefix of the VPA
  /// (regex name-matching stops at '@', so "from shop@upi" can otherwise
  /// yield the useless partial name "shop").
  static String? cleanName(String? name, String? vpa) {
    if (name == null || name.trim().isEmpty) return null;
    final trimmed = name.trim();
    if (vpa != null && vpa.toLowerCase().startsWith(trimmed.toLowerCase())) return null;
    return trimmed;
  }
}
