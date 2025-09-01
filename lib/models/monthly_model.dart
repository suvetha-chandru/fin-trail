import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseEntry {
  final String id;  // Add this
  final String month;
  final String title;
  final String category;
  final String subCategory;
  final String amount;

  ExpenseEntry({
    required this.id,  // Add this
    required this.month,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'title': title,
      'category': category,
      'subCategory': subCategory,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExpenseEntry.fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: map['id'],
      month: map['month'],
      title: map['title'],
      category: map['category'],
      subCategory: map['subCategory'],
      amount: map['amount'],
    );
  }
}