class Expense {
  int? id;
  int? recurringId;
  String title;
  double amount;
  String type;
  String date;
  String category;
  String currency; // Currency code (e.g., 'USD', 'EUR')

  Expense({
    this.id,
    this.recurringId,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.currency = 'USD', // Default to USD
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'date': date,
      'category': category,
      'currency': currency,
      if (recurringId != null) 'recurring_id': recurringId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final recurringValue = map['recurring_id'] ?? map['recurringId'];

    return Expense(
      id: map['id'] as int?,
      recurringId:
          recurringValue == null ? null : (recurringValue as num).toInt(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      date: map['date'] as String,
      category: map['category'] as String? ?? 'Other',
      currency: map['currency'] as String? ?? 'USD',
    );
  }
}
