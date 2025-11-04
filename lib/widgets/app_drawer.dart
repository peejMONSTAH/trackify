import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';
import '../screens/settings_screen.dart';
import '../screens/expense_calendar_screen.dart';
import '../screens/spending_limit_screen.dart';

class AppDrawer extends StatefulWidget {
  final String userId;
  final VoidCallback onRefresh;

  const AppDrawer({super.key, required this.userId, required this.onRefresh});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _userName;
  String? _userEmail;
  String? _profileImagePath;
  double _totalExpenses = 0.0;
  double _monthlyExpenses = 0.0;
  int _expensesCount = 0;
  Map<String, double> _categoryTotals = {};
  bool _isLoading = true;
  final _dbHelper = DatabaseHelper.instance;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load user profile
    final profile = await UserProfileService.getUserProfile();
    _userName = profile['name'];

    // Get user email from Firebase Auth
    final user = _authService.currentUser;
    _userEmail = user?.email ?? 'No email';

    // Load profile image (per-user)
    _profileImagePath = await UserProfileService.getProfileImagePath(user?.uid);

    // Load statistics
    _totalExpenses = await _dbHelper.getTotalExpenses(widget.userId);

    final now = DateTime.now();
    _monthlyExpenses = await _dbHelper.getMonthlyExpenses(
      widget.userId,
      now.year,
      now.month,
    );

    _expensesCount = await _dbHelper.getExpensesCount(widget.userId);
    _categoryTotals = await _dbHelper.getExpensesByCategory(widget.userId);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // User Info Header - Enhanced Design
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Constants.primaryBlue,
                  Constants.primaryBlueLight,
                  Constants.accentGreen,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Constants.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _profileImagePath != null &&
                                File(_profileImagePath!).existsSync()
                            ? FileImage(File(_profileImagePath!))
                            : null,
                        child:
                            _profileImagePath == null ||
                                !File(_profileImagePath!).existsSync()
                            ? Icon(
                                Icons.person,
                                size: 36,
                                color: Constants.primaryBlue,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _userEmail ?? 'No email',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Quick Stats - Enhanced Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Constants.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bar_chart,
                                color: Constants.primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Constants.primaryBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Expenses',
                                '₱${_totalExpenses.toStringAsFixed(2)}',
                                Icons.account_balance_wallet,
                                Constants.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'This Month',
                                '₱${_monthlyExpenses.toStringAsFixed(2)}',
                                Icons.calendar_month,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Total Items',
                                _expensesCount.toString(),
                                Icons.receipt_long,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      // Category Breakdown - Enhanced Header
                      if (_categoryTotals.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.category,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Category Breakdown',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Constants.primaryBlue,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ..._categoryTotals.entries.map((entry) {
                          final category = entry.key;
                          final amount = entry.value;
                          final icon =
                              Constants.categoryIcons[category] ??
                              Icons.category;
                          final color =
                              Constants.categoryColors[category] ?? Colors.grey;
                          final percentage = _totalExpenses > 0
                              ? (amount / _totalExpenses * 100).toStringAsFixed(
                                  1,
                                )
                              : '0.0';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Text(category),
                            subtitle: Text('${percentage}% of total'),
                            trailing: Text(
                              '₱${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 8),
                      ],

                      // Menu Section Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.menu,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Menu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Constants.primaryBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Expense Calendar Menu Item
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.teal,
                                size: 24,
                              ),
                            ),
                            title: const Text(
                              'Expense Calendar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text('View expenses by date'),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ExpenseCalendarScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Spending Limit Menu Item
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            title: const Text(
                              'Spending Limit',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text('Set daily, weekly, or monthly limits'),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SpendingLimitScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Settings Menu Item
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Constants.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Constants.primaryBlue,
                                size: 24,
                              ),
                            ),
                            title: const Text(
                              'Settings',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text('Profile, logout, and more'),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 140, // Fixed height to prevent expansion
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
