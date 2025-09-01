class DailyModel {
  final String id;
  final String productName;
  final String amount;
  final String category;
  final DateTime date;

  DailyModel({
    required this.id,
    required this.productName,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }
factory DailyModel.fromMap(Map<String, dynamic> map) {
  return DailyModel(
    id: map['id']?.toString() ?? 'unknown_id',  // Handle null
    productName: map['productName']?.toString() ?? 'Unknown Product',  // Handle null
    amount: map['amount']?.toString() ?? '0.00',  // Handle null
    category: map['category']?.toString() ?? 'Uncategorized',  // Handle null
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),  // Handle null
  );
}
}