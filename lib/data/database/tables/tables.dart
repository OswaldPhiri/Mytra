import 'package:drift/drift.dart';

// Transactions table
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()(); // Unix ms
  RealColumn get amount => real()();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  TextColumn get source => text().withLength(min: 1, max: 20)();
  TextColumn get transactionType => text().withLength(min: 1, max: 20)();
  TextColumn get description => text().withLength(min: 0, max: 500)();
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get sender => text().nullable()();
  TextColumn get rawMessage => text().nullable()();
  IntColumn get budgetId => integer().nullable().references(Budgets, #id)();
  BoolColumn get isManuallyEdited => boolean().withDefault(const Constant(false))();
}

// Budgets table
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  IntColumn get month => integer()(); // 1-12
  IntColumn get year => integer()();
  IntColumn get createdAt => integer()(); // Unix ms
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// Rules table
class Rules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get conditionField => text()(); // sender|description|amount|category
  TextColumn get conditionOperator => text()(); // contains|equals|starts_with|gt|lt
  TextColumn get conditionValue => text()();
  TextColumn get actionCategory => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()(); // Unix ms
}

// Categories table
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))();
}
