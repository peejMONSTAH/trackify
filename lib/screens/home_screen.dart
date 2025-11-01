import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import 'add_edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  double _totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      await expenseProvider.loadExpenses(user.uid);
      _totalExpenses = await expenseProvider.getTotalExpenses(user.uid);
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
        title: const Text(
          'Trackify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: user == null
          ? null
          : AppDrawer(userId: user.uid, onRefresh: _loadData),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Total Expenses Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple[600]!,
                          Colors.deepPurple[400]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Expenses',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${_totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expenses List
                  Expanded(
                    child: Consumer<ExpenseProvider>(
                      builder: (context, expenseProvider, _) {
                        if (expenseProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final expenses = expenseProvider.expenses;

                        if (expenses.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No expenses yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap + to add your first expense',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            final categoryIcon =
                                Constants.categoryIcons[expense.category] ??
                                Icons.category;
                            final categoryColor =
                                Constants.categoryColors[expense.category] ??
                                Colors.grey;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: categoryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Icon(
                                    categoryIcon,
                                    color: categoryColor,
                                  ),
                                ),
                                title: Text(
                                  expense.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(expense.category),
                                    Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(expense.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₱${expense.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[600],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          color: Colors.blue,
                                          onPressed: () async {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddEditExpenseScreen(
                                                      expense: expense,
                                                    ),
                                              ),
                                            );
                                            _loadData();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                          ),
                                          color: Colors.red,
                                          onPressed: () =>
                                              _deleteExpense(expense),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
          );
          _loadData();
        },
        backgroundColor: Colors.deepPurple[600],
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
