import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../models/currency.dart';

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';

  // Common currencies
  static const List<Currency> supportedCurrencies = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
  ];

  static String _baseCurrency = 'USD';
  static Map<String, double> _exchangeRates = {};
  static DateTime? _lastUpdated;

  // Get current base currency
  static String get baseCurrency => _baseCurrency;

  // Set base currency
  static Future<void> setBaseCurrency(String currency) async {
    _baseCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_currency', currency);
    await fetchExchangeRates();
  }

  // Initialize service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseCurrency = prefs.getString('base_currency') ?? 'USD';
    await fetchExchangeRates();
  }

  // Fetch live exchange rates
  static Future<bool> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_baseCurrency'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRates = Map<String, double>.from(data['rates']);
        _lastUpdated = DateTime.now();

        // Cache rates
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('exchange_rates', json.encode(_exchangeRates));
        await prefs.setString('rates_last_updated', _lastUpdated!.toIso8601String());

        return true;
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
      // Try to load cached rates
      await _loadCachedRates();
    }
    return false;
  }

  // Load cached exchange rates
  static Future<void> _loadCachedRates() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRates = prefs.getString('exchange_rates');
    final lastUpdated = prefs.getString('rates_last_updated');

    if (cachedRates != null && lastUpdated != null) {
      _exchangeRates = Map<String, double>.from(json.decode(cachedRates));
      _lastUpdated = DateTime.parse(lastUpdated);
    }
  }

  // Convert amount from one currency to another
  static double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    if (_exchangeRates.isEmpty) return amount;

    // Convert to base currency first, then to target currency
    final toBaseRate = _exchangeRates[fromCurrency] ?? 1.0;
    final fromBaseRate = _exchangeRates[toCurrency] ?? 1.0;

    final amountInBase = amount / toBaseRate;
    return amountInBase * fromBaseRate;
  }

  // Convert amount to base currency
  static double convertToBase(double amount, String fromCurrency) {
    return convert(amount, fromCurrency, _baseCurrency);
  }

  // Convert amount from base currency
  static double convertFromBase(double amount, String toCurrency) {
    return convert(amount, _baseCurrency, toCurrency);
  }

  // Get exchange rate between two currencies
  static double getExchangeRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1.0;
    if (_exchangeRates.isEmpty) return 1.0;

    final toBaseRate = _exchangeRates[fromCurrency] ?? 1.0;
    final fromBaseRate = _exchangeRates[toCurrency] ?? 1.0;

    return fromBaseRate / toBaseRate;
  }

  // Get currency by code
  static Currency? getCurrencyByCode(String code) {
    return supportedCurrencies.firstWhere(
      (currency) => currency.code == code,
      orElse: () => supportedCurrencies.first, // Default to USD
    );
  }

  // Get formatted amount with currency symbol
  static String formatAmount(double amount, String currencyCode) {
    final currency = getCurrencyByCode(currencyCode);
    return '${currency?.symbol ?? '\$'}${amount.toStringAsFixed(2)}';
  }

  // Check if rates are stale (older than 1 hour)
  static bool get areRatesStale {
    if (_lastUpdated == null) return true;
    return DateTime.now().difference(_lastUpdated!) > const Duration(hours: 1);
  }

  // Get exchange rates history for trend analysis
  static Future<Map<String, List<double>>> getCurrencyTrends(String baseCurrency, int days) async {
    // This would typically fetch historical data from an API
    // For now, return mock data
    final trends = <String, List<double>>{};

    for (final currency in supportedCurrencies.where((c) => c.code != baseCurrency)) {
      // Generate mock trend data (in a real app, this would come from an API)
      final rates = <double>[];
      double currentRate = getExchangeRate(baseCurrency, currency.code);

      for (int i = 0; i < days; i++) {
        // Add some random variation for demo purposes
        final variation = (currentRate * 0.02) * (0.5 - (i % 2)); // Simple mock variation
        rates.add(currentRate + variation);
      }

      trends[currency.code] = rates;
    }

    return trends;
  }

  // Analyze currency trends
  static Map<String, dynamic> analyzeCurrencyTrends(Map<String, List<double>> trends) {
    final analysis = <String, dynamic>{};

    for (final entry in trends.entries) {
      final currency = entry.key;
      final rates = entry.value;

      if (rates.length < 2) continue;

      // Calculate trend direction
      final firstRate = rates.first;
      final lastRate = rates.last;
      final change = ((lastRate - firstRate) / firstRate) * 100;

      // Calculate volatility (standard deviation)
      final mean = rates.reduce((a, b) => a + b) / rates.length;
      final variance = rates.map((rate) => (rate - mean) * (rate - mean)).reduce((a, b) => a + b) / rates.length;
      final volatility = math.sqrt(variance);

      analysis[currency] = {
        'changePercent': change,
        'isIncreasing': change > 0,
        'volatility': volatility,
        'currentRate': lastRate,
        'trend': change.abs() > 2 ? (change > 0 ? 'up' : 'down') : 'stable',
      };
    }

    return analysis;
  }
}