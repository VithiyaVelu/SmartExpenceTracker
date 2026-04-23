import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/category.dart';
import '../utils/transaction_predictor.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final DBHelper db = DBHelper();
  late Future<Map<String, dynamic>> predictionsFuture;

  @override
  void initState() {
    super.initState();
    predictionsFuture = _loadPredictions();
  }

  Future<Map<String, dynamic>> _loadPredictions() async {
    final expenses = await db.getExpenses();
    final recurring = await db.getRecurringTransactions();
    
    final predictions = TransactionPredictor.getAllPredictions(
      expenses,
      recurring,
      30, // Show predictions for 30 days
    );

    // Calculate total predicted expenses
    final totalPredicted = predictions
        .where((p) => p.reason == 'recurring')
        .fold(0.0, (sum, p) => sum + p.amount);

    // Get category trends
    final trends = <String, Map<String, dynamic>>{};
    for (final cat in getCategories()) {
      trends[cat.name] = TransactionPredictor.getCategoryTrend(
        expenses,
        cat.name,
        3,
      );
    }

    return {
      'predictions': predictions,
      'totalPredicted': totalPredicted,
      'trends': trends,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions & Insights'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: predictionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          final data = snapshot.data!;
          final predictions = data['predictions'] as List<PredictionData>;
          final totalPredicted = data['totalPredicted'] as double;
          final trends = data['trends'] as Map<String, Map<String, dynamic>>;

          final recurringOnly = predictions
              .where((p) => p.reason == 'recurring')
              .toList();
          final patternOnly = predictions
              .where((p) => p.reason == 'pattern')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total predicted expenses card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expected in 30 Days',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs ${totalPredicted.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${recurringOnly.length} recurring transactions',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Recurring predictions section
                if (recurringOnly.isNotEmpty) ...[
                  Text(
                    'Recurring Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...recurringOnly.map((prediction) {
                    final category = getCategoryByName(prediction.category);
                    final daysUntil =
                        prediction.predictedDate.difference(DateTime.now()).inDays;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.color.withOpacity(0.2),
                          child: Icon(
                            category.icon,
                            color: category.color,
                          ),
                        ),
                        title: Text(prediction.description),
                        subtitle: Text(
                          'in $daysUntil days • ${prediction.predictedDate.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: Text(
                          'Rs ${prediction.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                // Pattern-based predictions
                if (patternOnly.isNotEmpty) ...[
                  Text(
                    'Pattern-Based Predictions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...patternOnly.map((prediction) {
                    final category = getCategoryByName(prediction.category);
                    final confidence = (prediction.confidence * 100).toInt();
                    final daysUntil =
                        prediction.predictedDate.difference(DateTime.now()).inDays;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.color.withOpacity(0.2),
                          child: Icon(
                            category.icon,
                            color: category.color,
                          ),
                        ),
                        title: Text(prediction.description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'in $daysUntil days • ${prediction.predictedDate.toLocal().toString().split(' ')[0]}',
                            ),
                            LinearProgressIndicator(
                              value: prediction.confidence,
                              minHeight: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                confidence >= 80
                                    ? Colors.green
                                    : confidence >= 60
                                        ? Colors.orange
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs ${prediction.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              '$confidence% confident',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                // Category trends
                Text(
                  'Spending Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...getCategories().map((category) {
                  final trend = trends[category.name];
                  if (trend == null || (trend['trend'] as Map).isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final isIncreasing = trend['isIncreasing'] as bool;
                  final avgAmount = trend['avgAmount'] as double;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withOpacity(0.2),
                        child: Icon(
                          category.icon,
                          color: category.color,
                        ),
                      ),
                      title: Text(category.name),
                      subtitle: Row(
                        children: [
                          Icon(
                            isIncreasing ? Icons.trending_up : Icons.trending_down,
                            size: 16,
                            color: isIncreasing ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isIncreasing ? 'Spending increasing' : 'Spending decreasing',
                            style: TextStyle(
                              color: isIncreasing ? Colors.red : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        'Avg: Rs ${avgAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // Insights
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
                          Icon(Icons.lightbulb, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'AI Insights',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInsights(trends),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsights(Map<String, Map<String, dynamic>> trends) {
    final insights = <String>[];

    // Find categories with increasing spend
    for (final entry in trends.entries) {
      final category = entry.key;
      final trend = entry.value;
      if (trend['isIncreasing'] == true && (trend['trend'] as Map).isNotEmpty) {
        insights.add('$category spending is increasing - consider reviewing');
      }
    }

    // Find high spending categories
    final sortedByAmount = trends.entries.toList()
      ..sort((a, b) =>
          (b.value['avgAmount'] as double)
              .compareTo(a.value['avgAmount'] as double));

    if (sortedByAmount.isNotEmpty) {
      final topCategory = sortedByAmount.first.key;
      final topAmount = sortedByAmount.first.value['avgAmount'] as double;
      insights.add('You spend the most on $topCategory (~Rs ${topAmount.toStringAsFixed(0)}/month)');
    }

    if (insights.isEmpty) {
      insights.add('Keep tracking your expenses to get personalized insights!');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights
          .map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
