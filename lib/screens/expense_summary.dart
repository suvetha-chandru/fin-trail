
import 'package:expense_tracker_client1/provider/daily_expense_provider.dart';
import 'package:expense_tracker_client1/provider/monthly_expense_provider.dart';
import 'package:expense_tracker_client1/widgets/daily_entry_table.dart';
import 'package:expense_tracker_client1/widgets/expense_entry_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseSummary extends ConsumerWidget {  // Changed from StatelessWidget to ConsumerWidget
  const ExpenseSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyEntriesAsync = ref.watch(monthlyEntriesProvider);
    final dailyEntriesAsync = ref.watch(dailyEntriesProvider);
    
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
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Monthly Expenses",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              monthlyEntriesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
                data: (monthlyEntries) => ExpenseTable(entries: monthlyEntries),
              ),
              const SizedBox(height: 40),
              const Text(
                "Daily Expenses",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              dailyEntriesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
                data: (dailyEntries) => DailyEntryTable(dailyEntries: dailyEntries),
              ),
            ],
          ),
        ),
      ),
    );
  }
}