import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'rule_dao.g.dart';

@DriftAccessor(tables: [Rules])
class RuleDao extends DatabaseAccessor<AppDatabase> with _$RuleDaoMixin {
  RuleDao(super.db);

  Future<int> insertRule(RulesCompanion entry) =>
      into(rules).insert(entry);

  Future<bool> updateRule(RulesCompanion entry) =>
      update(rules).replace(entry);

  Future<int> deleteRule(int id) =>
      (delete(rules)..where((r) => r.id.equals(id))).go();

  Stream<List<Rule>> watchAllRules() =>
      (select(rules)..orderBy([(r) => OrderingTerm.desc(r.priority)])).watch();

  Future<List<Rule>> getActiveRules() =>
      (select(rules)
            ..where((r) => r.isActive.equals(true))
            ..orderBy([(r) => OrderingTerm.desc(r.priority)]))
          .get();

  Future<Rule?> getRuleById(int id) =>
      (select(rules)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> getRuleCount() async {
    final query = selectOnly(rules)..addColumns([rules.id.count()]);
    final row = await query.getSingle();
    return row.read(rules.id.count()) ?? 0;
  }
}
