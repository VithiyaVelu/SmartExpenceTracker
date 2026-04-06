import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'voice_search_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final DBHelper db = DBHelper();
  List<Expense> allExpenses = [];
  List<Expense> filteredExpenses = [];
  
  final searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedCategories = [];
  double minAmount = 0;
  double maxAmount = 10000;
  String sortBy = 'date'; // date, amount, category
  bool isVoiceSearching = false;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final expenses = await db.getExpenses();
    setState(() {
      allExpenses = expenses;
      filteredExpenses = expenses;
    });
  }

  void applyFilters() {
    List<Expense> result = allExpenses;

    // Filter by search text
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();
      result = result.where((e) =>
          e.title.toLowerCase().contains(query) ||
          e.amount.toString().contains(query)).toList();
    }

    // Filter by date range
    if (startDate != null) {
      result = result.where((e) {
        final expenseDate = DateTime.parse(e.date);
        return expenseDate.isAfter(startDate!) || expenseDate.isAtSameMomentAs(startDate!);
      }).toList();
    }
    if (endDate != null) {
      result = result.where((e) {
        final expenseDate = DateTime.parse(e.date);
        return expenseDate.isBefore(endDate!.add(const Duration(days: 1))) ||
            expenseDate.isAtSameMomentAs(endDate!);
      }).toList();
    }

    // Filter by category
    if (selectedCategories.isNotEmpty) {
      result = result.where((e) => selectedCategories.contains(e.category)).toList();
    }

    // Filter by amount range
    result = result.where((e) => e.amount >= minAmount && e.amount <= maxAmount).toList();

    // Sort
    switch (sortBy) {
      case 'date':
        result.sort((a, b) => b.date.compareTo(a.date)); // newest first
        break;
      case 'amount':
        result.sort((a, b) => b.amount.compareTo(a.amount)); // highest first
        break;
      case 'category':
        result.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    setState(() {
      filteredExpenses = result;
    });
  }

  Future<void> pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (result != null) {
      setState(() {
        startDate = result.start;
        endDate = result.end;
      });
      applyFilters();
    }
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      startDate = null;
      endDate = null;
      selectedCategories = [];
      minAmount = 0;
      maxAmount = 10000;
      sortBy = 'date';
      filteredExpenses = allExpenses;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Voice search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: clearFilters,
            tooltip: 'Clear filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter panel
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title or amount',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    applyFilters();
                  },
                ),
                const SizedBox(height: 16),

                // Date Range Filter
                GestureDetector(
                  onTap: pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            startDate != null && endDate != null
                                ? '${DateFormat('MMM d').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}'
                                : 'Select date range',
                          ),
                        ),
                        if (startDate != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                startDate = null;
                                endDate = null;
                              });
                              applyFilters();
                            },
                            icon: const Icon(Icons.close, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Filter
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: predefinedCategories.map((cat) {
                    final isSelected = selectedCategories.contains(cat.name);
                    return FilterChip(
                      avatar: Icon(cat.icon, size: 18),
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(cat.name);
                          } else {
                            selectedCategories.add(cat.name);
                          }
                        });
                        applyFilters();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Amount Range Filter
                const Text('Amount Range', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Min',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onChanged: (value) {
                          minAmount = double.tryParse(value) ?? 0;
                          applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Max',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onChanged: (value) {
                          maxAmount = double.tryParse(value) ?? 10000;
                          applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sort By
                const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Date'),
                      selected: sortBy == 'date',
                      onSelected: (_) {
                        setState(() => sortBy = 'date');
                        applyFilters();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Amount'),
                      selected: sortBy == 'amount',
                      onSelected: (_) {
                        setState(() => sortBy = 'amount');
                        applyFilters();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Category'),
                      selected: sortBy == 'category',
                      onSelected: (_) {
                        setState(() => sortBy = 'category');
                        applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results count and list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Results: ${filteredExpenses.length}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          // Filtered results list
          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(
                    child: Text('No transactions match your filters'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
