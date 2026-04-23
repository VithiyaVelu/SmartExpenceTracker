import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/expense.dart';
import '../services/budget_notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _hasExpenseWithRecurringId(int recurringId) {
    return _expenses.any((expense) => expense.recurringId == recurringId);
  }

  Future<void> _refreshBudgetAlerts() async {
    try {
      final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
      final budgets = await _db.getBudgets(currentMonth);
      await BudgetNotificationService.instance.checkBudgetAlerts(
        budgets: budgets,
        expenses: _expenses,
        month: currentMonth,
      );
    } catch (_) {
      // Budget alerts should never block expense loading or saving.
    }
  }

  Future<void> loadExpenses({bool force = false}) async {
    if (_isLoading && !force) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _db.getExpenses();
      await _refreshBudgetAlerts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    if (expense.recurringId != null) {
      final recurringId = expense.recurringId!;

      if (_hasExpenseWithRecurringId(recurringId)) {
        return;
      }

      final existingExpenses = await _db.getExpensesByRecurringId(recurringId);
      if (existingExpenses.isNotEmpty) {
        return;
      }
    }

    final id = await _db.insertExpense(expense);
    expense.id = id;
    _expenses = [expense, ..._expenses];
    notifyListeners();
    await _refreshBudgetAlerts();
  }

  Future<void> updateExpense(Expense expense) async {
    final id = await _db.updateExpense(expense);
    expense.id = id;

    final index = _expenses.indexWhere((item) => item.id == id);
    if (index == -1) {
      _expenses = [expense, ..._expenses];
    } else {
      _expenses[index] = expense;
    }
    notifyListeners();
    await _refreshBudgetAlerts();
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
    await _refreshBudgetAlerts();
  }

  Future<void> refresh() => loadExpenses(force: true);
}
