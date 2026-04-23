import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../utils/currency_service.dart';

class BudgetNotificationService {
  BudgetNotificationService._();

  static final BudgetNotificationService instance =
      BudgetNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final darwinPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await darwinPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macOSPlugin = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macOSPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  Future<void> checkBudgetAlerts({
    required List<Budget> budgets,
    required List<Expense> expenses,
    required String month,
  }) async {
    if (kIsWeb || budgets.isEmpty) {
      return;
    }

    await initialize();

    final prefs = await SharedPreferences.getInstance();
    for (final budget in budgets) {
      if (budget.amount <= 0) {
        continue;
      }

      final spent = expenses
          .where((expense) =>
              expense.type == 'expense' &&
              expense.category == budget.category &&
              expense.date.startsWith(month))
          .fold<double>(
            0,
            (sum, expense) =>
                sum + CurrencyService.convertToBase(
                  expense.amount,
                  expense.currency,
                ),
          );

      final ratio = spent / budget.amount;
      final level = ratio >= 1 ? 2 : ratio >= 0.8 ? 1 : 0;
      final key = _storageKey(month, budget.category);
      final lastLevel = prefs.getInt(key) ?? 0;

      if (level == lastLevel) {
        continue;
      }

      await prefs.setInt(key, level);

      if (level == 1 && lastLevel < 1) {
        await _showBudgetAlert(
          id: _notificationId(month, budget.category, 80),
          title: 'Budget warning: ${budget.category}',
          body:
              'You have used ${_formatAmount(spent)} of ${_formatAmount(budget.amount)} '
              '(${(ratio * 100).toStringAsFixed(0)}%).',
        );
      } else if (level == 2 && lastLevel < 2) {
        await _showBudgetAlert(
          id: _notificationId(month, budget.category, 100),
          title: 'Budget exceeded: ${budget.category}',
          body:
              'You have used ${_formatAmount(spent)} of ${_formatAmount(budget.amount)} '
              '(${(ratio * 100).toStringAsFixed(0)}%).',
        );
      }
    }
  }

  Future<void> _showBudgetAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Alerts when spending reaches budget thresholds',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  String _storageKey(String month, String category) {
    final safeCategory = category.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
    return 'budget_alert_${month}_$safeCategory';
  }

  int _notificationId(String month, String category, int threshold) {
    return Object.hash(month, category, threshold);
  }

  String _formatAmount(double value) {
    return '${CurrencyService.baseCurrencySymbol} ${value.toStringAsFixed(0)}';
  }
}
