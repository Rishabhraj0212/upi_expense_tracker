class Expense {
  Expense({
    required this.id,
    required this.amountPaise,
    required this.payee,
    required this.payeeVpa,
    required this.upiRef,
    required this.app,
    required this.category,
    required this.note,
    required this.createdAt,
    required this.sources,
    required this.raw,
  });

  final int id;
  final int amountPaise;
  final String? payee;
  final String? payeeVpa;
  final String? upiRef;
  final String? app;
  final String? category;
  final String? note;
  final DateTime createdAt;
  final String sources;
  final String? raw;

  bool get isPending => category == null;

  String get title => payee ?? payeeVpa ?? 'UPI payment';

  factory Expense.fromMap(Map<dynamic, dynamic> m) => Expense(
        id: (m['id'] as num).toInt(),
        amountPaise: (m['amountPaise'] as num).toInt(),
        payee: m['payee'] as String?,
        payeeVpa: m['payeeVpa'] as String?,
        upiRef: m['upiRef'] as String?,
        app: m['app'] as String?,
        category: m['category'] as String?,
        note: m['note'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num).toInt()),
        sources: m['sources'] as String,
        raw: m['raw'] as String?,
      );
}

class Capture {
  Capture({required this.ts, required this.source, required this.origin, required this.text, required this.result});

  final DateTime ts;
  final String source;
  final String? origin;
  final String text;
  final String result;

  factory Capture.fromMap(Map<dynamic, dynamic> m) => Capture(
        ts: DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        source: m['source'] as String,
        origin: m['origin'] as String?,
        text: m['text'] as String,
        result: m['result'] as String,
      );
}
