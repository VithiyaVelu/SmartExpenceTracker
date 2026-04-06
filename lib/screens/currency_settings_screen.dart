import 'package:flutter/material.dart';
import '../utils/currency_service.dart';
import '../models/currency.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _selectedCurrency = CurrencyService.baseCurrency;
  bool _isLoading = false;
  Map<String, dynamic>? _currencyTrends;
  bool _showTrends = false;

  @override
  void initState() {
    super.initState();
    _loadCurrencyTrends();
  }

  Future<void> _loadCurrencyTrends() async {
    setState(() => _isLoading = true);
    try {
      final trends = await CurrencyService.getCurrencyTrends(
        CurrencyService.baseCurrency,
        30, // Last 30 days
      );
      final analysis = CurrencyService.analyzeCurrencyTrends(trends);

      setState(() {
        _currencyTrends = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading currency trends: $e')),
        );
      }
    }
  }

  Future<void> _changeBaseCurrency(String currency) async {
    setState(() => _isLoading = true);
    try {
      await CurrencyService.setBaseCurrency(currency);
      setState(() {
        _selectedCurrency = currency;
        _showTrends = false;
        _currencyTrends = null;
      });
      await _loadCurrencyTrends();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base currency updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating currency: $e')),
        );
      }
    }
  }

  Future<void> _refreshExchangeRates() async {
    setState(() => _isLoading = true);
    final success = await CurrencyService.fetchExchangeRates();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Exchange rates updated successfully'
              : 'Failed to update exchange rates'),
        ),
      );
    }
  }

  Widget _buildCurrencySelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Base Currency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your primary currency for expense tracking and analysis',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: CurrencyService.supportedCurrencies.map((currency) {
                return DropdownMenuItem(
                  value: currency.code,
                  child: Row(
                    children: [
                      Text(currency.flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('${currency.code} - ${currency.name}'),
                      const SizedBox(width: 8),
                      Text(currency.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null && value != _selectedCurrency) {
                        _changeBaseCurrency(value);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateStatus() {
    final isStale = CurrencyService.areRatesStale;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Exchange Rates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  isStale ? Icons.warning : Icons.check_circle,
                  color: isStale ? Colors.orange : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isStale
                  ? 'Exchange rates may be outdated. Update for latest rates.'
                  : 'Exchange rates are up to date.',
              style: TextStyle(color: isStale ? Colors.orange : Colors.green),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _refreshExchangeRates,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Update Rates'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTrends() {
    if (_currencyTrends == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Currency Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showTrends = !_showTrends),
                  icon: Icon(_showTrends ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
            if (_showTrends) ...[
              const SizedBox(height: 16),
              ..._currencyTrends!.entries.map((entry) {
                final currency = entry.key;
                final data = entry.value as Map<String, dynamic>;
                final changePercent = data['changePercent'] as double;
                final trend = data['trend'] as String;
                final volatility = data['volatility'] as double;

                Color trendColor;
                IconData trendIcon;
                switch (trend) {
                  case 'up':
                    trendColor = Colors.green;
                    trendIcon = Icons.trending_up;
                    break;
                  case 'down':
                    trendColor = Colors.red;
                    trendIcon = Icons.trending_down;
                    break;
                  default:
                    trendColor = Colors.grey;
                    trendIcon = Icons.trending_flat;
                }

                return ListTile(
                  leading: Icon(trendIcon, color: trendColor),
                  title: Text(currency),
                  subtitle: Text(
                    'Change: ${changePercent.toStringAsFixed(2)}% | Volatility: ${volatility.toStringAsFixed(3)}',
                  ),
                  trailing: Text(
                    '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading && _currencyTrends == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrencySelector(),
                  _buildExchangeRateStatus(),
                  _buildCurrencyTrends(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}