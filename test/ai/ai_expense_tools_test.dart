import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:upi_expense_tracker/ai/ai_expense_tools.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/domain/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class FakeTransactionFilter extends Fake implements TransactionFilter {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionFilter());
  });

  group('AiExpenseTools', () {
    late MockTransactionRepository repository;
    late AiExpenseTools tools;

    setUp(() {
      repository = MockTransactionRepository();
      tools = AiExpenseTools(repository);
    });

    test('tools declaration contains expected functions', () {
      final names = tools.openAiTools
          .map((t) => (t['function'] as Map<String, dynamic>)['name'] as String)
          .toList();
      expect(names, containsAll([
        'getTotalExpenses',
        'getTotalIncome',
        'getCategoryTotal',
        'getMerchantTotal',
        'getTopCategories',
        'getTopMerchants',
        'getRecentTransactions',
        'getMonthlySummary',
      ]));
    });

    test('getTotalExpenses parses args and calls repository', () async {
      when(() => repository.getTotalAmount(any())).thenAnswer((_) async => 5000);
      when(() => repository.getTransactionCount(any())).thenAnswer((_) async => 2);

      final result = await tools.handleCall('getTotalExpenses', {
        'fromDate': '2026-09-01',
        'toDate': '2026-09-30',
      });

      expect(result['totalPaise'], 5000);
      expect(result['transactionCount'], 2);
      
      final captured = verify(() => repository.getTotalAmount(captureAny())).captured;
      final filter = captured.first as TransactionFilter;
      expect(filter.type, TransactionType.debit);
      expect(filter.from?.year, 2026);
    });

    test('getMonthlySummary generates expected summary', () async {
      when(() => repository.getTotalAmount(any())).thenAnswer((_) async => 10000);
      when(() => repository.getTransactionCount(any())).thenAnswer((_) async => 5);
      when(() => repository.getTopCategories(any(), limit: any(named: 'limit'))).thenAnswer((_) async => const [MapEntry('Food', 5000)]);
      when(() => repository.getTopMerchants(any(), limit: any(named: 'limit'))).thenAnswer((_) async => const [MapEntry('Amazon', 3000)]);
      when(() => repository.getAll(filter: any(named: 'filter'), limit: any(named: 'limit'))).thenAnswer((_) async => []);

      final result = await tools.handleCall('getMonthlySummary', {
        'year': 2026,
        'month': 9,
      });

      expect(result['month'], 9);
      expect(result['totalExpensePaise'], 10000);
      expect((result['topCategories'] as List).length, 1);
    });
    
    test('unknown function returns error', () async {
      final result = await tools.handleCall('destroyDatabase', {});
      expect(result['error'], isNotNull);
      expect(result['error'], contains('Unknown function'));
    });
  });
}
