import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Map<String, double> getCategorySpending(List<Expense> expenses) {
    final Map<String, double> spending = {};
    for (final expense in expenses) {
      if (expense.type == 'expense') {
        spending[expense.category] =
            (spending[expense.category] ?? 0) + expense.amount;
      }
    }
    return spending;
  }

  Map<String, double> getMonthlySpending(List<Expense> expenses) {
    final Map<String, double> monthly = {};
    for (final expense in expenses) {
      if (expense.type == 'expense') {
        final month = expense.date.substring(0, 7); // YYYY-MM
        monthly[month] = (monthly[month] ?? 0) + expense.amount;
      }
    }
    // Sort by month
    final sorted = Map.fromEntries(
      monthly.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  List<String> getInsights(List<Expense> expenses) {
    final insights = <String>[];
    final categorySpending = getCategorySpending(expenses);
    final monthlySpending = getMonthlySpending(expenses);

    if (categorySpending.isEmpty) return insights;

    // Find highest spending category
    final topCategory = categorySpending.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    insights.add(
      'Your highest spending category is ${topCategory.key} with ${CurrencyService.formatBaseAmount(topCategory.value)}',
    );

    // Monthly comparison
    final sortedMonths = monthlySpending.keys.toList()..sort();
    if (sortedMonths.length >= 2) {
      final currentMonth = sortedMonths.last;
      final previousMonth = sortedMonths[sortedMonths.length - 2];
      final currentAmount = monthlySpending[currentMonth]!;
      final previousAmount = monthlySpending[previousMonth]!;
      final change = ((currentAmount - previousAmount) / previousAmount * 100)
          .round();

      if (change > 0) {
        insights.add(
          'You spent ${change.abs()}% more this month compared to last month',
        );
      } else if (change < 0) {
        insights.add(
          'You spent ${change.abs()}% less this month compared to last month',
        );
      } else {
        insights.add('Your spending remained the same as last month');
      }
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final categorySpending = getCategorySpending(expenses);
    final monthlySpending = getMonthlySpending(expenses);
    final insights = getInsights(expenses);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Trends', icon: Icon(Icons.show_chart)),
            Tab(text: 'Monthly', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No data to analyze yet'))
          : TabBarView(
              controller: _tabController,
              children: [
                // Pie Chart for Categories
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: categorySpending.entries.map((entry) {
                              final category = getCategoryByName(entry.key);
                              return PieChartSectionData(
                                value: entry.value,
                                title:
                                    '${entry.key}\n${entry.value.toStringAsFixed(0)}',
                                color: category.color,
                                radius: 100,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Line Chart for Trends
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Spending Trends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final months = monthlySpending.keys
                                        .toList();
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < months.length) {
                                      final monthStr = months[value.toInt()];
                                      final monthName = _getMonthName(
                                        int.parse(monthStr.split('-')[1]),
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '${monthName}\n${monthStr.split('-')[0]}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  interval: 1,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: monthlySpending.entries.map((entry) {
                                  final index = monthlySpending.keys
                                      .toList()
                                      .indexOf(entry.key);
                                  return FlSpot(index.toDouble(), entry.value);
                                }).toList(),
                                isCurved: true,
                                color: Colors.teal,
                                barWidth: 4,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.teal.withOpacity(0.1),
                                ),
                                dotData: FlDotData(show: true),
                              ),
                            ],
                            minX: 0,
                            maxX: monthlySpending.length.toDouble() - 1,
                            minY: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bar Chart for Monthly Comparison
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Monthly Spending',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: monthlySpending.values.isEmpty
                                ? 100
                                : (monthlySpending.values.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) *
                                      1.2),
                            barGroups: monthlySpending.entries.map((entry) {
                              final index = monthlySpending.keys
                                  .toList()
                                  .indexOf(entry.key);
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value,
                                    color: Colors.teal,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final months = monthlySpending.keys
                                        .toList();
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < months.length) {
                                      final monthStr = months[value.toInt()];
                                      final monthName = _getMonthName(
                                        int.parse(monthStr.split('-')[1]),
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '${monthName}\n${monthStr.split('-')[0]}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  interval: 1,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: insights.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.teal.shade50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insights',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...insights.map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $insight'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
