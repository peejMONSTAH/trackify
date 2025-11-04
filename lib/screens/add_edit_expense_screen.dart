import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/spending_limit_service.dart';
import '../services/database_helper.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = Constants.categories[0];
  DateTime _selectedDate = DateTime.now();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<bool> _checkSpendingLimit(double amount) async {
    final user = _authService.currentUser;
    if (user == null) return true;

    final isEnabled = await SpendingLimitService.isSpendingLimitEnabled(user.uid);
    if (!isEnabled) return true;

    final limit = await SpendingLimitService.getSpendingLimit(user.uid);
    final period = await SpendingLimitService.getSpendingPeriod(user.uid);
    
    if (limit == null || period == null) return true;

    // Get current spending for the period
    final dbHelper = DatabaseHelper.instance;
    final currentSpending = await dbHelper.getCurrentPeriodSpending(user.uid, period);
    
    // Calculate new total if this expense is added
    final oldAmount = widget.expense?.amount ?? 0;
    // If editing, subtract old amount first
    final actualNewTotal = widget.expense != null 
        ? currentSpending - oldAmount + amount 
        : currentSpending + amount;

    // Check if limit is exceeded
    if (actualNewTotal > limit) {
      if (!mounted) return false;
      final exceeded = actualNewTotal - limit;
      final periodName = period == SpendingPeriod.day 
          ? 'today' 
          : period == SpendingPeriod.week 
              ? 'this week' 
              : 'this month';
      
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'Spending Limit Exceeded!',
        desc: 'Adding this expense would exceed your ${period == SpendingPeriod.day ? 'daily' : period == SpendingPeriod.week ? 'weekly' : 'monthly'} spending limit of ₱${limit.toStringAsFixed(2)}.\n\nCurrent spending $periodName: ₱${currentSpending.toStringAsFixed(2)}\nThis expense: ₱${amount.toStringAsFixed(2)}\nWould exceed by: ₱${exceeded.toStringAsFixed(2)}',
        btnOkOnPress: () {},
        btnOkText: 'OK',
        btnOkColor: Colors.red,
        dismissOnTouchOutside: true,
        dismissOnBackKeyPress: true,
      ).show();
      return false; // Prevent saving
    }

    // Check if approaching limit (80% threshold)
    if (actualNewTotal >= limit * 0.8 && actualNewTotal < limit) {
      if (!mounted) return false;
      final remaining = limit - actualNewTotal;
      final periodName = period == SpendingPeriod.day 
          ? 'daily' 
          : period == SpendingPeriod.week 
              ? 'weekly' 
              : 'monthly';
      
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Approaching Limit',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'You are approaching your $periodName spending limit of ₱${limit.toStringAsFixed(2)}.\n\nCurrent: ₱${currentSpending.toStringAsFixed(2)}\nAfter adding: ₱${actualNewTotal.toStringAsFixed(2)}\nRemaining: ₱${remaining.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryBlue,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return false; // User cancelled
      }
    }

    return true; // Allow saving
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.bottomSlide,
        title: 'Authentication Error',
        desc: 'User not authenticated. Please login again.',
        btnOkOnPress: () {
          Navigator.of(context).pop();
        },
        btnOkText: 'OK',
        btnOkColor: Colors.orange,
        dismissOnTouchOutside: true,
        dismissOnBackKeyPress: true,
        autoDismiss: false,
      ).show();
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.bottomSlide,
        title: 'Invalid Amount',
        desc: 'Please enter a valid amount greater than 0.',
        btnOkOnPress: () {
          Navigator.of(context).pop();
        },
        btnOkText: 'OK',
        btnOkColor: Colors.orange,
        dismissOnTouchOutside: true,
        dismissOnBackKeyPress: true,
        autoDismiss: false,
      ).show();
      return;
    }

    // Check spending limit before saving
    final canProceed = await _checkSpendingLimit(amount);
    if (!canProceed) {
      return; // Don't save if limit check failed
    }

    setState(() => _isLoading = true);

    final expense = Expense(
      id: widget.expense?.id,
      userId: user.uid,
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final success = widget.expense == null
        ? await expenseProvider.addExpense(expense)
        : await expenseProvider.updateExpense(expense);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.bottomSlide,
        title: widget.expense == null ? 'Expense Added!' : 'Expense Updated!',
        desc: widget.expense == null
            ? 'Your expense has been successfully added.'
            : 'Your expense has been successfully updated.',
        btnOkOnPress: () {
          Navigator.of(context).pop();
        },
        btnOkText: 'OK',
        btnOkColor: Colors.green,
        dismissOnTouchOutside: true,
        dismissOnBackKeyPress: true,
      ).show();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'Error',
        desc: 'Failed to save expense. Please try again.',
        btnOkOnPress: () {
          Navigator.of(context).pop();
        },
        btnOkText: 'OK',
        btnOkColor: Colors.red,
        dismissOnTouchOutside: true,
        dismissOnBackKeyPress: true,
        autoDismiss: false,
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.expense == null ? Icons.add_circle : Icons.edit,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.expense == null ? 'Add Expense' : 'Edit Expense',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Constants.primaryBlue, Constants.primaryBlueLight],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field - Enhanced
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(
                      Icons.title,
                      color: Constants.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Amount Field - Enhanced
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Amount (₱)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: Constants.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Category Selection - Enhanced with Chips
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: Constants.categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  final categoryIcon =
                      Constants.categoryIcons[category] ?? Icons.category;
                  final categoryColor =
                      Constants.categoryColors[category] ?? Colors.grey;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? categoryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? categoryColor
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: categoryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon,
                            color: isSelected ? Colors.white : categoryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[800],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Date Picker - Enhanced
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Constants.primaryBlue,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM dd, yyyy',
                                ).format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Description Field - Enhanced
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(
                      Icons.description,
                      color: Constants.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Save Button - Enhanced
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Constants.primaryBlue, Constants.primaryBlueLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.expense == null
                                  ? Icons.add_circle_outline
                                  : Icons.check_circle_outline,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.expense == null
                                  ? 'Add Expense'
                                  : 'Update Expense',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
