import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/utils/currency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    // Initialize with mock data for testing
    await CurrencyService.initialize();
  });

  test('Base currency conversion', () {
    // Test converting USD to USD (should be 1:1)
    expect(CurrencyService.convertToBase(100, 'USD'), equals(100));

    // Test converting EUR to USD (mock rate)
    final eurToUsd = CurrencyService.convertToBase(100, 'EUR');
    expect(eurToUsd, isNotNull);
    expect(eurToUsd, greaterThan(0));
  });

  test('Currency formatting', () {
    expect(CurrencyService.formatAmount(100.50, 'USD'), equals('\$100.50'));
    expect(CurrencyService.formatAmount(50.25, 'EUR'), equals('€50.25'));
  });

  test('Supported currencies', () {
    expect(CurrencyService.supportedCurrencies.length, greaterThan(5));
    expect(CurrencyService.getCurrencyByCode('USD'), isNotNull);
    expect(CurrencyService.getCurrencyByCode('EUR'), isNotNull);
  });

  test('Exchange rate retrieval', () {
    final usdToEur = CurrencyService.getExchangeRate('USD', 'EUR');
    expect(usdToEur, greaterThan(0));
  });
}