import '../models/expense.dart';
import '../models/recurring_transaction.dart';
import 'currency_service.dart';

class PredictionData {
  final String description;
  final double amount;
  final String category;
  final DateTime predictedDate;
  final String reason; // 'recurring' or 'pattern'
  final double confidence; // 0-1 for pattern predictions

  PredictionData({
    required this.description,
    required this.amount,
    required this.category,
    required this.predictedDate,
    required this.reason,
    required this.confidence,
  });
}

class TransactionPredictor {
  // Predict upcoming transactions based on recurring transactions
  static List<PredictionData> predictFromRecurring(
    List<RecurringTransaction> recurring,
    int daysAhead,
  ) {
    final predictions = <PredictionData>[];
    final today = DateTime.now();
    final endDate = today.add(Duration(days: daysAhead));

    for (final rec in recurring) {
      if (!rec.isActive) continue;

      final occurrences = rec.getOccurrencesInRange(today, endDate);
      for (final date in occurrences) {
        // Skip if date is in the past (today is already counted)
        if (date.isBefore(today)) continue;

        predictions.add(PredictionData(
          description: rec.title,
          amount: rec.amount,
          category: rec.category,
          predictedDate: date,
          reason: 'recurring',
          confidence: 1.0, // Recurring transactions have 100% confidence
        ));
      }
    }

    return predictions;
  }
//Forecasts upcoming transactions so users can see what money 
//they'll likely need to spend in the future.
  // Smart prediction based on historical patterns
  static List<PredictionData> predictFromPatterns(
    List<Expense> expenses,
    int daysAhead,
  ) {
    final predictions = <PredictionData>[];
    final today = DateTime.now();
    final endDate = today.add(Duration(days: daysAhead));

    // Analyze expenses by category and find patterns
    final categoryPatterns = _analyzePatterns(expenses);

    for (final entry in categoryPatterns.entries) {
      final category = entry.key;
      final pattern = entry.value;

      if (pattern['frequency'] < 0.5) {
        // Not frequent enough to predict (appears less than 50% of cycles)
        continue;
      }

      // Estimate next occurrence and amount
      final nextDate = _estimateNextOccurrence(expenses, category, today);
      if (nextDate != null && nextDate.isBefore(endDate)) {
        final avgAmount = pattern['avgAmount'] as double;
        final confidence = (pattern['frequency'] as double).clamp(0.5, 1.0);

        predictions.add(PredictionData(
          description: 'Predicted $category expense',
          amount: avgAmount,
          category: category,
          predictedDate: nextDate,
          reason: 'pattern',
          confidence: confidence,
        ));
      }
    }

    return predictions;
  }

  // Analyze transaction patterns by category
  static Map<String, Map<String, dynamic>> _analyzePatterns(
    List<Expense> expenses,
  ) {
    final patterns = <String, Map<String, dynamic>>{};
    final today = DateTime.now();
    final last90Days = today.subtract(const Duration(days: 90));

    // Filter expenses from last 90 days
    final recentExpenses =
        expenses.where((e) => e.type == 'expense').toList();

    // Group by category
    final byCategory = <String, List<Expense>>{};
    for (final expense in recentExpenses) {
      if (!byCategory.containsKey(expense.category)) {
        byCategory[expense.category] = [];
      }
      byCategory[expense.category]!.add(expense);
    }

    // Analyze each category
    for (final entry in byCategory.entries) {
      final category = entry.key;
      final categoryExpenses = entry.value;

      final sortedDates = categoryExpenses
          .map((e) => DateTime.parse(e.date))
          .toList()
        ..sort();

      if (sortedDates.isEmpty) continue;

      // Convert all amounts to base currency for consistent analysis
      final amountsInBase = categoryExpenses.map((e) =>
          CurrencyService.convertToBase(e.amount, e.currency)).toList();

      // Calculate average amount (in base currency)
      final total = amountsInBase.fold(0.0, (sum, amount) => sum + amount);
      final avgAmount = total / categoryExpenses.length;

      // Calculate frequency (how often it appears)
      final frequency = categoryExpenses.length / 13; // Normalized to ~ weeks
      final clampedFrequency = (frequency / 3).clamp(0.0, 1.0);

      // Calculate gap between transactions (in days)
      int totalGap = 0;
      for (int i = 1; i < sortedDates.length; i++) {
        totalGap += sortedDates[i].difference(sortedDates[i - 1]).inDays;
      }
      final avgGap = sortedDates.length > 1
          ? (totalGap / (sortedDates.length - 1)).round()
          : 30;

      patterns[category] = {
        'avgAmount': avgAmount,
        'frequency': clampedFrequency,
        'avgGap': avgGap,
        'lastDate': sortedDates.last,
        'count': categoryExpenses.length,
      };
    }

    return patterns;
  }

  // Estimate next occurrence for a category
  static DateTime? _estimateNextOccurrence(
    List<Expense> expenses,
    String category,
    DateTime after,
  ) {
    final categoryExpenses = expenses
        .where((e) => e.category == category && e.type == 'expense')
        .toList();

    if (categoryExpenses.isEmpty) return null;

    final sortedExpenses = categoryExpenses
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedExpenses.isEmpty) return null;

    // Get last transaction date
    final lastDate = DateTime.parse(sortedExpenses.first.date);

    // Calculate average gap between transactions
    int totalGap = 0;
    int gaps = 0;
    for (int i = 1; i < sortedExpenses.length && i < 5; i++) {
      final date1 = DateTime.parse(sortedExpenses[i - 1].date);
      final date2 = DateTime.parse(sortedExpenses[i].date);
      totalGap += date1.difference(date2).inDays;
      gaps++;
    }

    if (gaps == 0) return null;

    final avgGap = (totalGap / gaps).round();

    // Estimate next occurrence
    var nextDate = lastDate.add(Duration(days: avgGap));

    // If it's in the past, add more gaps until it's in the future
    while (nextDate.isBefore(after)) {
      nextDate = nextDate.add(Duration(days: avgGap));
    }

    return nextDate;
  }

  // Combine all predictions and sort by date
  static List<PredictionData> getAllPredictions(
    List<Expense> expenses,
    List<RecurringTransaction> recurring,
    int daysAhead,
  ) {
    final predictions = <PredictionData>[];

    // Get predictions from recurring transactions
    predictions.addAll(predictFromRecurring(recurring, daysAhead));

    // Get predictions from patterns
    predictions.addAll(predictFromPatterns(expenses, daysAhead));

    // Remove duplicates and sort by date
    final uniquePredictions = <PredictionData>[];
    final seen = <String>{};

    predictions.sort((a, b) => a.predictedDate.compareTo(b.predictedDate));

    for (final prediction in predictions) {
      final key =
          '${prediction.category}_${prediction.predictedDate.toIso8601String().split('T')[0]}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniquePredictions.add(prediction);
      }
    }

    return uniquePredictions;
  }

  // Get spending trend for a category
  static Map<String, dynamic> getCategoryTrend(
    List<Expense> expenses,
    String category,
    int monthsBack,
  ) {
    final expensesInCategory =
        expenses.where((e) => e.category == category && e.type == 'expense');

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - monthsBack, 1);

    final trend = <String, double>{};

    for (int i = 0; i <= monthsBack; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      if (date.isBefore(startDate)) break;

      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthExpenses = expensesInCategory
          .where((e) => e.date.startsWith(monthKey))
          .map((e) => CurrencyService.convertToBase(e.amount, e.currency))
          .fold(0.0, (sum, amount) => sum + amount);

      trend[monthKey] = monthExpenses;
    }

    // Calculate trend (increasing/decreasing)
    var isIncreasing = false;
    double avgAmount = 0;

    if (trend.isNotEmpty) {
      avgAmount = trend.values.fold(0.0, (sum, e) => (sum as double) + e) /
          trend.length;

      final values = trend.values.toList();
      if (values.length > 1) {
        isIncreasing =
            values.first > values.last; // First month vs last month
      }
    }

    return {
      'trend': trend,
      'isIncreasing': isIncreasing,
      'avgAmount': avgAmount,
    };
  }
}
