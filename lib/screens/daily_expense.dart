import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_client1/models/daily_model.dart';
import 'package:expense_tracker_client1/provider/budget_provider.dart';
import 'package:expense_tracker_client1/provider/daily_expense_provider.dart';
import 'package:expense_tracker_client1/widgets/daily_entry_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DailyExpense extends ConsumerStatefulWidget {
  const DailyExpense({super.key});

  @override
  ConsumerState<DailyExpense> createState() => _DailyExpenseState();
}

class _DailyExpenseState extends ConsumerState<DailyExpense> {
  String selectedDailyCategory = "Grocery";
  final List<String> dailyCategory = ["Grocery", "Lunch", "Others"];

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  late TextEditingController _dateController;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = _formattedDate;
      });
    }
  }

  String get _formattedDate {
    if (_selectedDate == null) return '';
    return DateFormat('dd MMM yyyy').format(_selectedDate!);
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitDailyForm() async {
    final product = titleController.text.trim();
    final amount = amountController.text.trim();

    if (product.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a product name")),
      );
      return;
    }
    if (amount.isEmpty || double.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid number")),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a Date")),
      );
      return;
    }

    final newEntry = DailyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: product,
      amount: amount,
      category: selectedDailyCategory,
      date: _selectedDate!,
    );

    try {
      await FirebaseFirestore.instance
          .collection('dailyExpenses')
          .doc(newEntry.id)
          .set(newEntry.toMap());

      final parsedAmount = double.tryParse(amount) ?? 0.0;
      if (selectedDailyCategory == "Grocery") {
        ref.read(grocerySpentProvider.notifier).add(parsedAmount);
      } else if (selectedDailyCategory == "Lunch") {
        ref.read(lunchSpentProvider.notifier).add(parsedAmount);
      } else if (selectedDailyCategory == "Others") {
        ref.read(otherSpentProvider.notifier).add(parsedAmount);
      }

      // Clear form after submission
      titleController.clear();
      amountController.clear();
      setState(() {
        _selectedDate = null;
        _dateController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense saved successfully!")),
      );
    } catch (e) {
      debugPrint('Failed to save: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save expense")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyEntriesAsync = ref.watch(dailyEntriesProvider);

    return dailyEntriesAsync.when(
      loading: () => _buildLoadingScreen(),
      error: (err, stack) => _buildErrorScreen(err),
      data: (dailyEntries) => _buildMainScreen(dailyEntries),
    );
  }

  Widget _buildMainScreen(List<DailyModel> dailyEntries) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 18, 14, 24),
              Color.fromARGB(255, 18, 14, 24),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          maxLength: 50,
                          style: const TextStyle(color: Colors.white),
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: "Product Name",
                            hintStyle: const TextStyle(color: Colors.white38),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          maxLength: 50,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Product Price",
                            hintStyle: const TextStyle(color: Colors.white38),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: const Color.fromARGB(255, 103, 99, 99),
                          value: selectedDailyCategory,
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white,
                          decoration: InputDecoration(
                            labelText: "Category",
                            labelStyle: const TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: dailyCategory.map((String dailycategory) {
                            return DropdownMenuItem<String>(
                              value: dailycategory,
                              child: Text(dailycategory),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedDailyCategory = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                controller: _dateController,
                                onTap: _pickDate,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  labelStyle: const TextStyle(color: Colors.white38),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.white,
                              ),
                              onPressed: _pickDate,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        const Color.fromARGB(255, 126, 30, 195),
                      ),
                      minimumSize: WidgetStateProperty.all<Size>(const Size(140, 40)),
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    onPressed: _submitDailyForm,
                    child: const Text(
                      "Enter",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (dailyEntries.isNotEmpty)
                    DailyEntryTable(dailyEntries: dailyEntries),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen(dynamic error) {
    return Scaffold(
      body: Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}