import 'package:expense_tracker_client1/models/monthly_model.dart';
import 'package:expense_tracker_client1/provider/budget_provider.dart';
import 'package:expense_tracker_client1/provider/monthly_expense_provider.dart';
import 'package:expense_tracker_client1/widgets/expense_entry_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonthlyLogPage extends ConsumerStatefulWidget {
  const MonthlyLogPage({super.key});

  @override
  ConsumerState<MonthlyLogPage> createState() => _MonthlyLogPageState();
}

class _MonthlyLogPageState extends ConsumerState<MonthlyLogPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  String selectedMonth = "January";
  String selectedCategory = "Savings";
  String selectedSubCategory = "Mutual Funds";

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final List<String> category = ['Savings', 'House', 'Extras'];

  final Map<String, List<String>> subCategories = {
    'Savings': ['Mutual Funds', 'Gold'],
    'House': ['Rent', 'Grocery', 'Lunch', 'Current Bill'],
    'Extras': ['Gym', 'Entertainment', 'Mobile Recharge'],
  };

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final titleText = titleController.text.trim();
    final amountText = amountController.text.trim();

    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (selectedCategory.isEmpty || selectedSubCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both category and subcategory.')),
      );
      return;
    }

    final newEntry = ExpenseEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      month: selectedMonth,
      title: titleText,
      category: selectedCategory,
      subCategory: selectedSubCategory,
      amount: amountText,
    );

    try {
      await ref.read(firebaseServiceProvider).addMonthlyExpense(newEntry);
      
      // Clear form after successful submission
      titleController.clear();
      amountController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully!')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error saving to Firestore: $e');
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save expense: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyEntriesAsync = ref.watch(monthlyEntriesProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedMonth,
                          dropdownColor: const Color.fromARGB(255, 103, 99, 99),
                          decoration: const InputDecoration(
                            labelText: "Select Month",
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white,
                          items: months.map((String month) {
                            return DropdownMenuItem<String>(
                              value: month,
                              child: Text(
                                month,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedMonth = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: titleController,
                          maxLength: 50,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter The Expense",
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Category Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCategory,
                                dropdownColor: const Color.fromARGB(255, 103, 99, 99),
                                decoration: const InputDecoration(
                                  labelText: "Category",
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                iconEnabledColor: Colors.white,
                                items: category.map((String cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(
                                      cat,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedCategory = newValue!;
                                    selectedSubCategory = subCategories[selectedCategory]!.first;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Sub-Category Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedSubCategory,
                                dropdownColor: const Color.fromARGB(255, 103, 99, 99),
                                decoration: const InputDecoration(
                                  labelText: "Sub-Category",
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                iconEnabledColor: Colors.white,
                                items: subCategories[selectedCategory]!
                                    .map((String sub) => DropdownMenuItem<String>(
                                          value: sub,
                                          child: Text(
                                            sub,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedSubCategory = val!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: "Amount",
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
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 45,
                              width: 100,
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all<Color>(
                                    const Color.fromARGB(255, 24, 1, 28)),
                                  minimumSize: WidgetStateProperty.all<Size>(const Size(10, 10)),
                                  padding: WidgetStateProperty.all<EdgeInsets>(
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                                onPressed: _submitForm,
                                child: const Text(
                                  "Enter",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                monthlyEntriesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Text(
                        'No monthly expenses yet',
                        style: TextStyle(color: Colors.white),
                      );
                    }
                    return ExpenseTable(entries: entries);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}