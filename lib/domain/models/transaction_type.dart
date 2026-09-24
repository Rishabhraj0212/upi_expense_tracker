enum TransactionType {
  debit,
  credit;

  static TransactionType fromName(String name) =>
      TransactionType.values.firstWhere((t) => t.name == name);
}
