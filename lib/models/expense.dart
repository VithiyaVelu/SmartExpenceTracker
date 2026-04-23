class Expense {
  int? id;
  String title;
  double amount;
  String type;
  String date;
  String category;
  String currency; // Currency code (e.g., 'USD', 'EUR')

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.currency = 'USD', // Default to USD
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'date': date,
      'category': category,
      'currency': currency,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      date: map['date'] as String,
      category: map['category'] as String? ?? 'Other',
      currency: map['currency'] as String? ?? 'USD',
    );
  }
}
