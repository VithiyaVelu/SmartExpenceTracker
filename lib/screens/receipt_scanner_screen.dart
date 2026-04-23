import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/receipt_ocr.dart';
import '../utils/receipt_parser.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ReceiptOcr _receiptOcr = createReceiptOcr();

  ReceiptData? _parsedData;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseReceiptText() {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste or scan a receipt first.')),
      );
      return;
    }

    setState(() {
      _parsedData = ReceiptParser.parseReceiptText(rawText);
    });
  }

  Future<void> _scanReceiptFromImage(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(source: source);
    if (pickedImage == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final extractedText = await _receiptOcr.extractText(pickedImage);
      if (!mounted) {
        return;
      }

      if (extractedText.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No receipt text was detected in that image.'),
          ),
        );
        return;
      }

      _textController.text = extractedText;
      _parseReceiptText();
    } on UnsupportedError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? error.toString())),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not scan receipt: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveExpense() async {
    if (_parsedData == null) {
      return;
    }

    final expense = Expense(
      title: _parsedData!.merchant,
      amount: _parsedData!.amount,
      type: 'expense',
      date:
          _parsedData!.date?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      category: _parsedData!.category,
    );

    await context.read<ExpenseProvider>().addExpense(expense);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense saved successfully!')),
    );

    Navigator.pop(context, true);
  }

  void _clearParsedData() {
    setState(() {
      _parsedData = null;
    });
  }

  Widget _buildParsedField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan or Paste Receipt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        kIsWeb
                            ? 'Use pasted receipt text on web.'
                            : 'Pick a receipt image or paste the OCR text here.',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => _scanReceiptFromImage(
                                      ImageSource.camera,
                                    ),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Scan Camera'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => _scanReceiptFromImage(
                                      ImageSource.gallery,
                                    ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Upload Image'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
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
                        onPressed: _isLoading ? null : _parseReceiptText,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isLoading ? 'Scanning...' : 'Parse Receipt',
                        ),
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
                        _buildParsedField(
                          'Amount',
                          '\u20B9${_parsedData!.amount.toStringAsFixed(2)}',
                        ),
                        _buildParsedField('Category', _parsedData!.category),
                        _buildParsedField(
                          'Date',
                          _parsedData!.date?.toIso8601String() ?? 'Not found',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearParsedData,
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upcoming Features:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.camera_alt,
                'Auto Receipt Scanning',
                'Capture receipts with your camera',
              ),
              _buildFeatureItem(
                Icons.search,
                'Smart Amount Detection',
                'Automatically extract total amounts',
              ),
              _buildFeatureItem(
                Icons.store,
                'Store Recognition',
                'Identify merchant names automatically',
              ),
              _buildFeatureItem(
                Icons.event,
                'Date Extraction',
                'Pull transaction dates from receipts',
              ),
              _buildFeatureItem(
                Icons.local_offer,
                'Category Suggestion',
                'Auto-categorize based on content',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
