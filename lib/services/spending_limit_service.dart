import 'package:shared_preferences/shared_preferences.dart';

enum SpendingPeriod { day, week, month }

class SpendingLimitService {
  static const String _keySpendingLimit = 'spending_limit';
  static const String _keySpendingPeriod = 'spending_period';
  static const String _keySpendingLimitEnabled = 'spending_limit_enabled';

  // Helper method to get user-specific keys
  static String _getUserKey(String baseKey, String userId) {
    return '${baseKey}_$userId';
  }

  // Save spending limit
  static Future<void> saveSpendingLimit({
    required String userId,
    required double limit,
    required SpendingPeriod period,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store per-user data
    await prefs.setDouble(_getUserKey(_keySpendingLimit, userId), limit);
    await prefs.setString(
      _getUserKey(_keySpendingPeriod, userId),
      period.toString().split('.').last, // 'day', 'week', or 'month'
    );
    await prefs.setBool(_getUserKey(_keySpendingLimitEnabled, userId), enabled);
    
    // Also store in current session for compatibility
    await prefs.setDouble(_keySpendingLimit, limit);
    await prefs.setString(_keySpendingPeriod, period.toString().split('.').last);
    await prefs.setBool(_keySpendingLimitEnabled, enabled);
  }

  // Get spending limit
  static Future<double?> getSpendingLimit([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString('user_id');
    
    if (currentUserId != null) {
      final perUser = prefs.getDouble(_getUserKey(_keySpendingLimit, currentUserId));
      if (perUser != null) return perUser;
    }
    
    return prefs.getDouble(_keySpendingLimit);
  }

  // Get spending period
  static Future<SpendingPeriod?> getSpendingPeriod([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString('user_id');
    
    String? periodStr;
    if (currentUserId != null) {
      periodStr = prefs.getString(_getUserKey(_keySpendingPeriod, currentUserId));
    }
    periodStr ??= prefs.getString(_keySpendingPeriod);
    
    if (periodStr == null) return null;
    
    switch (periodStr) {
      case 'day':
        return SpendingPeriod.day;
      case 'week':
        return SpendingPeriod.week;
      case 'month':
        return SpendingPeriod.month;
      default:
        return null;
    }
  }

  // Check if spending limit is enabled
  static Future<bool> isSpendingLimitEnabled([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString('user_id');
    
    if (currentUserId != null) {
      final perUser = prefs.getBool(_getUserKey(_keySpendingLimitEnabled, currentUserId));
      if (perUser != null) return perUser;
    }
    
    return prefs.getBool(_keySpendingLimitEnabled) ?? false;
  }

  // Get all spending limit settings
  static Future<Map<String, dynamic>> getSpendingLimitSettings([String? userId]) async {
    final limit = await getSpendingLimit(userId);
    final period = await getSpendingPeriod(userId);
    final enabled = await isSpendingLimitEnabled(userId);
    
    return {
      'limit': limit,
      'period': period,
      'enabled': enabled,
    };
  }

  // Clear spending limit (on logout)
  static Future<void> clearSpendingLimit([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear current session
    await prefs.remove(_keySpendingLimit);
    await prefs.remove(_keySpendingPeriod);
    await prefs.remove(_keySpendingLimitEnabled);
    
    // Clear per-user storage if userId available
    if (userId != null) {
      await prefs.remove(_getUserKey(_keySpendingLimit, userId));
      await prefs.remove(_getUserKey(_keySpendingPeriod, userId));
      await prefs.remove(_getUserKey(_keySpendingLimitEnabled, userId));
    }
  }
}

