import 'package:expense_tracker_client1/models/daily_model.dart';
import 'package:expense_tracker_client1/models/monthly_model.dart';
import 'package:expense_tracker_client1/screens/daily_expense.dart';
import 'package:expense_tracker_client1/screens/expense_summary.dart';
import 'package:expense_tracker_client1/screens/homeScreen.dart';
import 'package:expense_tracker_client1/screens/home_expense_screen.dart';
import 'package:expense_tracker_client1/screens/monthly_log_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker_client1/screens/plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker_client1/provider/budget_provider.dart'
    as budget_providers;
import 'package:expense_tracker_client1/provider/daily_expense_provider.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageConsumerState();
}

class _HomepageConsumerState extends ConsumerState<Homepage> {
  List<ExpenseEntry> entries = [];
  List<DailyModel> dailyEntries = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _formattedDate;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _formattedDate = DateFormat('MMMM yyyy').format(now);
  }

  int _selectedIndex = 0;

  List<Widget> get _pages => [
    Homescreen(),
    DailyExpense(),
    MonthlyLogPage(),
    ExpenseSummary(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _resetAllData() async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Reset All Data?"),
            content: const Text(
              "This will delete ALL expenses and reset budgets.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Reset", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. First completely clear all collections
      final collectionsToDelete = [
        'budgets',
        'dailyExpenses',
        'monthlyExpenses',
        'homeExpenses', // ADDED: Include home expenses in reset
        'spendingTotals',
        'remainingBudgets',
      ];

      final batch = _firestore.batch();

      for (var collection in collectionsToDelete) {
        final snapshot = await _firestore.collection(collection).get();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();

      // 2. Create fresh documents WITHOUT merge
      await Future.wait([
        _firestore.collection('budgets').doc('current').set({
          'grocery': 0.0,
          'lunch': 0.0,
          'others': 0.0,
          'timestamp': FieldValue.serverTimestamp(),
        }),

        _firestore.collection('spendingTotals').doc('current').set({
          'grocery': 0.0,
          'lunch': 0.0,
          'others': 0.0,
        }),

        _firestore.collection('remainingBudgets').doc('current').set({
          'grocery': 0.0,
          'lunch': 0.0,
          'others': 0.0,
        }),
      ]);

      // 3. Force UI refresh by invalidating all relevant providers
      if (mounted) {
        // First close the loading dialog
        Navigator.of(context).pop();

        // Then show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data reset successfully!')),
        );

        // Invalidate all providers to force refresh
        ref.invalidate(budget_providers.budgetInitializerProvider);
        ref.invalidate(dailyEntriesProvider);
        ref.invalidate(budget_providers.groceryBudgetProvider);
        ref.invalidate(budget_providers.lunchBudgetProvider);
        ref.invalidate(budget_providers.othersBudgetProvider);
        ref.invalidate(budget_providers.grocerySpentProvider);
        ref.invalidate(budget_providers.lunchSpentProvider);
        ref.invalidate(budget_providers.otherSpentProvider);
        ref.invalidate(budget_providers.remainingBudgetsProvider);

        // Also refresh the current page if needed
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting data: ${e.toString()}')),
        );
      }
      debugPrint('Reset error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Color.fromARGB(255, 18, 14, 24),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 18, 14, 24)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      'Expense Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "- by S ❤️",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            
            ListTile(
              leading: Icon(Icons.money, color: Colors.white),
              title: Text('Set Budget', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlanScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text(
                'Home Expenses',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeExpenseScreen()),
                );
              },
            ),
            // Add the new refresh button here
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white),
              title: const Text(
                'Reset for New Month',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _resetAllData();
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 18, 14, 24),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: const Color.fromARGB(255, 126, 30, 195),
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // ✅ This opens the drawer
            },
          ),
        ),

        title: Text(
          _formattedDate,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _onItemTapped(1),
                  icon: Icon(
                    Icons.calendar_month_sharp,
                    color: const Color.fromARGB(255, 126, 30, 195),
                  ),
                ),
                IconButton(
                  onPressed: () => _onItemTapped(3),
                  icon: Icon(
                    Icons.note_alt_outlined,
                    color: const Color.fromARGB(255, 126, 30, 195),
                  ),
                ),
                IconButton(
                  onPressed: () => _onItemTapped(2),
                  icon: Icon(
                    Icons.add,
                    color: const Color.fromARGB(255, 126, 30, 195),
                  ),
                ),
              ],
            ),
          ),
        ],
        automaticallyImplyLeading: false, // ✅ hide default back icon
        elevation: 2,
      ),

      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color.fromARGB(255, 18, 14, 24),
        type: BottomNavigationBarType
            .fixed, // ✅ Needed for custom background to apply
        selectedItemColor: Color.fromARGB(255, 126, 30, 195),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            label: "Daily Expense",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Monthly Log",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Summary",
          ),
        ],
      ),
    );
  }
}