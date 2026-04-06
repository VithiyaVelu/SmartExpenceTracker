class Budget {
  int? id;
  String category;
  double amount;
  String month; // YYYY-MM format

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
    );
  }
}
