import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/category.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DBHelper db = DBHelper();
  final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
  Map<String, double> budgets = {};
  Map<String, double> currentSpending = {};
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // Load expenses
    final allExpenses = await db.getExpenses();
    
    // Load budgets
    final budgetList = await db.getBudgets(currentMonth);
    final Map<String, double> budgetMap = {};
    for (final budget in budgetList) {
      budgetMap[budget.category] = budget.amount;
    }

    // Calculate current month spending by category
    final Map<String, double> spending = {};
    for (final expense in allExpenses) {
      if (expense.type == 'expense' && expense.date.startsWith(currentMonth)) {
        spending[expense.category] = (spending[expense.category] ?? 0) + expense.amount;
      }
    }

    if (!mounted) return;

    setState(() {
      expenses = allExpenses;
      budgets = budgetMap;
      currentSpending = spending;
    });
  }

  Map<String, double> getAverageSpending() {
    final Map<String, double> monthlySpending = {};
    final Map<String, int> monthCount = {};

    for (final expense in expenses) {
      if (expense.type == 'expense') {
        monthlySpending[expense.category] = (monthlySpending[expense.category] ?? 0) + expense.amount;
        monthCount[expense.category] = (monthCount[expense.category] ?? 0) + 1;
      }
    }

    final Map<String, double> average = {};
    for (final category in monthlySpending.keys) {
      average[category] = monthlySpending[category]! / monthCount[category]!;
    }

    return average;
  }

  Future<void> suggestBudgets() async {
    final average = getAverageSpending();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Budget Suggestions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: average.entries.map((entry) {
              final suggested = entry.value * 1.2; // 20% buffer
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('Rs ${suggested.toStringAsFixed(0)}'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyBudgetSuggestions(average);
            },
            child: const Text('Apply All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyBudgetSuggestions(Map<String, double> average) async {
    for (final entry in average.entries) {
      final suggested = entry.value * 1.2; // 20% buffer
      final budget = Budget(
        category: entry.key,
        amount: suggested,
        month: currentMonth,
      );
      await db.insertBudget(budget);
    }
    await loadData();
  }

  Future<void> setBudget(String category, double amount) async {
    if (amount <= 0) return;
    
    final budget = Budget(
      category: category,
      amount: amount,
      month: currentMonth,
    );
    
    await db.insertBudget(budget);
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb),
            tooltip: 'Smart Suggestions',
            onPressed: () {
              if (expenses.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add transactions to get budget suggestions')),
                );
              } else {
                suggestBudgets();
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: predefinedCategories.length,
        itemBuilder: (context, index) {
          final category = predefinedCategories[index];
          final budget = budgets[category.name] ?? 0;
          final spent = currentSpending[category.name] ?? 0;
          final percentage = budget > 0 ? (spent / budget * 100).clamp(0, 100) : 0;
          
          Color progressColor = Colors.green;
          String statusText = 'On Track';
          
          if (budget > 0) {
            if (spent >= budget) {
              progressColor = Colors.red;
              statusText = 'Over Budget';
            } else if ((spent / budget) >= 0.8) {
              progressColor = Colors.orange;
              statusText = 'Warning';
            }
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: category.color.withOpacity(0.2),
                        child: Icon(category.icon, color: category.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (budget > 0)
                              Text(
                                'Rs ${spent.toStringAsFixed(0)} / Rs ${budget.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (budget > 0)
                        Text(
                          statusText,
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (budget > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  BudgetInputField(
                    category: category.name,
                    currentBudget: budget,
                    onSet: (amount) => setBudget(category.name, amount),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BudgetInputField extends StatefulWidget {
  final String category;
  final double currentBudget;
  final Function(double) onSet;

  const BudgetInputField({
    Key? key,
    required this.category,
    required this.currentBudget,
    required this.onSet,
  }) : super(key: key);

  @override
  State<BudgetInputField> createState() => _BudgetInputFieldState();
}

class _BudgetInputFieldState extends State<BudgetInputField> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.currentBudget > 0 ? widget.currentBudget.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Set budget',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(controller.text);
            if (amount != null && amount > 0) {
              widget.onSet(amount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Budget for ${widget.category} set to Rs ${amount.toStringAsFixed(0)}')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
