import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/tables/tables.dart';
import 'core_providers.dart';

// --- Active budget ---
final activeBudgetProvider = StreamProvider<Budget?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.budgetDao.watchActiveBudget();
});

// --- All budgets ---
final allBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.budgetDao.watchAllBudgets();
});

// --- Budget summary for current month ---
final budgetSummaryProvider = FutureProvider<BudgetSummary>((ref) async {
  final db = ref.watch(databaseProvider);
  final budget = await db.budgetDao.getActiveBudget();
  final now = DateTime.now();

  final totalExpenses = await db.transactionDao.getTotalByTypeAndPeriod(
    type: 'expense',
    from: DateTime(now.year, now.month, 1),
    to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
  );
  final totalIncome = await db.transactionDao.getTotalByTypeAndPeriod(
    type: 'income',
    from: DateTime(now.year, now.month, 1),
    to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
  );

  return BudgetSummary(
    budget: budget,
    totalExpenses: totalExpenses,
    totalIncome: totalIncome,
    remaining: (budget?.amount ?? 0) - totalExpenses,
  );
});

class BudgetSummary {
  final Budget? budget;
  final double totalExpenses;
  final double totalIncome;
  final double remaining;

  BudgetSummary({
    required this.budget,
    required this.totalExpenses,
    required this.totalIncome,
    required this.remaining,
  });

  double get usagePercentage {
    if (budget == null || budget!.amount == 0) return 0;
    return (totalExpenses / budget!.amount).clamp(0.0, 1.0);
  }
}

// --- Transactions ---
class TransactionFilter {
  final String? category;
  final String? type;
  final DateTime? from;
  final DateTime? to;
  final String? search;

  const TransactionFilter({
    this.category,
    this.type,
    this.from,
    this.to,
    this.search,
  });

  TransactionFilter copyWith({
    String? category,
    String? type,
    DateTime? from,
    DateTime? to,
    String? search,
  }) =>
      TransactionFilter(
        category: category ?? this.category,
        type: type ?? this.type,
        from: from ?? this.from,
        to: to ?? this.to,
        search: search ?? this.search,
      );
}

final transactionFilterProvider = StateProvider<TransactionFilter>(
  (_) => const TransactionFilter(),
);

final transactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final db = ref.watch(databaseProvider);
  final filter = ref.watch(transactionFilterProvider);
  return db.transactionDao.getTransactionsPaged(
    limit: 100,
    offset: 0,
    category: filter.category,
    type: filter.type,
    from: filter.from,
    to: filter.to,
    search: filter.search,
  );
});

final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.transactionDao.watchRecentTransactions(limit: 8);
});

final transactionByIdProvider = FutureProvider.family<Transaction?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.transactionDao.getTransactionById(id);
});

// --- Category breakdown ---
final categoryBreakdownProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  return db.transactionDao.getCategoryTotals(
    from: DateTime(now.year, now.month, 1),
    to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    type: 'expense',
  );
});

// --- Transaction mutations ---
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  TransactionNotifier(this._db) : super(const AsyncValue.data(null));

  Future<void> addTransaction(TransactionsCompanion entry) async {
    state = const AsyncValue.loading();
    try {
      await _db.transactionDao.insertTransaction(entry);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateTransaction(TransactionsCompanion entry) async {
    state = const AsyncValue.loading();
    try {
      await _db.transactionDao.updateTransaction(entry);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncValue.loading();
    try {
      await _db.transactionDao.deleteTransaction(id);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  return TransactionNotifier(ref.watch(databaseProvider));
});

// --- Budget mutations ---
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  BudgetNotifier(this._db) : super(const AsyncValue.data(null));

  Future<void> createBudget({
    required String name,
    required double amount,
    required int month,
    required int year,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Deactivate current active budget
      await _db.budgetDao.deactivateAllBudgets();
      await _db.budgetDao.insertBudget(
        BudgetsCompanion.insert(
          name: name,
          amount: amount,
          month: month,
          year: year,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateBudget(BudgetsCompanion entry) async {
    state = const AsyncValue.loading();
    try {
      await _db.budgetDao.updateBudget(entry);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteBudget(int id) async {
    state = const AsyncValue.loading();
    try {
      await _db.budgetDao.deleteBudget(id);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  return BudgetNotifier(ref.watch(databaseProvider));
});
