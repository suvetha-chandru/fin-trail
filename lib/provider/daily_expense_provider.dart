import 'package:expense_tracker_client1/provider/budget_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_model.dart';

final dailyEntriesProvider = StreamProvider<List<DailyModel>>((ref) {
  return ref.read(firebaseServiceProvider).getDailyExpenses();
});