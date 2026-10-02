import '../domain/models/transaction_type.dart';
import '../domain/repositories/transaction_repository.dart';

class AiExpenseTools {
  AiExpenseTools(this.repository);

  final TransactionRepository repository;

  List<Map<String, dynamic>> get openAiTools => [
        {
          'type': 'function',
          'function': {
            'name': 'getTotalExpenses',
            'description': 'Get total amount spent (debits) in a specific date range.',
            'parameters': {
              'type': 'object',
              'properties': {
                'fromDate': {'type': 'string', 'description': 'ISO8601 date, e.g. 2026-09-01'},
                'toDate': {'type': 'string', 'description': 'ISO8601 date, e.g. 2026-09-30'},
              },
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'getTotalIncome',
            'description': 'Get total amount received (credits) in a specific date range.',
            'parameters': {
              'type': 'object',
              'properties': {
                'fromDate': {'type': 'string', 'description': 'ISO8601 date'},
                'toDate': {'type': 'string', 'description': 'ISO8601 date'},
              },
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'getCategoryTotal',
            'description': 'Get total amount spent in a specific category.',
            'parameters': {
              'type': 'object',
              'properties': {
                'category': {'type': 'string', 'description': 'The category name (e.g. Food, Shopping).'},
                'fromDate': {'type': 'string', 'description': 'ISO8601 date'},
                'toDate': {'type': 'string', 'description': 'ISO8601 date'},
              },
              'required': ['category'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'getMerchantTotal',
            'description': 'Get total amount spent at a specific merchant.',
            'parameters': {
              'type': 'object',
              'properties': {
                'merchant': {'type': 'string', 'description': 'The merchant name (e.g. Amazon, Uber).'},
                'fromDate': {'type': 'string', 'description': 'ISO8601 date'},
                'toDate': {'type': 'string', 'description': 'ISO8601 date'},
              },
              'required': ['merchant'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'getTopCategories',
            'description': 'Get top spending categories.',
            'parameters': {
              'type': 'object',
              'properties': {
                'fromDate': {'type': 'string', 'description': 'ISO8601 date'},
                'toDate': {'type': 'string', 'description': 'ISO8601 date'},
                'limit': {'type': 'integer', 'description': 'Number of categories to return, default 5.'},
              },
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'getTopMerchants',
            'description': 'Get top merchants by spending.',
            'parameters': {
              'type': 'object',
              'properties': {
                'fromDate': {'type': 'string', 'description': 'ISO8601 date'},
                'toDate': {'type': 'string', 'description': 'ISO8601 date'},
                'limit': {'type': 'integer', 'description': 'Number of merchants to return, default 5.'},
              },
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'getRecentTransactions',
            'description': 'Get recent transactions matching optional filters (e.g. largest, or specific category).',
            'parameters': {
              'type': 'object',
              'properties': {
                'limit': {'type': 'integer', 'description': 'Number of transactions, default 10.'},
                'category': {'type': 'string', 'description': 'Filter by category'},
                'merchant': {'type': 'string', 'description': 'Filter by merchant'},
                'transactionType': {'type': 'string', 'description': 'debit or credit'},
                'fromDate': {'type': 'string', 'description': 'ISO8601 date'},
                'toDate': {'type': 'string', 'description': 'ISO8601 date'},
              },
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'getMonthlySummary',
            'description': 'Get a summary of transactions for a specific month.',
            'parameters': {
              'type': 'object',
              'properties': {
                'year': {'type': 'integer', 'description': 'Year, e.g. 2026'},
                'month': {'type': 'integer', 'description': 'Month, e.g. 9 for September'},
              },
              'required': ['year', 'month'],
            },
          },
        },
      ];

  Future<Map<String, Object?>> handleCall(String name, Map<String, Object?> args) async {
    try {
      switch (name) {
        case 'getTotalExpenses':
          return await _getTotalExpenses(args);
        case 'getTotalIncome':
          return await _getTotalIncome(args);
        case 'getCategoryTotal':
          return await _getCategoryTotal(args);
        case 'getMerchantTotal':
          return await _getMerchantTotal(args);
        case 'getTopCategories':
          return await _getTopCategories(args);
        case 'getTopMerchants':
          return await _getTopMerchants(args);
        case 'getRecentTransactions':
          return await _getRecentTransactions(args);
        case 'getMonthlySummary':
          return await _getMonthlySummary(args);
        default:
          return {'error': 'Unknown function $name'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  TransactionFilter _parseFilter(Map<String, Object?> args, {TransactionType? forceType}) {
    TransactionType? type = forceType;
    if (type == null && args['transactionType'] is String) {
      final t = (args['transactionType'] as String).toLowerCase();
      if (t == 'debit') type = TransactionType.debit;
      if (t == 'credit') type = TransactionType.credit;
    }
    return TransactionFilter(
      type: type,
      from: _parseDate(args['fromDate']),
      to: _parseDate(args['toDate'])?.add(const Duration(days: 1)), // inclusive of the day
      category: args['category'] as String?,
      searchText: args['merchant'] as String?,
    );
  }

  Future<Map<String, Object?>> _getTotalExpenses(Map<String, Object?> args) async {
    final filter = _parseFilter(args, forceType: TransactionType.debit);
    final total = await repository.getTotalAmount(filter);
    final count = await repository.getTransactionCount(filter);
    return {'totalPaise': total, 'transactionCount': count, 'currency': 'INR'};
  }

  Future<Map<String, Object?>> _getTotalIncome(Map<String, Object?> args) async {
    final filter = _parseFilter(args, forceType: TransactionType.credit);
    final total = await repository.getTotalAmount(filter);
    final count = await repository.getTransactionCount(filter);
    return {'totalPaise': total, 'transactionCount': count, 'currency': 'INR'};
  }

  Future<Map<String, Object?>> _getCategoryTotal(Map<String, Object?> args) async {
    final filter = _parseFilter(args, forceType: TransactionType.debit);
    final total = await repository.getTotalAmount(filter);
    return {'category': args['category'], 'totalPaise': total};
  }

  Future<Map<String, Object?>> _getMerchantTotal(Map<String, Object?> args) async {
    final filter = _parseFilter(args, forceType: TransactionType.debit);
    final total = await repository.getTotalAmount(filter);
    return {'merchant': args['merchant'], 'totalPaise': total};
  }

  Future<Map<String, Object?>> _getTopCategories(Map<String, Object?> args) async {
    final filter = _parseFilter(args, forceType: TransactionType.debit);
    final limit = (args['limit'] as num?)?.toInt() ?? 5;
    final tops = await repository.getTopCategories(filter, limit: limit);
    return {
      'topCategories': tops.map((e) => {'category': e.key, 'totalPaise': e.value}).toList(),
    };
  }

  Future<Map<String, Object?>> _getTopMerchants(Map<String, Object?> args) async {
    final filter = _parseFilter(args, forceType: TransactionType.debit);
    final limit = (args['limit'] as num?)?.toInt() ?? 5;
    final tops = await repository.getTopMerchants(filter, limit: limit);
    return {
      'topMerchants': tops.map((e) => {'merchant': e.key, 'totalPaise': e.value}).toList(),
    };
  }

  Future<Map<String, Object?>> _getRecentTransactions(Map<String, Object?> args) async {
    final filter = _parseFilter(args);
    final limit = (args['limit'] as num?)?.toInt() ?? 10;
    final transactions = await repository.getAll(filter: filter, limit: limit);
    return {
      'transactions': transactions.map((t) => {
        'date': t.occurredAt.toIso8601String(),
        'amountPaise': t.amountPaise,
        'type': t.type.name,
        'merchant': t.merchantName,
        'category': t.category,
      }).toList(),
    };
  }

  Future<Map<String, Object?>> _getMonthlySummary(Map<String, Object?> args) async {
    final year = (args['year'] as num).toInt();
    final month = (args['month'] as num).toInt();
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    
    final debitFilter = TransactionFilter(type: TransactionType.debit, from: start, to: end);
    final creditFilter = TransactionFilter(type: TransactionType.credit, from: start, to: end);

    final totalExpense = await repository.getTotalAmount(debitFilter);
    final totalIncome = await repository.getTotalAmount(creditFilter);
    final expenseCount = await repository.getTransactionCount(debitFilter);
    
    final topsCategories = await repository.getTopCategories(debitFilter, limit: 3);
    final topsMerchants = await repository.getTopMerchants(debitFilter, limit: 3);
    
    final largestTransactions = await repository.getAll(filter: debitFilter, limit: 10000);
    largestTransactions.sort((a, b) => b.amountPaise.compareTo(a.amountPaise));
    
    return {
      'month': month,
      'year': year,
      'totalIncomePaise': totalIncome,
      'totalExpensePaise': totalExpense,
      'expenseTransactionCount': expenseCount,
      'topCategories': topsCategories.map((e) => {'category': e.key, 'amountPaise': e.value}).toList(),
      'topMerchants': topsMerchants.map((e) => {'merchant': e.key, 'amountPaise': e.value}).toList(),
      'largestTransaction': largestTransactions.isNotEmpty ? {
        'amountPaise': largestTransactions.first.amountPaise,
        'merchant': largestTransactions.first.merchantName,
        'date': largestTransactions.first.occurredAt.toIso8601String(),
      } : null,
    };
  }
}
