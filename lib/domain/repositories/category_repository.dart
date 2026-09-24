import '../models/expense_category.dart';

abstract class CategoryRepository {
  Stream<List<ExpenseCategory>> watchAllCategories();
  
  Future<List<ExpenseCategory>> getAllCategories();
  
  Future<ExpenseCategory> addCustomCategory(String name);
  
  Future<void> updateCustomCategory(int id, String newName);
  
  /// Deletes a custom category. Implementations should check if it's safe to delete 
  /// (e.g. no transactions are using it) and throw if it's in use, or re-assign 
  /// them to 'Uncategorized' (null) based on requirements.
  Future<void> deleteCustomCategory(int id);
  
  /// Saves a category memory rule for a given merchant/UPI ID.
  Future<void> saveRule(String merchantKey, String category);
  
  /// Retrieves the saved category for a merchant/UPI ID, if any.
  Future<String?> getCategoryForMerchant(String merchantKey);
}
