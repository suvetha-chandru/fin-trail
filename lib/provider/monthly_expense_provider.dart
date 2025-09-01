import 'package:expense_tracker_client1/provider/budget_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_model.dart';


final monthlyEntriesProvider = StreamProvider<List<ExpenseEntry>>((ref) {
  return ref.read(firebaseServiceProvider).getMonthlyExpenses();
});