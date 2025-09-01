import 'package:expense_tracker_client1/models/monthly_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTable extends StatefulWidget {
  final List<ExpenseEntry> entries;

  const ExpenseTable({super.key, required this.entries});

  @override
  State<ExpenseTable> createState() => _ExpenseTableState();
}

class _ExpenseTableState extends State<ExpenseTable> {
  Future<void> _deleteMonthlyEntry(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('monthlyExpenses')
          .doc(id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Monthly expense deleted successfully!")),
        );
      }
    } catch (e) {
      debugPrint('Error deleting monthly entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete monthly expense")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                label: Text('Title', style: TextStyle(color: Colors.white)),
              ),
              DataColumn(
                label: Text('Amount', style: TextStyle(color: Colors.white)),
              ),
              DataColumn(
                label: Text('Category', style: TextStyle(color: Colors.white)),
              ),
              DataColumn(
                label: Text(
                  'Sub-Category',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DataColumn(
                label: Center(
                  child: Text('Action', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
            rows: widget.entries
                .map(
                  (e) => DataRow(
                    cells: [
                      DataCell(
                        Center(
                          child: Text(
                            e.title,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            e.amount,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            e.category,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            e.subCategory,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteDialog(context, e.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 28, 24, 34),
          title: Text(
            "Delete Monthly Expense",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Are you sure you want to delete this monthly expense?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                _deleteMonthlyEntry(id);
                Navigator.of(dialogContext).pop();
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}