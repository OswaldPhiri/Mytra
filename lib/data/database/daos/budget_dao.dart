import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Future<int> insertBudget(BudgetsCompanion entry) =>
      into(budgets).insert(entry);

  Future<bool> updateBudget(BudgetsCompanion entry) =>
      update(budgets).replace(entry);

  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  Stream<List<Budget>> watchAllBudgets() =>
      (select(budgets)..orderBy([(b) => OrderingTerm.desc(b.year), (b) => OrderingTerm.desc(b.month)])).watch();

  Future<Budget?> getActiveBudget() =>
      (select(budgets)..where((b) => b.isActive.equals(true))..limit(1)).getSingleOrNull();

  Future<Budget?> getBudgetByMonthYear(int month, int year) =>
      (select(budgets)
            ..where((b) => b.month.equals(month) & b.year.equals(year))
            ..limit(1))
          .getSingleOrNull();

  Future<Budget?> getBudgetById(int id) =>
      (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<void> deactivateAllBudgets() =>
      (update(budgets)..where((b) => b.isActive.equals(true)))
          .write(const BudgetsCompanion(isActive: Value(false)));

  Stream<Budget?> watchActiveBudget() =>
      (select(budgets)..where((b) => b.isActive.equals(true))..limit(1)).watchSingleOrNull();
}
