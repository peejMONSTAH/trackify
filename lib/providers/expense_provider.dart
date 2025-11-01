import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  // Load all expenses for a user
  Future<void> loadExpenses(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await _dbHelper.getAllExpenses(userId);
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add expense
  Future<bool> addExpense(Expense expense) async {
    try {
      await _dbHelper.insertExpense(expense);
      await loadExpenses(expense.userId);
      return true;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      return false;
    }
  }

  // Update expense
  Future<bool> updateExpense(Expense expense) async {
    try {
      await _dbHelper.updateExpense(expense);
      await loadExpenses(expense.userId);
      return true;
    } catch (e) {
      debugPrint('Error updating expense: $e');
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(int id, String userId) async {
    try {
      await _dbHelper.deleteExpense(id, userId);
      await loadExpenses(userId);
      return true;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    }
  }

  // Get total expenses
  Future<double> getTotalExpenses(String userId) async {
    return await _dbHelper.getTotalExpenses(userId);
  }

  // Get expenses by category
  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    return await _dbHelper.getExpensesByCategory(userId);
  }
}

