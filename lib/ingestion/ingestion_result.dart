import '../domain/models/parsed_transaction.dart';

enum IngestionOutcome {
  /// The raw text wasn't a recognizable completed transaction.
  ignored,

  /// A brand-new transaction row was created.
  inserted,

  /// The parsed transaction was the same payment as an existing row, which
  /// was updated in place instead of creating a duplicate.
  merged,
}

class IngestionResult {
  const IngestionResult._(this.outcome, this.transactionId, this.parsed);

  const IngestionResult.ignored() : this._(IngestionOutcome.ignored, null, null);

  IngestionResult.inserted(int id, ParsedTransaction parsed) : this._(IngestionOutcome.inserted, id, parsed);

  IngestionResult.merged(int id, ParsedTransaction parsed) : this._(IngestionOutcome.merged, id, parsed);

  final IngestionOutcome outcome;
  final int? transactionId;
  final ParsedTransaction? parsed;
}
