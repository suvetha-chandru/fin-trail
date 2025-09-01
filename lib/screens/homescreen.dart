import 'package:expense_tracker_client1/provider/budget_provider.dart'
    as budget_providers;
import 'package:expense_tracker_client1/provider/daily_expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker_client1/widgets/daily_entry_table.dart';

class Homescreen extends ConsumerStatefulWidget {
  const Homescreen({super.key});

  @override
  ConsumerState<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends ConsumerState<Homescreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Helper function to safely convert to double
  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _refreshData() async {
    ref.invalidate(budget_providers.budgetInitializerProvider);
    ref.invalidate(dailyEntriesProvider);
    ref.invalidate(budget_providers.grocerySpentProvider);
    ref.invalidate(budget_providers.lunchSpentProvider);
    ref.invalidate(budget_providers.otherSpentProvider);
    ref.invalidate(budget_providers.remainingBudgetsProvider);
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    // Watch all providers at the top level
    final grocerySpent = ref.watch(budget_providers.grocerySpentProvider);
    final lunchSpent = ref.watch(budget_providers.lunchSpentProvider);
    final othersSpent = ref.watch(budget_providers.otherSpentProvider);
    final remainingBudgets = ref.watch(budget_providers.remainingBudgetsProvider);
    final groceryBudget = ref.watch(budget_providers.groceryBudgetProvider);
    final lunchBudget = ref.watch(budget_providers.lunchBudgetProvider);
    final othersBudget = ref.watch(budget_providers.othersBudgetProvider);

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
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildBudgetTile('Grocery', 'grocery', grocerySpent, groceryBudget, remainingBudgets),
                _buildBudgetTile('Lunch', 'lunch', lunchSpent, lunchBudget, remainingBudgets),
                _buildBudgetTile('Others', 'others', othersSpent, othersBudget, remainingBudgets),
                _buildTotalBudgetTile(grocerySpent, lunchSpent, othersSpent, groceryBudget, lunchBudget, othersBudget),
                const SizedBox(height: 20),
                _buildRecentExpenses(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentExpenses() {
    final dailyEntriesAsync = ref.watch(dailyEntriesProvider);

    return dailyEntriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (allEntries) {
        final last20Entries = allEntries.length > 20
            ? allEntries.sublist(0, 20)
            : allEntries;

        if (last20Entries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Recent Expenses',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DailyEntryTable(dailyEntries: last20Entries),
          ],
        );
      },
    );
  }

  Widget _buildBudgetTile(String label, String category, double spent, double budget, Map<String, double> remainingBudgets) {
    final remaining = _toDouble(remainingBudgets[category] ?? 0.0);

    return Card(
      color: const Color.fromARGB(255, 28, 24, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Budget: ₹${budget.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Spent: ₹${spent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 239, 193, 53),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Remaining: ₹${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: remaining < 0 ? Colors.red : Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBudgetTile(double grocerySpent, double lunchSpent, double othersSpent, 
                              double groceryBudget, double lunchBudget, double othersBudget) {
    final totalBudget = groceryBudget + lunchBudget + othersBudget;
    final totalSpent = grocerySpent + lunchSpent + othersSpent;
    final remaining = totalBudget - totalSpent;

    return Card(
      color: const Color.fromARGB(255, 28, 24, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Budget: ₹${totalBudget.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Spent: ₹${totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 239, 193, 53),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Remaining: ₹${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: remaining < 0 ? Colors.red : Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}