import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

// Helper function to safely convert to double
double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// Budget Providers - explicitly set as double
final groceryBudgetProvider = StateProvider<double>((ref) => 0.0); // Changed to 0.0
final lunchBudgetProvider = StateProvider<double>((ref) => 0.0);   // Changed to 0.0
final othersBudgetProvider = StateProvider<double>((ref) => 0.0);  // Changed to 0.0

final budgetInitializerProvider = FutureProvider<void>((ref) async {
  final service = ref.read(firebaseServiceProvider);
  final budgets = await service.getBudgets();
  ref.read(groceryBudgetProvider.notifier).state = _toDouble(budgets['grocery']);
  ref.read(lunchBudgetProvider.notifier).state = _toDouble(budgets['lunch']);
  ref.read(othersBudgetProvider.notifier).state = _toDouble(budgets['others']);
});

// Spending Providers
final grocerySpentProvider = StateNotifierProvider<SpendingNotifier, double>((ref) {
  return SpendingNotifier(0.0, 'grocery', ref);
});

final lunchSpentProvider = StateNotifierProvider<SpendingNotifier, double>((ref) {
  return SpendingNotifier(0.0, 'lunch', ref);
});

final otherSpentProvider = StateNotifierProvider<SpendingNotifier, double>((ref) {
  return SpendingNotifier(0.0, 'others', ref);
});

// Remaining Budget Provider
final remainingBudgetsProvider = StateNotifierProvider<RemainingBudgetNotifier, Map<String, double>>((ref) {
  return RemainingBudgetNotifier(ref);
});

class SpendingNotifier extends StateNotifier<double> {
  final String category;
  final Ref ref;
  
  SpendingNotifier(super.state, this.category, this.ref) {
    _initialize();
  }

  Future<void> _initialize() async {
    final totals = await ref.read(firebaseServiceProvider).getSpendingTotals();
    state = _toDouble(totals[category]);
  }

  void add(double amount) {
    state += amount;
    _saveToFirestore();
    _updateRemainingBudget();
  }

  void subtract(double amount) {
    state -= amount; // This subtracts from the spent total
    _saveToFirestore();
    _updateRemainingBudget(); // This should update the remaining budget
  }

  void reset(double value) {
    state = value;
    _saveToFirestore();
    _updateRemainingBudget();
  }

  Future<void> _saveToFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('spendingTotals')
          .doc('current')
          .set({
            category: state,
          }, SetOptions(merge: true));
    } catch (e) {
      // Error handling can be added here if needed
    }
  }

  void _updateRemainingBudget() {
    final budget = ref.read(
      category == 'grocery' ? groceryBudgetProvider :
      category == 'lunch' ? lunchBudgetProvider :
      othersBudgetProvider
    );
    
    // Calculate remaining: budget - spent
    final remaining = _toDouble(budget) - state;
    
    // Update the remaining budget
    ref.read(remainingBudgetsProvider.notifier).updateRemaining(
      category, 
      remaining
    );
  }
}

class RemainingBudgetNotifier extends StateNotifier<Map<String, double>> {
  final Ref ref;
  
  RemainingBudgetNotifier(this.ref) : super({'grocery': 0.0, 'lunch': 0.0, 'others': 0.0}) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('remainingBudgets')
          .doc('current')
          .get();

      if (doc.exists) {
        state = {
          'grocery': _toDouble(doc.data()?['grocery']),
          'lunch': _toDouble(doc.data()?['lunch']),
          'others': _toDouble(doc.data()?['others']),
        };
      } else {
        // Initialize with calculated values if document doesn't exist
        await _calculateInitialRemainingBudgets();
      }
    } catch (e) {
      await _calculateInitialRemainingBudgets();
    }
  }

  Future<void> _calculateInitialRemainingBudgets() async {
    try {
      // Get budgets
      final budgetsDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc('current')
          .get();
      
      // Get spending totals
      final spendingDoc = await FirebaseFirestore.instance
          .collection('spendingTotals')
          .doc('current')
          .get();

      final groceryBudget = _toDouble(budgetsDoc.data()?['grocery'] ?? 0.0);
      final lunchBudget = _toDouble(budgetsDoc.data()?['lunch'] ?? 0.0);
      final othersBudget = _toDouble(budgetsDoc.data()?['others'] ?? 0.0);

      final grocerySpent = _toDouble(spendingDoc.data()?['grocery'] ?? 0.0);
      final lunchSpent = _toDouble(spendingDoc.data()?['lunch'] ?? 0.0);
      final othersSpent = _toDouble(spendingDoc.data()?['others'] ?? 0.0);

      state = {
        'grocery': groceryBudget - grocerySpent,
        'lunch': lunchBudget - lunchSpent,
        'others': othersBudget - othersSpent,
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('remainingBudgets')
          .doc('current')
          .set(state);
    } catch (e) {
      // Error handling can be added here if needed
    }
  }

  Future<void> updateRemaining(String category, double value) async {
    state = {...state, category: value};
    
    try {
      await FirebaseFirestore.instance
          .collection('remainingBudgets')
          .doc('current')
          .set({
            category: value,
          }, SetOptions(merge: true));
    } catch (e) {
      // Error handling can be added here if needed
    }
  }

  Future<void> recalculateAllRemainingBudgets() async {
    try {
      // Get budgets
      final budgetsDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc('current')
          .get();
      
      // Get spending totals
      final spendingDoc = await FirebaseFirestore.instance
          .collection('spendingTotals')
          .doc('current')
          .get();

      final groceryBudget = _toDouble(budgetsDoc.data()?['grocery'] ?? 0.0);
      final lunchBudget = _toDouble(budgetsDoc.data()?['lunch'] ?? 0.0);
      final othersBudget = _toDouble(budgetsDoc.data()?['others'] ?? 0.0);

      final grocerySpent = _toDouble(spendingDoc.data()?['grocery'] ?? 0.0);
      final lunchSpent = _toDouble(spendingDoc.data()?['lunch'] ?? 0.0);
      final othersSpent = _toDouble(spendingDoc.data()?['others'] ?? 0.0);

      final newState = {
        'grocery': groceryBudget - grocerySpent,
        'lunch': lunchBudget - lunchSpent,
        'others': othersBudget - othersSpent,
      };

      state = newState;

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('remainingBudgets')
          .doc('current')
          .set(newState);
    } catch (e) {
      // Error handling can be added here if needed
    }
  }
}