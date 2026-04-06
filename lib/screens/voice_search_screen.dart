import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';

class VoiceSearchScreen extends StatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen> {
  final DBHelper db = DBHelper();
  String transcribedText = '';
  bool isListening = false;
  List<Expense> searchResults = [];
  List<Expense> allExpenses = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final expenses = await db.getExpenses();
    setState(() {
      allExpenses = expenses;
    });
  }

  void performVoiceSearch(String text) {
    final query = text.toLowerCase();
    final results = allExpenses.where((e) =>
        e.title.toLowerCase().contains(query) ||
        e.category.toLowerCase().contains(query) ||
        e.amount.toString().contains(query)).toList();

    setState(() {
      searchResults = results;
    });
  }

  void simulateVoiceInput() {
    // Simulate voice search with common phrases
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Input Simulation'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What do you want to search?',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              transcribedText = value;
            });
          },
          onSubmitted: (value) {
            Navigator.pop(context);
            performVoiceSearch(value);
            setState(() {
              transcribedText = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              performVoiceSearch(transcribedText);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Search'),
      ),
      body: Column(
        children: [
          // Voice input section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade300, Colors.teal.shade600],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: simulateVoiceInput,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.shade400.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      size: 50,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isListening ? 'Listening...' : 'Tap to search by voice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Transcribed text display
          if (transcribedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('You said:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            transcribedText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search results
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Text(
                      transcribedText.isEmpty
                          ? 'Start voice search to find transactions'
                          : 'No results found for "$transcribedText"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Found ${searchResults.length} result${searchResults.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...searchResults.map((expense) {
                        final isIncome = expense.type == 'income';
                        final category = getCategoryByName(expense.category);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: category.color.withOpacity(0.2),
                              child: Icon(
                                category.icon,
                                color: category.color,
                              ),
                            ),
                            title: Text(expense.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(expense.date),
                                Text(
                                  expense.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}Rs ${expense.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
