import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../utils/currency_service.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';

class WebDashboard extends StatefulWidget {
  const WebDashboard({super.key});

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  final DBHelper db = DBHelper();
  List<Expense> expenses = [];
  List<Budget> budgets = [];
  double totalIncome = 0;
  double totalExpense = 0;
  Map<String, double> categorySpending = {};
  ExpenseProvider? _expenseProvider;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ExpenseProvider>();
    if (_expenseProvider != provider) {
      _expenseProvider?.removeListener(loadDashboardData);
      _expenseProvider = provider;
      _expenseProvider!.addListener(loadDashboardData);
    }
  }

  @override
  void dispose() {
    _expenseProvider?.removeListener(loadDashboardData);
    super.dispose();
  }

  Future<void> loadDashboardData() async {
    final allExpenses =
        _expenseProvider?.expenses ?? context.read<ExpenseProvider>().expenses;
    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final monthlyBudgets = await db.getBudgets(currentMonth);

    double income = 0;
    double expense = 0;
    final categoryMap = <String, double>{};

    for (final e in allExpenses) {
      final amountInBase = CurrencyService.convertToBase(e.amount, e.currency);
      if (e.type == 'income') {
        income += amountInBase;
      } else {
        expense += amountInBase;
        categoryMap[e.category] = (categoryMap[e.category] ?? 0) + amountInBase;
      }
    }

    if (mounted) {
      setState(() {
        this.expenses = allExpenses;
        budgets = monthlyBudgets;
        totalIncome = income;
        totalExpense = expense;
        categorySpending = categoryMap;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Expense Tracker Dashboard'),
        backgroundColor: themeProvider.currentTheme.primaryColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                CurrencyService.formatBaseAmount(totalIncome - totalExpense),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // KPI Cards
            _buildKPIRow(themeProvider),
            const SizedBox(height: 24),

            // Charts Row
            if (!isMobile)
              Row(
                children: [
                  Expanded(child: _buildExpenseChart(themeProvider)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildCategoryChart(themeProvider)),
                ],
              )
            else ...[
              _buildExpenseChart(themeProvider),
              const SizedBox(height: 24),
              _buildCategoryChart(themeProvider),
            ],

            const SizedBox(height: 24),

            // Budget Status
            _buildBudgetStatus(themeProvider),

            const SizedBox(height: 24),

            // Recent Transactions
            _buildRecentTransactions(themeProvider, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIRow(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildKPICard(
            'Total Income',
            totalIncome,
            Colors.green,
            themeProvider,
          ),
          const SizedBox(width: 16),
          _buildKPICard(
            'Total Expense',
            totalExpense,
            Colors.red,
            themeProvider,
          ),
          const SizedBox(width: 16),
          _buildKPICard(
            'Net Balance',
            totalIncome - totalExpense,
            (totalIncome - totalExpense) >= 0 ? Colors.blue : Colors.orange,
            themeProvider,
          ),
          const SizedBox(width: 16),
          _buildKPICard(
            'Save Rate',
            ((totalIncome - totalExpense) / totalIncome * 100).isNaN
                ? 0
                : ((totalIncome - totalExpense) / totalIncome * 100),
            Colors.purple,
            themeProvider,
            suffix: '%',
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    String label,
    double value,
    Color color,
    ThemeProvider themeProvider, {
    String suffix = '',
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                CurrencyService.baseCurrencySymbol,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${value.toStringAsFixed(0)}$suffix',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expense',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totalIncome,
                        color: Colors.green,
                        width: 40,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalExpense,
                        color: Colors.red,
                        width: 40,
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Income', 'Expense'];
                        return Text(
                          titles[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(ThemeProvider themeProvider) {
    if (categorySpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No expense data available')),
      );
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categorySpending.entries.toList().asMap().entries.map((
                  e,
                ) {
                  final color = colors[e.key % colors.length];
                  return PieChartSectionData(
                    value: e.value.value,
                    title:
                        '${(e.value.value / totalExpense * 100).toStringAsFixed(0)}%',
                    color: color,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...categorySpending.entries.map((e) {
            final color =
                colors[categorySpending.keys.toList().indexOf(e.key) %
                    colors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.key)),
                  Text(
                    CurrencyService.formatBaseAmount(
                      e.value,
                      fractionDigits: 0,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBudgetStatus(ThemeProvider themeProvider) {
    if (budgets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No budgets set for this month')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...budgets.map((budget) {
            final spent = categorySpending[budget.category] ?? 0;
            final percentage = (spent / budget.amount * 100).clamp(0, 100);
            final isOverBudget = spent > budget.amount;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isOverBudget ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyService.formatBaseAmount(spent, fractionDigits: 0)} / ${CurrencyService.formatBaseAmount(budget.amount, fractionDigits: 0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeProvider themeProvider, bool isMobile) {
    final recentExpenses = expenses.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            ...recentExpenses.map((e) => _buildTransactionListItem(e))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Amount')),
                ],
                rows: recentExpenses.map((e) {
                  return DataRow(
                    cells: [
                      DataCell(Text(e.date)),
                      DataCell(Text(e.title)),
                      DataCell(Text(e.category)),
                      DataCell(
                        Text(
                          '${e.type == 'income' ? '+' : '-'}${CurrencyService.formatBaseAmount(e.amount)}',
                          style: TextStyle(
                            color: e.type == 'income'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionListItem(Expense expense) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${expense.date} • ${expense.category}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Text(
            '${expense.type == 'income' ? '+' : '-'}${CurrencyService.formatBaseAmount(expense.amount)}',
            style: TextStyle(
              color: expense.type == 'income' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
