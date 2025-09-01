import 'package:expense_tracker_client1/models/daily_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/budget_provider.dart';

class DailyEntryTable extends ConsumerStatefulWidget {
  final List<DailyModel> dailyEntries;
  const DailyEntryTable({super.key, required this.dailyEntries});

  @override
  ConsumerState<DailyEntryTable> createState() => _DailyEntryTableState();
}

class _DailyEntryTableState extends ConsumerState<DailyEntryTable> {
  // Track active delete operations to cancel them if needed
  final Map<String, Future<void>> _activeDeletes = {};

  @override
  void dispose() {
    // Cancel any ongoing delete operations when widget is disposed
    _activeDeletes.clear();
    super.dispose();
  }

  Future<void> _deleteDailyEntry(String id, String category, String amount) async {
    // Store the future to track this operation
    final deleteFuture = _performDeleteOperation(id, category, amount);
    _activeDeletes[id] = deleteFuture;
    
    try {
      await deleteFuture;
    } finally {
      // Remove from tracking map when done
      _activeDeletes.remove(id);
    }
  }

  Future<void> _performDeleteOperation(String id, String category, String amount) async {
    try {
      // Convert category to lowercase to match provider categories
      final categoryLower = category.toLowerCase();
      final parsedAmount = double.tryParse(amount) ?? 0.0;
      
      // 1. First update the app state (subtract from spent)
      if (categoryLower == "grocery") {
        ref.read(grocerySpentProvider.notifier).subtract(parsedAmount);
      } else if (categoryLower == "lunch") {
        ref.read(lunchSpentProvider.notifier).subtract(parsedAmount);
      } else if (categoryLower == "others") {
        ref.read(otherSpentProvider.notifier).subtract(parsedAmount);
      }

      // 2. Then delete from Firebase
      await FirebaseFirestore.instance
          .collection('dailyExpenses')
          .doc(id)
          .delete();
      
      // Check if widget is still mounted before showing messages
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense deleted successfully!")),
      );

    } catch (e) {
      // Show error message only if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete expense")),
        );
      }
      rethrow;
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
                label: Text('Amount', style: TextStyle(color: Colors.white)),
              ),
              DataColumn(
                label: Text(
                  'Product Name',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DataColumn(
                label: Text('Category', style: TextStyle(color: Colors.white)),
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
            rows: widget.dailyEntries
                .map(
                  (e) => DataRow(
                    cells: [
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
                            e.productName,
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
                            '${e.date.day}/${e.date.month}/${e.date.year}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteDialog(e.id, e.category, e.amount),
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

  void _showDeleteDialog(String id, String category, String amount) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 28, 24, 34),
          title: Text(
            "Delete Expense",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Are you sure you want to delete this expense?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                _deleteDailyEntry(id, category, amount);
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