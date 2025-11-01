import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String _keyName = 'user_name';
  static const String _keyPhone = 'user_phone';
  static const String _keyUserId = 'user_id';

  // Save user profile
  static Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyPhone, phone);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  // Get user phone
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  // Get full user profile
  static Future<Map<String, String?>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName),
      'phone': prefs.getString(_keyPhone),
      'userId': prefs.getString(_keyUserId),
    };
  }

  // Clear user profile (on logout)
  static Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyUserId);
  }

  // Update user name
  static Future<void> updateUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  // Update user phone
  static Future<void> updateUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
  }
}

