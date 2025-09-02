import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeExpenseScreen extends ConsumerStatefulWidget {
  const HomeExpenseScreen({super.key});

  @override
  ConsumerState<HomeExpenseScreen> createState() => _HomeExpenseScreenState();
}

class _HomeExpenseScreenState extends ConsumerState<HomeExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final expenseController = TextEditingController();
  final amountController = TextEditingController();

  @override
  void dispose() {
    expenseController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final expenseText = expenseController.text.trim();
    final amountText = amountController.text.trim();

    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (expenseText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expense.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('homeExpenses').add({
        'expense': expenseText,
        'amount': amountText,
        'date': DateTime.now(),
      });

      // Clear form after successful submission
      expenseController.clear();
      amountController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home expense saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save expense: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteHomeExpense(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('homeExpenses')
          .doc(id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home expense deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete home expense')),
      );
    }
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 28, 24, 34),
          title: const Text(
            "Delete Home Expense",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to delete this home expense?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                _deleteHomeExpense(id);
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
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
                          TextFormField(
                            controller: expenseController,
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
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('homeExpenses')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
        
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
                      }
        
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No home expenses yet',
                          style: TextStyle(color: Colors.white),
                        );
                      }
        
                      final expenses = snapshot.data!.docs;
        
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: IntrinsicWidth(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: DataTable(
                              columnSpacing: 42,
                              headingRowColor: WidgetStateColor.resolveWith(
                                (states) => Color.fromARGB(255, 18, 14, 24),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text('Expense', style: TextStyle(color: Colors.white)),
                                ),
                                DataColumn(
                                  label: Text('Amount', style: TextStyle(color: Colors.white)),
                                ),
                                DataColumn(
                                  label: Center(
                                    child: Text('Date', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                DataColumn(
                                  label: Center(
                                    child: Text('Action', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                              rows: expenses.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final date = data['date'] != null 
                                    ? (data['date'] as Timestamp).toDate()
                                    : DateTime.now();
                                
                                // Ensure all fields have values to prevent the error
                                final expense = data['expense']?.toString() ?? 'N/A';
                                final amount = data['amount']?.toString() ?? 'N/A';
                                final dateString = '${date.day}/${date.month}/${date.year}';
                                
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Center(
                                        child: Text(
                                          expense,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Text(
                                          amount,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Text(
                                          dateString,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _showDeleteDialog(doc.id),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}