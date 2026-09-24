class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  final int id;
  final String name;
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory && runtimeType == other.runtimeType && id == other.id && name == other.name && isDefault == other.isDefault;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ isDefault.hashCode;
}
