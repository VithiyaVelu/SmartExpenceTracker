class RecurringTransaction {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String frequency; // 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly'
  final String type; // 'income' or 'expense'
  final String startDate; // ISO format: yyyy-MM-dd
  final String? endDate; // ISO format: yyyy-MM-dd (optional)
  final int dayOfWeek; // 0-6 for weekly (0=Monday), or day of month for monthly
  final bool isActive;

  RecurringTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.dayOfWeek,
    this.isActive = true,
  });

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'dayOfWeek': dayOfWeek,
      'isActive': isActive ? 1 : 0,
    };
  }

  // Create from map
  factory RecurringTransaction.fromMap(Map<dynamic, dynamic> map) {
    return RecurringTransaction(
      id: map['id'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      frequency: map['frequency'],
      type: map['type'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      dayOfWeek: map['dayOfWeek'],
      isActive: (map['isActive'] ?? 1) == 1,
    );
  }

  // Get next occurrence date
  DateTime getNextOccurrence(DateTime after) {
    DateTime current = DateTime.parse(startDate);

    // Check if recurring has ended
    if (endDate != null) {
      DateTime end = DateTime.parse(endDate!);
      if (after.isAfter(end)) {
        return DateTime(9999); // Return far future date
      }
    }

    while (current.isBefore(after) || current.isAtSameMomentAs(after)) {
      current = _addFrequency(current);
    }

    return current;
  }

  // Add frequency to date
  DateTime _addFrequency(DateTime date) {
    switch (frequency) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'biweekly':
        return date.add(const Duration(days: 14));
      case 'monthly':
        // Move to same day next month, handling month-end cases
        final nextMonth = date.month == 12 ? 1 : date.month + 1;
        final nextYear = date.month == 12 ? date.year + 1 : date.year;
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = dayOfWeek > 0 ? dayOfWeek : date.day;
        return DateTime(nextYear, nextMonth, day > lastDay ? lastDay : day);
      case 'quarterly':
        return DateTime(date.year, date.month + 3, date.day);
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date.add(const Duration(days: 7));
    }
  }

  // Get all occurrences within a date range
  List<DateTime> getOccurrencesInRange(DateTime start, DateTime end) {
    final occurrences = <DateTime>[];
    DateTime current = getNextOccurrence(start);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      occurrences.add(current);
      current = _addFrequency(current);
    }

    return occurrences;
  }

  // Frequency label for display
  String getFrequencyLabel() {
    final labels = {
      'weekly': 'Weekly',
      'biweekly': 'Every 2 Weeks',
      'monthly': 'Monthly',
      'quarterly': 'Quarterly',
      'yearly': 'Yearly',
    };
    return labels[frequency] ?? 'Unknown';
  }

  // Copy with method for creating modified instances
  RecurringTransaction copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    String? frequency,
    String? type,
    String? startDate,
    String? endDate,
    int? dayOfWeek,
    bool? isActive,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isActive: isActive ?? this.isActive,
    );
  }
}
