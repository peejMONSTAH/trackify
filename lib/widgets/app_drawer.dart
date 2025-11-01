import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';
import '../screens/login_screen.dart';

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
  String? _userPhone;
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
    _userPhone = profile['phone'];

    // Get user email from Firebase Auth
    final user = _authService.currentUser;
    _userEmail = user?.email ?? 'No email';

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

  Future<void> _showAboutDialog(BuildContext dialogContext) async {
    AwesomeDialog(
      context: dialogContext,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'About Trackify',
      desc:
          'Trackify v1.0.0\n\nA comprehensive expense tracking app built with Flutter.\n\nFeatures:\n• Firebase Authentication\n• Local SQFLite Database\n• Category Management\n• Expense Analytics\n\nDeveloped for ITCC 116',
      btnOkOnPress: () {},
      btnOkText: 'OK',
      btnOkColor: Colors.deepPurple[600]!,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
    ).show();
  }

  Future<void> _showHelpDialog(BuildContext dialogContext) async {
    AwesomeDialog(
      context: dialogContext,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Help & Tips',
      desc:
          'How to use Trackify:\n\n1. Tap the + button to add a new expense\n2. Fill in all required fields\n3. Select a category\n4. Tap Edit icon to modify expenses\n5. Tap Delete icon to remove expenses\n6. View statistics in the drawer\n7. Expenses are stored locally on your device',
      btnOkOnPress: () {},
      btnOkText: 'Got it!',
      btnOkColor: Colors.deepPurple[600]!,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
    ).show();
  }

  Future<void> _logout(BuildContext dialogContext) async {
    AwesomeDialog(
      context: dialogContext,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      btnCancelOnPress: () {},
      btnCancelText: 'Cancel',
      btnOkOnPress: () async {
        // Close the dialog first
        Navigator.of(dialogContext).pop();

        // Clear data
        await UserProfileService.clearUserProfile();
        await _authService.signOut();

        // Navigate to login
        if (!mounted) return;
        Navigator.of(dialogContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      btnOkText: 'Logout',
      btnOkColor: Colors.orange,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // User Info Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple[600]!, Colors.deepPurple[400]!],
              ),
            ),
            accountName: Text(
              _userName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_userEmail ?? 'No email'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.deepPurple[600],
              ),
            ),
          ),

          // Statistics Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Quick Stats
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),

                      _buildStatCard(
                        'Total Expenses',
                        '₱${_totalExpenses.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.deepPurple,
                      ),

                      _buildStatCard(
                        'This Month',
                        '₱${_monthlyExpenses.toStringAsFixed(2)}',
                        Icons.calendar_month,
                        Colors.blue,
                      ),

                      _buildStatCard(
                        'Total Items',
                        _expensesCount.toString(),
                        Icons.receipt_long,
                        Colors.green,
                      ),

                      const Divider(),

                      // Category Breakdown
                      if (_categoryTotals.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Category Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
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

                        const Divider(),
                      ],

                      // User Info
                      ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: Colors.deepPurple,
                        ),
                        title: const Text('Profile'),
                        subtitle: Text(_userPhone ?? 'No phone'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.info,
                            animType: AnimType.scale,
                            title: 'Profile Information',
                            desc:
                                'Name: ${_userName ?? "Not set"}\nEmail: ${_userEmail ?? "Not set"}\nPhone: ${_userPhone ?? "Not set"}',
                            btnOkOnPress: () {},
                            btnOkText: 'OK',
                            btnOkColor: Colors.deepPurple[600]!,
                            dismissOnTouchOutside: true,
                            dismissOnBackKeyPress: true,
                            btnOkIcon: Icons.check,
                          ).show();
                        },
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.help_outline,
                          color: Colors.blue,
                        ),
                        title: const Text('Help & Tips'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          _showHelpDialog(context);
                        },
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: Colors.teal,
                        ),
                        title: const Text('About'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          _showAboutDialog(context);
                        },
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.refresh,
                          color: Colors.orange,
                        ),
                        title: const Text('Refresh Data'),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          _loadData();
                          widget.onRefresh();
                        },
                      ),
                    ],
                  ),
          ),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _logout(context);
            },
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
