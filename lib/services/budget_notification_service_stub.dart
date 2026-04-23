import '../models/budget.dart';
import '../models/expense.dart';

class BudgetNotificationService {
  BudgetNotificationService._();

  static final BudgetNotificationService instance =
      BudgetNotificationService._();

  Future<void> initialize() async {}

  Future<void> checkBudgetAlerts({
    required List<Budget> budgets,
    required List<Expense> expenses,
    required String month,
  }) async {}
}
