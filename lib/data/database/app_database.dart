import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/tables.dart';
import 'daos/transaction_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/rule_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, Budgets, Rules, Categories],
  daos: [TransactionDao, BudgetDao, RuleDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(DatabaseConnection connection) : super(connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _insertDefaultCategories();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations here
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA cache_size = 10000');
        },
      );

  Future<void> _insertDefaultCategories() async {
    final defaultCats = [
      CategoriesCompanion.insert(
        name: 'Food',
        icon: 'restaurant',
        color: 0xFFF59E0B,
      ),
      CategoriesCompanion.insert(
        name: 'Transport',
        icon: 'directions_car',
        color: 0xFF3B82F6,
      ),
      CategoriesCompanion.insert(
        name: 'Utilities',
        icon: 'bolt',
        color: 0xFF8B5CF6,
      ),
      CategoriesCompanion.insert(
        name: 'Rent',
        icon: 'home',
        color: 0xFFEF4444,
      ),
      CategoriesCompanion.insert(
        name: 'Entertainment',
        icon: 'movie',
        color: 0xFFEC4899,
      ),
      CategoriesCompanion.insert(
        name: 'Shopping',
        icon: 'shopping_bag',
        color: 0xFF10B981,
      ),
      CategoriesCompanion.insert(
        name: 'Salary',
        icon: 'payments',
        color: 0xFF26C165,
      ),
      CategoriesCompanion.insert(
        name: 'Transfers',
        icon: 'swap_horiz',
        color: 0xFF06B6D4,
      ),
      CategoriesCompanion.insert(
        name: 'Savings',
        icon: 'savings',
        color: 0xFFF59E0B,
      ),
      CategoriesCompanion.insert(
        name: 'Other',
        icon: 'more_horiz',
        color: 0xFF6B7280,
      ),
    ];
    await batch((b) => b.insertAll(categories, defaultCats));
  }

  // Close and reopen (for backup/restore)
  Future<void> closeDatabase() => close();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mytra_budget.db'));
    return driftDatabase(name: 'mytra_budget', native: DriftNativeOptions(databasePath: () => file.path));
  });
}
