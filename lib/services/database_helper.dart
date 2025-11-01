import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT
      )
    ''');
  }

  // Create
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  // Read All
  Future<List<Expense>> getAllExpenses(String userId) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Read Single
  Future<Expense?> getExpense(int id, String userId) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    if (result.isNotEmpty) {
      return Expense.fromMap(result.first);
    }
    return null;
  }

  // Update
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [expense.id, expense.userId],
    );
  }

  // Delete
  Future<int> deleteExpense(int id, String userId) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // Get Total Expenses
  Future<double> getTotalExpenses(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE userId = ?',
      [userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get Expenses by Category
  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses WHERE userId = ? GROUP BY category',
      [userId],
    );
    final Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['category'] as String] = 
          (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    return categoryTotals;
  }

  // Get Monthly Expenses
  Future<double> getMonthlyExpenses(String userId, int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE userId = ? AND date >= ? AND date <= ?',
      [userId, startDate, endDate],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get Expenses Count
  Future<int> getExpensesCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE userId = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

