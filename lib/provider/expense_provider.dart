import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_model.dart';

final dailyExpenseProvider = StateNotifierProvider<DailyExpenseNotifier, List<DailyModel>>(
  (ref) => DailyExpenseNotifier(),
);

class DailyExpenseNotifier extends StateNotifier<List<DailyModel>> {
  DailyExpenseNotifier() : super([]);

  // Helper function to safely convert to double
  double _safeParseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }

  void addEntry(DailyModel entry) {
    state = [...state, entry];
  }

  void clearEntries() {
    state = [];
  }

  double totalForCategory(String category) {
    return state
      .where((entry) => entry.category == category)
      .fold(0.0, (sum, entry) => sum + _safeParseDouble(entry.amount));
  }
}
