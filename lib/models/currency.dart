class Currency {
  final String code; // e.g., 'USD', 'EUR', 'GBP'
  final String name; // e.g., 'US Dollar', 'Euro', 'British Pound'
  final String symbol; // e.g., '$', '€', '£'
  final String flag; // e.g., '🇺🇸', '🇪🇺', '🇬🇧'

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      code: map['code'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String,
      flag: map['flag'] as String,
    );
  }

  @override
  String toString() => '$flag $code';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime lastUpdated;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'rate': rate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    return ExchangeRate(
      fromCurrency: map['fromCurrency'] as String,
      toCurrency: map['toCurrency'] as String,
      rate: (map['rate'] as num).toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }
}