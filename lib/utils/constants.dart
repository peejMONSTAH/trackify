import 'package:flutter/material.dart';

class Constants {
  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  static Map<String, IconData> get categoryIcons => {
        'Food': Icons.restaurant,
        'Transport': Icons.directions_car,
        'Shopping': Icons.shopping_bag,
        'Bills': Icons.receipt,
        'Entertainment': Icons.movie,
        'Health': Icons.local_hospital,
        'Education': Icons.school,
        'Other': Icons.category,
      };

  static Map<String, Color> get categoryColors => {
        'Food': Colors.orange,
        'Transport': Colors.blue,
        'Shopping': Colors.pink,
        'Bills': Colors.red,
        'Entertainment': Colors.purple,
        'Health': Colors.green,
        'Education': Colors.teal,
        'Other': Colors.grey,
      };
}
