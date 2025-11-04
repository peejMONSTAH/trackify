import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Tips'),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 8),
          _buildSection(
            context,
            'Getting Started',
            'How to use Trackify:\n\n'
            '1. Tap the + button to add a new expense\n'
            '2. Fill in all required fields (title, amount, date, category)\n'
            '3. Select a category from the available options\n'
            '4. Save your expense\n',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            'Managing Expenses',
            '• Tap Edit icon to modify expenses\n'
            '• Tap Delete icon to remove expenses\n'
            '• View all your expenses in the home screen\n'
            '• Use the search and filter options to find specific expenses\n',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            'Statistics',
            '• View your total expenses in the drawer\n'
            '• See monthly expenses breakdown\n'
            '• Check category-wise spending\n'
            '• Refresh data anytime using the refresh option\n',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            'Data Storage',
            '• All expenses are stored locally on your device\n'
            '• Your data is secure and private\n'
            '• No internet connection required for basic features\n'
            '• Backup your data regularly\n',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Constants.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

