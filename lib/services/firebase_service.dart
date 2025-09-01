import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/daily_model.dart';
import '../models/monthly_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Budgets
  Future<void> saveBudgets({
    required double grocery,
    required double lunch,
    required double others,
  }) async {
    await _firestore.collection('budgets').doc('current').set({
      'grocery': grocery,
      'lunch': lunch,
      'others': others,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, double>> getBudgets() async {
    final doc = await _firestore.collection('budgets').doc('current').get();
    if (doc.exists) {
      return {
        'grocery': (doc.data()?['grocery'] as num?)?.toDouble() ?? 0.0,
        'lunch': (doc.data()?['lunch'] as num?)?.toDouble() ?? 0.0,
        'others': (doc.data()?['others'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {'grocery': 0.0, 'lunch': 0.0, 'others': 0.0};
  }

  // Daily Expenses
  Future<void> addDailyExpense(DailyModel expense) async {
    await _firestore
        .collection('dailyExpenses')
        .doc(expense.id)
        .set(expense.toMap());
  }

  Stream<List<DailyModel>> getDailyExpenses() {
    return _firestore
        .collection('dailyExpenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Monthly Expenses
  Future<void> addMonthlyExpense(ExpenseEntry entry) async {
    await FirebaseFirestore.instance
        .collection('monthlyExpenses')
        .doc(entry.id)
        .set(entry.toMap());
  }

  Stream<List<ExpenseEntry>> getMonthlyExpenses() {
    return FirebaseFirestore.instance
        .collection('monthlyExpenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseEntry.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveSpendingTotals({
    required double grocery,
    required double lunch,
    required double others,
  }) async {
    await _firestore.collection('spendingTotals').doc('current').set({
      'grocery': grocery,
      'lunch': lunch,
      'others': others,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, double>> getSpendingTotals() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('spendingTotals')
          .doc('current')
          .get();

      if (!doc.exists) {
        // Initialize with default values if document doesn't exist
        await _initializeSpendingTotals();
        return {'grocery': 0.0, 'lunch': 0.0, 'others': 0.0};
      }

      return {
        'grocery': (doc.data()?['grocery'] as num?)?.toDouble() ?? 0.0,
        'lunch': (doc.data()?['lunch'] as num?)?.toDouble() ?? 0.0,
        'others': (doc.data()?['others'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error getting spending totals: $e');
      return {'grocery': 0.0, 'lunch': 0.0, 'others': 0.0};
    }
  }

  Future<void> _initializeSpendingTotals() async {
    await FirebaseFirestore.instance
        .collection('spendingTotals')
        .doc('current')
        .set({'grocery': 0.0, 'lunch': 0.0, 'others': 0.0});
  }
}
