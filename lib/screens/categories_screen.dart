import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final DBHelper db = DBHelper();
  Map<String, double> categoryTotals = {};

  @override
  void initState() {
    super.initState();
    loadCategoryData();
  }

  Future<void> loadCategoryData() async {
    final expenses = await db.getExpenses();
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      if (expense.type == 'expense') {
        totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
      }
    }

    if (!mounted) return;

    setState(() {
      categoryTotals = totals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Category Breakdown')),
      body: categoryTotals.isEmpty
          ? const Center(child: Text('No expenses yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final category = getCategoryByName(entry.key);
                final percentage = (entry.value / categoryTotals.values.reduce((a, b) => a + b)) * 100;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.2),
                      child: Icon(category.icon, color: category.color),
                    ),
                    title: Text(category.name),
                    subtitle: Text('${percentage.toStringAsFixed(1)}% of total expenses'),
                    trailing: Text(
                      'Rs ${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}