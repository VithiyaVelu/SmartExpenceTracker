import 'package:flutter/foundation.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import '../models/budget.dart';
import '../models/recurring_transaction.dart';

class DBHelper {
  static Database? _database;
  static const String dbName = 'expense.db';
  static const String storeName = 'expenses';
  static const String budgetStoreName = 'budgets';
  static const String recurringStoreName = 'recurring';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      final factory = databaseFactoryWeb;
      return factory.openDatabase(dbName);
    }

    final factory = databaseFactoryIo;
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocDir.path, dbName);
    return factory.openDatabase(dbPath);
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final store = intMapStoreFactory.store(storeName);
    final key = await store.add(db, expense.toMap());
    return key;
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final store = intMapStoreFactory.store(storeName);
    final records = await store.find(db, finder: Finder(sortOrders: [SortOrder(Field.key, false)]));
    return records.map((record) {
      final expense = Expense.fromMap(record.value);
      expense.id = record.key;
      return expense;
    }).toList();
  }

  Future<List<Expense>> getExpensesByRecurringId(int recurringId) async {
    final db = await database;
    final store = intMapStoreFactory.store(storeName);
    final records = await store.find(
      db,
      finder: Finder(filter: Filter.equals('recurring_id', recurringId)),
    );

    return records.map((record) {
      final expense = Expense.fromMap(record.value);
      expense.id = record.key;
      return expense;
    }).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    final store = intMapStoreFactory.store(storeName);
    if (expense.id == null) {
      return await store.add(db, expense.toMap());
    }
    await store.record(expense.id!).update(db, expense.toMap());
    return expense.id!;
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    final store = intMapStoreFactory.store(storeName);
    await store.delete(db, finder: Finder(filter: Filter.byKey(id)));
  }

  // Budget operations
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    final store = intMapStoreFactory.store(budgetStoreName);
    
    // Find and delete existing budget for the same category and month
    final existing = await store.find(db);
    for (final record in existing) {
      if (record.value['category'] == budget.category && record.value['month'] == budget.month) {
        await store.delete(db, finder: Finder(filter: Filter.byKey(record.key)));
      }
    }
    
    // Add new budget
    return await store.add(db, budget.toMap());
  }

  Future<List<Budget>> getBudgets(String month) async {
    final db = await database;
    final store = intMapStoreFactory.store(budgetStoreName);
    final records = await store.find(db);
    
    final budgets = <Budget>[];
    for (final record in records) {
      if (record.value['month'] == month) {
        final budget = Budget.fromMap(record.value);
        budget.id = record.key;
        budgets.add(budget);
      }
    }
    return budgets;
  }

  Future<Budget?> getBudgetByCategory(String category, String month) async {
    final db = await database;
    final store = intMapStoreFactory.store(budgetStoreName);
    final records = await store.find(db);
    
    for (final record in records) {
      if (record.value['category'] == category && record.value['month'] == month) {
        final budget = Budget.fromMap(record.value);
        budget.id = record.key;
        return budget;
      }
    }
    return null;
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    final store = intMapStoreFactory.store(budgetStoreName);
    await store.delete(db, finder: Finder(filter: Filter.byKey(id)));
  }

  // Recurring transaction operations
  Future<int> insertRecurringTransaction(RecurringTransaction recurring) async {
    final db = await database;
    final store = intMapStoreFactory.store(recurringStoreName);
    return await store.add(db, recurring.toMap());
  }

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final db = await database;
    final store = intMapStoreFactory.store(recurringStoreName);
    final records = await store.find(db);
    
    return records.map((record) {
      final recurring = RecurringTransaction.fromMap(record.value);
      return RecurringTransaction(
        id: record.key,
        title: recurring.title,
        amount: recurring.amount,
        category: recurring.category,
        frequency: recurring.frequency,
        type: recurring.type,
        startDate: recurring.startDate,
        endDate: recurring.endDate,
        dayOfWeek: recurring.dayOfWeek,
        isActive: recurring.isActive,
      );
    }).toList();
  }

  Future<int> updateRecurringTransaction(RecurringTransaction recurring) async {
    final db = await database;
    final store = intMapStoreFactory.store(recurringStoreName);
    if (recurring.id == null) {
      return await store.add(db, recurring.toMap());
    }
    await store.record(recurring.id!).update(db, recurring.toMap());
    return recurring.id!;
  }

  Future<void> deleteRecurringTransaction(int id) async {
    final db = await database;
    final store = intMapStoreFactory.store(recurringStoreName);
    await store.delete(db, finder: Finder(filter: Filter.byKey(id)));
  }

  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    final all = await getRecurringTransactions();
    return all.where((r) => r.isActive).toList();
  }

  Future<void> clearAllData() async {
    final db = await database;
    
    // Clear all stores
    await intMapStoreFactory.store(storeName).drop(db);
    await intMapStoreFactory.store(budgetStoreName).drop(db);
    await intMapStoreFactory.store(recurringStoreName).drop(db);
  }
}
