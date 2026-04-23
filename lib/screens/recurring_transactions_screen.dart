import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/recurring_transaction.dart';
import '../models/category.dart';
import '../utils/currency_service.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final DBHelper db = DBHelper();
  List<RecurringTransaction> recurringTransactions = [];

  @override
  void initState() {
    super.initState();
    loadRecurringTransactions();
  }

  Future<void> loadRecurringTransactions() async {
    final data = await db.getRecurringTransactions();
    if (!mounted) return;
    setState(() {
      recurringTransactions = data
        ..sort((a, b) {
          // Sort by frequency, then by category
          final freqOrder = {
            'weekly': 0,
            'biweekly': 1,
            'monthly': 2,
            'quarterly': 3,
            'yearly': 4,
          };
          final aOrder = freqOrder[a.frequency] ?? 5;
          final bOrder = freqOrder[b.frequency] ?? 5;
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          return a.category.compareTo(b.category);
        });
    });
  }

  Future<void> deleteRecurring(RecurringTransaction recurring) async {
    if (recurring.id == null) return;
    await db.deleteRecurringTransaction(recurring.id!);
    await loadRecurringTransactions();
  }

  Future<void> toggleActive(RecurringTransaction recurring) async {
    if (recurring.id == null) return;
    final updated = recurring.copyWith(isActive: !recurring.isActive);
    await db.updateRecurringTransaction(updated);
    await loadRecurringTransactions();
  }

  void _showAddRecurringDialog() {
    showDialog(
      context: context,
      builder: (_) => AddRecurringDialog(
        onSave: (_) {
          loadRecurringTransactions();
        },
      ),
    );
  }

  void _showEditRecurringDialog(RecurringTransaction recurring) {
    showDialog(
      context: context,
      builder: (_) => AddRecurringDialog(
        recurring: recurring,
        onSave: (_) {
          loadRecurringTransactions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = recurringTransactions.where((r) => r.isActive).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions'), elevation: 0),
      body: Column(
        children: [
          // Summary card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.teal.shade400, Colors.teal.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Recurring',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$activeCount transactions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // List of recurring transactions
          Expanded(
            child: recurringTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.repeat, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No recurring transactions',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recurringTransactions.length,
                    itemBuilder: (context, index) {
                      final recurring = recurringTransactions[index];
                      final category = getCategoryByName(recurring.category);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: category.color.withOpacity(0.2),
                            child: Icon(category.icon, color: category.color),
                          ),
                          title: Text(recurring.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${recurring.getFrequencyLabel()} • ${recurring.category}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                CurrencyService.formatBaseAmount(
                                  recurring.amount,
                                  fractionDigits: 0,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: recurring.type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () {
                                  _showEditRecurringDialog(recurring);
                                },
                              ),
                              PopupMenuItem(
                                child: Text(
                                  recurring.isActive
                                      ? 'Deactivate'
                                      : 'Activate',
                                ),
                                onTap: () {
                                  toggleActive(recurring);
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('Delete'),
                                onTap: () {
                                  deleteRecurring(recurring);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _showEditRecurringDialog(recurring);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecurringDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddRecurringDialog extends StatefulWidget {
  final RecurringTransaction? recurring;
  final Function(RecurringTransaction) onSave;

  const AddRecurringDialog({super.key, this.recurring, required this.onSave});

  @override
  State<AddRecurringDialog> createState() => _AddRecurringDialogState();
}

class _AddRecurringDialogState extends State<AddRecurringDialog> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  late String selectedCategory;
  late String selectedFrequency;
  late String selectedType;
  late DateTime startDate;
  late DateTime? endDate;
  late int dayOfMonth;
  final DBHelper db = DBHelper();

  final frequencies = ['weekly', 'biweekly', 'monthly', 'quarterly', 'yearly'];
  final frequencyLabels = {
    'weekly': 'Weekly',
    'biweekly': 'Every 2 Weeks',
    'monthly': 'Monthly',
    'quarterly': 'Quarterly',
    'yearly': 'Yearly',
  };

  @override
  void initState() {
    super.initState();
    if (widget.recurring != null) {
      titleController = TextEditingController(text: widget.recurring!.title);
      amountController = TextEditingController(
        text: widget.recurring!.amount.toString(),
      );
      selectedCategory = widget.recurring!.category;
      selectedFrequency = widget.recurring!.frequency;
      selectedType = widget.recurring!.type;
      startDate = DateTime.parse(widget.recurring!.startDate);
      endDate = widget.recurring!.endDate != null
          ? DateTime.parse(widget.recurring!.endDate!)
          : null;
      dayOfMonth = widget.recurring!.dayOfWeek;
    } else {
      titleController = TextEditingController();
      amountController = TextEditingController();
      selectedCategory = 'Food';
      selectedFrequency = 'monthly';
      selectedType = 'expense';
      startDate = DateTime.now();
      endDate = null;
      dayOfMonth = DateTime.now().day;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (titleController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final recurring = RecurringTransaction(
      id: widget.recurring?.id,
      title: titleController.text,
      amount: double.parse(amountController.text),
      category: selectedCategory,
      frequency: selectedFrequency,
      type: selectedType,
      startDate: startDate.toIso8601String().split('T')[0],
      endDate: endDate?.toIso8601String().split('T')[0],
      dayOfWeek: dayOfMonth,
      isActive: widget.recurring?.isActive ?? true,
    );

    await db.updateRecurringTransaction(recurring);
    if (mounted) {
      widget.onSave(recurring);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.recurring == null
                    ? 'Add Recurring Transaction'
                    : 'Edit Recurring Transaction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Monthly subscription',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefix: Text('${CurrencyService.baseCurrencySymbol} '),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedType,
                      items: ['income', 'expense']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  color: type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedType = value);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                value: selectedCategory,
                items: getCategories()
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat.name,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 20, color: cat.color),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategory = value);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                value: selectedFrequency,
                items: frequencies
                    .map(
                      (freq) => DropdownMenuItem(
                        value: freq,
                        child: Text(frequencyLabels[freq] ?? freq),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedFrequency = value);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        '${startDate.day}/${startDate.month}/${startDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Set end date?'),
                value: endDate != null,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      endDate = DateTime.now().add(const Duration(days: 365));
                    } else {
                      endDate = null;
                    }
                  });
                },
              ),
              if (endDate != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(
                    '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate!,
                      firstDate: startDate,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.recurring == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
