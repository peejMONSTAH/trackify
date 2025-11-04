import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import 'spending_limit_service.dart';

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add users table for email/phone validation
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          userId TEXT PRIMARY KEY,
          email TEXT NOT NULL UNIQUE,
          phone TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Remove UNIQUE constraint from phone - allow phone number reuse
      try {
        // Create new table without UNIQUE on phone
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users_new (
            userId TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            phone TEXT NOT NULL,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        
        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO users_new (userId, email, phone, name, createdAt)
          SELECT userId, email, phone, name, createdAt FROM users
        ''');
        
        // Drop old table
        await db.execute('DROP TABLE users');
        
        // Rename new table
        await db.execute('ALTER TABLE users_new RENAME TO users');
      } catch (e) {
        print('Error migrating users table: $e');
        // If migration fails, try to just remove the constraint by recreating
        // This is a fallback if the above fails
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create expenses table
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
    
    // Create users table for email validation (phone can be reused)
    await db.execute('''
      CREATE TABLE users (
        userId TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
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

  // Get Today's Expenses
  Future<double> getTodayExpenses(String userId) async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE userId = ? AND date >= ? AND date <= ?',
      [userId, startOfDay, endOfDay],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get This Week's Expenses
  Future<double> getThisWeekExpenses(String userId) async {
    final db = await database;
    final now = DateTime.now();
    // Get the start of the week (Monday)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();
    final endOfWeek = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE userId = ? AND date >= ? AND date <= ?',
      [userId, startOfWeek, endOfWeek],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get This Month's Expenses (already exists, but adding for consistency)
  Future<double> getThisMonthExpenses(String userId) async {
    final now = DateTime.now();
    return await getMonthlyExpenses(userId, now.year, now.month);
  }

  // Get current period spending based on period type
  Future<double> getCurrentPeriodSpending(String userId, SpendingPeriod period) async {
    switch (period) {
      case SpendingPeriod.day:
        return await getTodayExpenses(userId);
      case SpendingPeriod.week:
        return await getThisWeekExpenses(userId);
      case SpendingPeriod.month:
        return await getThisMonthExpenses(userId);
    }
  }

  // Get expenses for a specific date
  Future<double> getExpensesForDate(String userId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE userId = ? AND date >= ? AND date <= ?',
      [userId, startOfDay, endOfDay],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get expenses grouped by date for a month
  Future<Map<String, double>> getExpensesByDateForMonth(
    String userId,
    int year,
    int month,
  ) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    // SQLite doesn't have DATE() function, so we extract date part using substr
    final result = await db.rawQuery(
      '''
      SELECT 
        SUBSTR(date, 1, 10) as expense_date,
        SUM(amount) as total 
      FROM expenses 
      WHERE userId = ? AND date >= ? AND date <= ?
      GROUP BY SUBSTR(date, 1, 10)
      ''',
      [userId, startDate, endDate],
    );

    final Map<String, double> dateTotals = {};
    for (var row in result) {
      final dateStr = row['expense_date'] as String?;
      if (dateStr != null) {
        dateTotals[dateStr] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return dateTotals;
  }

  // User registration methods
  Future<int> insertUser({
    required String userId,
    required String email,
    required String phone,
    required String name,
  }) async {
    final db = await database;
    try {
      return await db.insert(
        'users',
        {
          'userId': userId,
          'email': email.toLowerCase().trim(),
          'phone': phone.trim(),
          'name': name.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // Allow phone reuse, but replace if same userId
      );
    } catch (e) {
      print('Error inserting user: $e');
      rethrow;
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final db = await database;
      final normalizedEmail = email.toLowerCase().trim();
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );
      final exists = result.isNotEmpty;
      print('Email check: $normalizedEmail exists = $exists');
      return exists;
    } catch (e) {
      print('Error checking email existence: $e');
      // If table doesn't exist or error occurs, return false to allow registration
      return false;
    }
  }

  // Check if phone exists
  Future<bool> phoneExists(String phone) async {
    try {
      final db = await database;
      final normalizedPhone = phone.trim();
      final result = await db.query(
        'users',
        where: 'phone = ?',
        whereArgs: [normalizedPhone],
        limit: 1,
      );
      final exists = result.isNotEmpty;
      print('Phone check: $normalizedPhone exists = $exists');
      return exists;
    } catch (e) {
      print('Error checking phone existence: $e');
      // If table doesn't exist or error occurs, return false to allow registration
      return false;
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final normalizedEmail = email.toLowerCase().trim();
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );
      final user = result.isNotEmpty ? result.first : null;
      print('getUserByEmail: $normalizedEmail -> ${user != null ? "found" : "not found"}');
      if (user != null) {
        print('User data: name=${user['name']}, userId=${user['userId']}');
      }
      return user;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Get user by phone
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
