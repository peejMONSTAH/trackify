import 'package:flutter/material.dart';

class Constants {
  // Trackify Brand Colors (matching logo)
  static const Color primaryBlue = Color(0xFF1E40AF); // Deep vibrant blue
  static const Color primaryBlueLight = Color(0xFF3B82F6); // Lighter blue variant
  static const Color primaryBlueDark = Color(0xFF1E3A8A); // Darker blue variant
  static const Color accentGreen = Color(0xFF84CC16); // Vibrant lime green
  static const Color accentGreenLight = Color(0xFFA3E635); // Lighter lime green
  static const Color accentGreenDark = Color(0xFF65A30D); // Darker lime green

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
