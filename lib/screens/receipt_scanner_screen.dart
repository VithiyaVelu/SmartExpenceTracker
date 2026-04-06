import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../utils/receipt_parser.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final TextEditingController _textController = TextEditingController();
  ReceiptData? _parsedData;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseReceipt() {
    if (_textController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate processing delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final parsed = ReceiptParser.parseReceiptText(_textController.text);
      setState(() {
        _parsedData = parsed;
        _isLoading = false;
      });
    });
  }

  void _saveExpense() async {
    if (_parsedData == null) return;
    
    final expense = Expense(
      title: _parsedData!.merchant,
      amount: _parsedData!.amount,
      type: 'expense',
      date: _parsedData!.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
      category: _parsedData!.category,
    );
    
    final db = DBHelper();
    await db.insertExpense(expense);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully!')),
      );
      setState(() {
        _parsedData = null;
        _textController.clear();
      });
    }
  }

  Widget _buildParsedField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              // Text Input for Receipt
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paste Receipt Text',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _textController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'Paste the text from your receipt here...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _parseReceipt,
                        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                        label: Text(_isLoading ? 'Parsing...' : 'Parse Receipt'),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_parsedData != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parsed Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildParsedField('Merchant', _parsedData!.merchant),
                        _buildParsedField('Amount', '₹${_parsedData!.amount.toStringAsFixed(2)}'),
                        _buildParsedField('Category', _parsedData!.category),
                        _buildParsedField('Date', _parsedData!.date?.toString() ?? 'Not found'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _parsedData = null),
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveExpense,
                                child: const Text('Save Expense'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),

              // Features Coming Soon Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upcoming Features:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildFeatureItem(
                '📷',
                'Auto Receipt Scanning',
                'Capture receipts with your camera',
              ),
              _buildFeatureItem(
                '🔍',
                'Smart Amount Detection',
                'Automatically extract total amounts',
              ),
              _buildFeatureItem(
                '🏪',
                'Store Recognition',
                'Identify merchant names automatically',
              ),
              _buildFeatureItem(
                '📅',
                'Date Extraction',
                'Pull transaction dates from receipts',
              ),
              _buildFeatureItem(
                '🏷️',
                'Category Suggestion',
                'Auto-categorize based on content',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

