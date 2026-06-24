import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Budgets])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // --- Insert ---
  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  // --- Update ---
  Future<bool> updateTransaction(TransactionsCompanion entry) =>
      update(transactions).replace(entry);

  // --- Delete ---
  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  // --- Get all ---
  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  // --- Get paginated ---
  Future<List<Transaction>> getTransactionsPaged({
    int limit = 50,
    int offset = 0,
    String? category,
    String? type,
    DateTime? from,
    DateTime? to,
    String? search,
  }) {
    final query = select(transactions);
    query.where((t) {
      Expression<bool> expr = const Constant(true);
      if (category != null && category.isNotEmpty) {
        expr = expr & t.category.equals(category);
      }
      if (type != null && type.isNotEmpty) {
        expr = expr & t.transactionType.equals(type);
      }
      if (from != null) {
        expr = expr & t.date.isBiggerOrEqualValue(from.millisecondsSinceEpoch);
      }
      if (to != null) {
        expr = expr & t.date.isSmallerOrEqualValue(to.millisecondsSinceEpoch);
      }
      if (search != null && search.isNotEmpty) {
        expr = expr &
            (t.description.like('%$search%') |
                t.sender.like('%$search%') |
                t.referenceNumber.like('%$search%'));
      }
      return expr;
    });
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    query.limit(limit, offset: offset);
    return query.get();
  }

  // --- Get by month ---
  Future<List<Transaction>> getTransactionsByMonth(int month, int year) {
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  // --- Aggregates ---
  Future<double> getTotalByTypeAndPeriod({
    required String type,
    required DateTime from,
    required DateTime to,
  }) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(
        transactions.transactionType.equals(type) &
            transactions.date.isBiggerOrEqualValue(from.millisecondsSinceEpoch) &
            transactions.date.isSmallerOrEqualValue(to.millisecondsSinceEpoch),
      );
    final row = await query.getSingle();
    return row.read(transactions.amount.sum()) ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTotals({
    required DateTime from,
    required DateTime to,
    String type = 'expense',
  }) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.category, transactions.amount.sum()])
      ..where(
        transactions.transactionType.equals(type) &
            transactions.date.isBiggerOrEqualValue(from.millisecondsSinceEpoch) &
            transactions.date.isSmallerOrEqualValue(to.millisecondsSinceEpoch),
      )
      ..groupBy([transactions.category]);

    final rows = await query.get();
    final result = <String, double>{};
    for (final row in rows) {
      final cat = row.read(transactions.category) ?? 'Other';
      final sum = row.read(transactions.amount.sum()) ?? 0.0;
      result[cat] = sum;
    }
    return result;
  }

  // Daily spending for the last N days
  Future<List<DailySpending>> getDailySpending({
    required DateTime from,
    required DateTime to,
  }) async {
    final allTransactions = await (select(transactions)
          ..where((t) =>
              t.transactionType.equals('expense') &
              t.date.isBiggerOrEqualValue(from.millisecondsSinceEpoch) &
              t.date.isSmallerOrEqualValue(to.millisecondsSinceEpoch)))
        .get();

    final Map<String, double> dailyMap = {};
    for (final tx in allTransactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.date);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0) + tx.amount;
    }

    return dailyMap.entries
        .map((e) => DailySpending(date: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Get single transaction
  Future<Transaction?> getTransactionById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Watch recent transactions
  Stream<List<Transaction>> watchRecentTransactions({int limit = 10}) =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .watch();

  // Count
  Future<int> getTransactionCount() async {
    final query = selectOnly(transactions)..addColumns([transactions.id.count()]);
    final row = await query.getSingle();
    return row.read(transactions.id.count()) ?? 0;
  }

  // Get all for export
  Future<List<Transaction>> getAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
}

class DailySpending {
  final String date;
  final double amount;
  DailySpending({required this.date, required this.amount});
}
