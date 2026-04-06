import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../utils/currency_service.dart';
import '../providers/theme_provider.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> {
  final DBHelper db = DBHelper();
  List<Expense> allExpenses = [];
  
  String selectedPeriod = 'Month'; // Month, Quarter, Year
  DateTime selectedDate = DateTime.now();
  
  Map<String, double> monthlySpending = {};
  Map<String, double> categoryTrends = {};
  double totalYearSpending = 0;
  double averageMonthlySpending = 0;
  double highestMonthSpending = 0;
  String highestSpendingMonth = '';
  
  List<SpendingInsight> insights = [];

  @override
  void initState() {
    super.initState();
    loadAnalyticsData();
  }

  Future<void> loadAnalyticsData() async {
    final expenses = await db.getExpenses();
    
    setState(() {
      allExpenses = expenses;
    });
    
    _calculateMetrics();
    _generateInsights();
  }

  void _calculateMetrics() {
    final monthlyMap = <String, double>{};
    final categoryMap = <String, double>{};
    
    // Group expenses by month
    for (final exp in allExpenses) {
      if (exp.type == 'expense') {
        final amountInBase = CurrencyService.convertToBase(exp.amount, exp.currency);
        final monthKey = exp.date.substring(0, 7); // YYYY-MM
        
        monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0) + amountInBase;
        categoryMap[exp.category] = (categoryMap[exp.category] ?? 0) + amountInBase;
      }
    }
    
    // Calculate statistics
    double yearTotal = 0;
    double maxMonth = 0;
    String maxMonthKey = '';
    
    for (final entry in monthlyMap.entries) {
      yearTotal += entry.value;
      if (entry.value > maxMonth) {
        maxMonth = entry.value;
        maxMonthKey = entry.key;
      }
    }
    
    setState(() {
      monthlySpending = monthlyMap;
      categoryTrends = categoryMap;
      totalYearSpending = yearTotal;
      averageMonthlySpending = monthlyMap.isEmpty ? 0 : yearTotal / monthlyMap.length;
      highestMonthSpending = maxMonth;
      highestSpendingMonth = maxMonthKey;
    });
  }

  void _generateInsights() {
    final newInsights = <SpendingInsight>[];
    
    if (highestMonthSpending > averageMonthlySpending * 1.5) {
      newInsights.add(
        SpendingInsight(
          title: 'High Spending Alert',
          description: '$highestSpendingMonth had ${((highestMonthSpending / averageMonthlySpending - 1) * 100).toStringAsFixed(0)}% higher spending than average',
          severity: 'high',
          icon: Icons.trending_up,
        ),
      );
    }
    
    // Find top spending category
    if (categoryTrends.isNotEmpty) {
      final topCategory = categoryTrends.entries.reduce((a, b) => a.value > b.value ? a : b);
      newInsights.add(
        SpendingInsight(
          title: 'Top Spending Category',
          description: '${topCategory.key} accounts for ${((topCategory.value / totalYearSpending) * 100).toStringAsFixed(0)}% of total spending',
          severity: 'info',
          icon: Icons.pie_chart,
        ),
      );
    }
    
    // Monthly trend analysis
    if (monthlySpending.length >= 2) {
      final sortedMonths = monthlySpending.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      if (sortedMonths.length >= 2) {
        final lastMonth = sortedMonths[sortedMonths.length - 1].value;
        final prevMonth = sortedMonths[sortedMonths.length - 2].value;
        final changePercent = ((lastMonth - prevMonth) / prevMonth * 100);
        
        if (changePercent > 10) {
          newInsights.add(
            SpendingInsight(
              title: 'Spending Increase',
              description: 'Your spending increased by ${changePercent.toStringAsFixed(0)}% compared to last month',
              severity: 'warning',
              icon: Icons.warning,
            ),
          );
        } else if (changePercent < -10) {
          newInsights.add(
            SpendingInsight(
              title: 'Great Job!',
              description: 'You reduced spending by ${(-changePercent).toStringAsFixed(0)}% compared to last month',
              severity: 'success',
              icon: Icons.thumb_up,
            ),
          );
        }
      }
    }
    
    setState(() {
      insights = newInsights;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = CurrencyService.getCurrencyByCode(CurrencyService.baseCurrency)?.symbol ?? '\$';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        backgroundColor: themeProvider.currentTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(themeProvider),
            const SizedBox(height: 24),
            
            // Key Metrics
            _buildKeyMetrics(currencySymbol, themeProvider),
            const SizedBox(height: 24),
            
            // Monthly Spending Chart
            _buildMonthlyChart(themeProvider),
            const SizedBox(height: 24),
            
            // Category Breakdown
            _buildCategoryBreakdown(currencySymbol, themeProvider),
            const SizedBox(height: 24),
            
            // Insights
            _buildInsights(themeProvider),
            const SizedBox(height: 24),
            
            // Spending Patterns
            _buildSpendingPatterns(currencySymbol, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeProvider themeProvider) {
    return Row(
      children: ['Month', 'Quarter', 'Year'].map((period) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedPeriod = period;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPeriod == period
                    ? themeProvider.currentTheme.primaryColor
                    : Colors.grey[300],
                foregroundColor: selectedPeriod == period ? Colors.white : Colors.black,
              ),
              child: Text(period),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyMetrics(String currencySymbol, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Spending',
              '$currencySymbol${totalYearSpending.toStringAsFixed(0)}',
              Colors.red,
              themeProvider,
            ),
            _buildMetricCard(
              'Avg Monthly',
              '$currencySymbol${averageMonthlySpending.toStringAsFixed(0)}',
              Colors.orange,
              themeProvider,
            ),
            _buildMetricCard(
              'Highest Month',
              '$currencySymbol${highestMonthSpending.toStringAsFixed(0)}',
              Colors.deepOrange,
              themeProvider,
            ),
            _buildMetricCard(
              'Categories',
              '${categoryTrends.length}',
              Colors.purple,
              themeProvider,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(ThemeProvider themeProvider) {
    if (monthlySpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No spending data available'),
        ),
      );
    }

    final sortedMonths = monthlySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedMonths.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedMonths[i].value));
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Monthly Spending Trend',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedMonths.length) {
                          return Text(
                            sortedMonths[index].key.substring(5),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox();
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
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.red[400],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(String currencySymbol, ThemeProvider themeProvider) {
    if (categoryTrends.isEmpty) {
      return const SizedBox();
    }

    final sortedCategories = categoryTrends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Category Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...sortedCategories.take(6).map((entry) {
            final percentage = (entry.value / totalYearSpending * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$currencySymbol${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.primaries[entry.key.length % Colors.primaries.length],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsights(ThemeProvider themeProvider) {
    if (insights.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) {
          final color = insight.severity == 'high'
              ? Colors.red
              : insight.severity == 'warning'
                  ? Colors.orange
                  : insight.severity == 'success'
                      ? Colors.green
                      : Colors.blue;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(insight.icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          insight.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSpendingPatterns(String currencySymbol, ThemeProvider themeProvider) {
    final dayOfWeekSpending = <String, double>{
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    for (final exp in allExpenses) {
      if (exp.type == 'expense') {
        final date = DateTime.parse(exp.date);
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayKey = dayNames[date.weekday - 1];
        final amountInBase = CurrencyService.convertToBase(exp.amount, exp.currency);
        dayOfWeekSpending[dayKey] = (dayOfWeekSpending[dayKey] ?? 0) + amountInBase;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Spending by Day of Week',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: dayOfWeekSpending.entries.toList().asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: Colors.blue[400 + (e.key * 100)],
                        width: 12,
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final keys = dayOfWeekSpending.keys.toList();
                        final index = value.toInt();
                        if (index >= 0 && index < keys.length) {
                          return Text(keys[index], style: const TextStyle(fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 100).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 9),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpendingInsight {
  final String title;
  final String description;
  final String severity; // high, warning, info, success
  final IconData icon;

  SpendingInsight({
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
  });
}
