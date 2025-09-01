import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker_client1/provider/budget_provider.dart';

class PlanScreen extends ConsumerStatefulWidget {
   const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final groceryController = TextEditingController();
  final lunchController = TextEditingController();
  final othersController = TextEditingController();

  void saveBudget() {
    final groceryValue = double.tryParse(groceryController.text);
    final lunchValue = double.tryParse(lunchController.text);
    final othersValue = double.tryParse(othersController.text);

    if (groceryValue == null || lunchValue == null || othersValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter valid numbers in all fields")),
      );
      return;
    }

    ref.read(groceryBudgetProvider.notifier).state = groceryValue;
    ref.read(lunchBudgetProvider.notifier).state = lunchValue;
    ref.read(othersBudgetProvider.notifier).state = othersValue;
    final firebaseService = ref.read(firebaseServiceProvider);
    firebaseService.saveBudgets(
      grocery: groceryValue,
      lunch: lunchValue,
      others: othersValue,
    );

    groceryController.clear();
    lunchController.clear();
    othersController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Budget saved successfully!')));

    Navigator.pop(context);
  }

  @override
  void dispose() {
    groceryController.dispose();
    lunchController.dispose();
    othersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 18, 14, 24),
              Color.fromARGB(255, 18, 14, 24),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Set Your Budget',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            _buildBudgetInput('Grocery Budget', groceryController),
            _buildBudgetInput('Lunch Budget', lunchController),
            _buildBudgetInput('Others Budget', othersController),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    const Color.fromARGB(255, 126, 30, 195),
                  ),
                  minimumSize: WidgetStateProperty.all<Size>(Size(80, 40)),
                  padding: WidgetStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                onPressed: saveBudget,
                child: const Text(
                  'Save Budgets',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildBudgetInput(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: TextField(
      style: TextStyle(color: Colors.white),
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    ),
  );
}
