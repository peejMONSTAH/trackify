import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/database_helper.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import 'add_edit_expense_screen.dart';
import 'expense_calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _dbHelper = DatabaseHelper.instance;
  double _totalExpenses = 0.0;
  double _todayExpenses = 0.0;
  double _weekExpenses = 0.0;
  double _monthExpenses = 0.0;
  String? _selectedCategoryFilter; // null means "All Categories"

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Restore user profile data on login
      await UserProfileService.restoreUserProfile(user.uid);

      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      await expenseProvider.loadExpenses(user.uid);
      _totalExpenses = await expenseProvider.getTotalExpenses(user.uid);
      _todayExpenses = await _dbHelper.getTodayExpenses(user.uid);
      _weekExpenses = await _dbHelper.getThisWeekExpenses(user.uid);
      _monthExpenses = await _dbHelper.getThisMonthExpenses(user.uid);
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Delete Expense',
      desc:
          'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnCancelText: 'Cancel',
      btnOkOnPress: () async {
        final user = _authService.currentUser;
        if (user != null && mounted) {
          final expenseProvider = Provider.of<ExpenseProvider>(
            context,
            listen: false,
          );
          final success = await expenseProvider.deleteExpense(
            expense.id!,
            user.uid,
          );
          if (success && mounted) {
            _totalExpenses = await expenseProvider.getTotalExpenses(user.uid);
            _todayExpenses = await _dbHelper.getTodayExpenses(user.uid);
            _weekExpenses = await _dbHelper.getThisWeekExpenses(user.uid);
            _monthExpenses = await _dbHelper.getThisMonthExpenses(user.uid);
            if (mounted) {
              setState(() {});
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.bottomSlide,
                title: 'Deleted!',
                desc: 'Expense deleted successfully.',
                btnOkOnPress: () {},
                btnOkText: 'OK',
                btnOkColor: Colors.green,
                dismissOnTouchOutside: true,
                dismissOnBackKeyPress: true,
              ).show();
            }
          } else if (mounted) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.bottomSlide,
              title: 'Error',
              desc: 'Failed to delete expense. Please try again.',
              btnOkOnPress: () {},
              btnOkText: 'OK',
              btnOkColor: Colors.red,
              dismissOnTouchOutside: true,
              dismissOnBackKeyPress: true,
            ).show();
          }
        }
      },
      btnOkText: 'Delete',
      btnOkColor: Colors.red,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Trackify',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Constants.primaryBlue, Constants.primaryBlueLight],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Expense Calendar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExpenseCalendarScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: user == null
          ? null
          : AppDrawer(userId: user.uid, onRefresh: _loadData),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Consumer<ExpenseProvider>(
                builder: (context, expenseProvider, _) {
                  if (expenseProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final expenses = expenseProvider.expenses;

                  return CustomScrollView(
                    slivers: [
                      // Total Expenses Card as Sliver - Enhanced
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(28),
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
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Constants.primaryBlue.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Expenses',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'All Time',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '₱${_totalExpenses.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Today, Week, Month Expenses Cards
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPeriodCard(
                                  'Today',
                                  _todayExpenses,
                                  Icons.today,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPeriodCard(
                                  'This Week',
                                  _weekExpenses,
                                  Icons.date_range,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPeriodCard(
                                  'This Month',
                                  _monthExpenses,
                                  Icons.calendar_month,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      // Category Filter
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 50,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildFilterChip('All', null),
                                const SizedBox(width: 8),
                                ...Constants.categories.map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildFilterChip(category, category),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      // Expenses List
                      if (_getFilteredExpenses(expenses).isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Constants.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    size: 80,
                                    color: Constants.primaryBlueLight,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'No Expenses Yet',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                  ),
                                  child: Text(
                                    'Start tracking your expenses by adding your first transaction',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Constants.primaryBlueLight,
                                        Constants.primaryBlue,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Constants.primaryBlue.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Tap + to Add Expense',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final filteredExpenses = _getFilteredExpenses(
                                expenses,
                              );
                              final expense = filteredExpenses[index];
                              final categoryIcon =
                                  Constants.categoryIcons[expense.category] ??
                                  Icons.category;
                              final categoryColor =
                                  Constants.categoryColors[expense.category] ??
                                  Colors.grey;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AddEditExpenseScreen(
                                            expense: expense,
                                          ),
                                        ),
                                      );
                                      _loadData();
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  categoryColor.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                  categoryColor.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              categoryIcon,
                                              color: categoryColor,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  expense.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: categoryColor
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        expense.category,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: categoryColor,
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.calendar_today,
                                                          size: 10,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 3,
                                                        ),
                                                        Text(
                                                          DateFormat(
                                                            'MMM dd',
                                                          ).format(
                                                            expense.date,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '₱${expense.amount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            7,
                                                          ),
                                                    ),
                                                    child: InkWell(
                                                      onTap: () async {
                                                        await Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                AddEditExpenseScreen(
                                                                  expense:
                                                                      expense,
                                                                ),
                                                          ),
                                                        );
                                                        _loadData();
                                                      },
                                                      child: const Icon(
                                                        Icons.edit,
                                                        size: 14,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            7,
                                                          ),
                                                    ),
                                                    child: InkWell(
                                                      onTap: () =>
                                                          _deleteExpense(
                                                            expense,
                                                          ),
                                                      child: const Icon(
                                                        Icons.delete,
                                                        size: 14,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: _getFilteredExpenses(expenses).length),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Constants.primaryBlue, Constants.primaryBlueLight],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                                        color: Constants.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
            );
            _loadData();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  List<Expense> _getFilteredExpenses(List<Expense> expenses) {
    if (_selectedCategoryFilter == null) {
      return expenses;
    }
    return expenses
        .where((expense) => expense.category == _selectedCategoryFilter)
        .toList();
  }

  Widget _buildFilterChip(String label, String? category) {
    final isSelected = _selectedCategoryFilter == category;
    final color = category != null
        ? Constants.categoryColors[category] ?? Colors.grey
        : Constants.primaryBlue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryFilter = selected ? category : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      avatar: category != null
          ? Icon(
              Constants.categoryIcons[category],
              color: isSelected ? color : Colors.grey[600],
              size: 18,
            )
          : Icon(
              Icons.filter_list,
              color: isSelected ? color : Colors.grey[600],
              size: 18,
            ),
    );
  }

  Widget _buildPeriodCard(
    String period,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 120, // Fixed height to prevent expansion
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              period,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₱${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
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
