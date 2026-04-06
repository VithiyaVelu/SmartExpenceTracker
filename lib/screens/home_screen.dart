import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../utils/transaction_predictor.dart';
import '../utils/currency_service.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'add_expense_screen.dart';
import 'categories_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'search_filter_screen.dart';
import 'receipt_scanner_screen.dart';
import 'recurring_transactions_screen.dart';
import 'predictions_screen.dart';
import 'currency_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'web_dashboard.dart';
import 'advanced_analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper db = DBHelper();
  List<Expense> expenses = [];
  double balance = 0;
  Map<String, double> budgets = {};
  Map<String, double> currentSpending = {};
  List<PredictionData> upcomingPredictions = [];
  final currentMonth = DateTime.now().toIso8601String().substring(0, 7);

  @override
  void initState() {
    super.initState();
    loadData();
    _autoCreateDueRecurringTransactions();
  }

  Future<void> loadData() async {
    final data = await db.getExpenses();
    double total = 0;

    for (final expense in data) {
      final amountInBase = CurrencyService.convertToBase(expense.amount, expense.currency);
      if (expense.type == 'income') {
        total += amountInBase;
      } else {
        total -= amountInBase;
      }
    }

    // Load budgets
    final budgetList = await db.getBudgets(currentMonth);
    final Map<String, double> budgetMap = {};
    for (final budget in budgetList) {
      budgetMap[budget.category] = budget.amount;
    }

    // Calculate current month spending by category
    final Map<String, double> spending = {};
    for (final expense in data) {
      if (expense.type == 'expense' && expense.date.startsWith(currentMonth)) {
        final amountInBase = CurrencyService.convertToBase(expense.amount, expense.currency);
        spending[expense.category] = (spending[expense.category] ?? 0) + amountInBase;
      }
    }

    // Load upcoming predictions (next 7 days)
    final recurring = await db.getRecurringTransactions();
    final predictions = TransactionPredictor.getAllPredictions(data, recurring, 7);

    if (!mounted) {
      return;
    }

    setState(() {
      expenses = data;
      balance = total;
      budgets = budgetMap;
      currentSpending = spending;
      upcomingPredictions = predictions.take(5).toList(); // Show top 5 upcoming
    });

    // Update spending mood for dynamic theming
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.updateSpendingMood();
  }

  List<String> getBudgetAlerts() {
    final alerts = <String>[];

    for (final category in currentSpending.keys) {
      final spent = currentSpending[category]!;
      final budget = budgets[category] ?? 0;

      if (budget > 0) {
        final currencySymbol = CurrencyService.getCurrencyByCode(CurrencyService.baseCurrency)?.symbol ?? '\$';
        if (spent >= budget) {
          alerts.add('⚠️ Over budget in $category! Spent $currencySymbol ${spent.toStringAsFixed(0)} of $currencySymbol ${budget.toStringAsFixed(0)}');
        } else if ((spent / budget) >= 0.8) {
          alerts.add('📌 ${category} spending at ${((spent/budget)*100).toStringAsFixed(0)}% of budget');
        }
      }
    }

    return alerts;
  }

  Future<void> deleteExpense(Expense expense) async {
    await db.deleteExpense(expense.id!);
    await loadData();
  }

  Future<void> _autoCreateDueRecurringTransactions() async {
    final recurring = await db.getRecurringTransactions();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    for (final rec in recurring) {
      if (!rec.isActive) continue;
      
      // Check if this recurring transaction should be created today
      final nextOccurrence = rec.getNextOccurrence(DateTime.now());
      final nextOccurrenceStr = nextOccurrence.toIso8601String().split('T')[0];
      
      // Create if due today or overdue
      if (nextOccurrenceStr.compareTo(today) <= 0) {
        // Check if already created today
        final expenses = await db.getExpenses();
        final alreadyCreated = expenses.any((e) =>
            e.title == rec.title &&
            e.date == today &&
            e.category == rec.category &&
            e.amount == rec.amount);
        
        if (!alreadyCreated) {
          final expense = Expense(
            title: rec.title,
            amount: rec.amount,
            category: rec.category,
            date: today,
            type: rec.type,
          );
          await db.insertExpense(expense);
        }
      }
    }
  }

  Future<void> _syncData(BuildContext context, AuthProvider authProvider) async {
    try {
      await authProvider.syncToCloud();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data synced to cloud successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  Future<void> _logout(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? Make sure your data is synced.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = getBudgetAlerts();
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: themeProvider.currentTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Budget',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              ).then((_) => loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search & Filter',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: 'Recurring',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen()),
              ).then((_) => loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'Predictions',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PredictionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.currency_exchange),
            tooltip: 'Currency Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CurrencySettingsScreen()),
              ).then((_) => loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Theme Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'Advanced Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdvancedAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Web Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebDashboard()),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAuthenticated && !authProvider.hasSkippedAuth) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'sync':
                        _syncData(context, authProvider);
                        break;
                      case 'logout':
                        _logout(context, authProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sync',
                      child: Row(
                        children: [
                          Icon(Icons.cloud_sync),
                          SizedBox(width: 8),
                          Text('Sync Data'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.account_circle),
                  tooltip: 'Account',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
                border: themeProvider.useDynamicTheme
                    ? Border.all(
                        color: themeProvider.getMoodColor().withOpacity(0.3),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Total Balance (${CurrencyService.baseCurrency})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      if (themeProvider.useDynamicTheme) ...[
                        const SizedBox(width: 8),
                        Icon(
                          themeProvider.getMoodIcon(),
                          color: themeProvider.getMoodColor(),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${CurrencyService.getCurrencyByCode(CurrencyService.baseCurrency)?.symbol ?? '\$'} ${balance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.useDynamicTheme
                              ? themeProvider.getMoodColor()
                              : null,
                        ),
                  ),
                  if (themeProvider.useDynamicTheme) ...[
                    const SizedBox(height: 8),
                    Text(
                      themeProvider.getMoodDescription(),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.getMoodColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Upcoming predictions card
            if (upcomingPredictions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Next 7 Days',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...upcomingPredictions.take(3).map((prediction) {
                      final daysUntil =
                          prediction.predictedDate.difference(DateTime.now()).inDays;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${prediction.description} (in ${daysUntil}d)',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${CurrencyService.getCurrencyByCode(CurrencyService.baseCurrency)?.symbol ?? '\$'} ${prediction.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (alerts.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Alerts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...alerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            alert,
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: expenses.isEmpty
                  ? const Center(
                      child: Text('No transactions yet. Tap + to add one.'),
                    )
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final isIncome = expense.type == 'income';
                        final category = getCategoryByName(expense.category);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: category.color.withOpacity(0.2),
                              child: Icon(
                                category.icon,
                                color: category.color,
                              ),
                            ),
                            title: Text(expense.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(expense.date),
                                Text(
                                  expense.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} ${CurrencyService.getCurrencyByCode(CurrencyService.baseCurrency)?.symbol ?? '\$'} ${CurrencyService.convertToBase(expense.amount, expense.currency).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isIncome ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (expense.currency != CurrencyService.baseCurrency)
                                  Text(
                                    '${CurrencyService.getCurrencyByCode(expense.currency)?.symbol ?? '\$'} ${expense.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            onLongPress: () => deleteExpense(expense),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.teal),
              title: const Text('Add Manually'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddExpenseScreen(),
                  ),
                );
                await loadData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.orange),
              title: const Text('Scan Receipt'),
              subtitle: const Text('Extract data with AI'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReceiptScannerScreen(),
                  ),
                );
                if (result == true) {
                  await loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }}