import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String _keyName = 'user_name';
  static const String _keyPhone = 'user_phone';
  static const String _keyUserId = 'user_id';
  static const String _keyProfileImage = 'user_profile_image';

  // Helper methods to get user-specific keys
  static String _getUserKey(String baseKey, String userId) {
    return '${baseKey}_$userId';
  }

  // Save user profile (stores per userId for persistence)
  static Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Store current user ID
    await prefs.setString(_keyUserId, userId);
    // Store per-user data (persists across logins)
    await prefs.setString(_getUserKey(_keyName, userId), name);
    await prefs.setString(_getUserKey(_keyPhone, userId), phone);
    // Also store in current session keys for compatibility
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyPhone, phone);
  }

  // Get user name (checks per-user storage first, then current session)
  static Future<String?> getUserName([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      // Try per-user storage first
      final perUser = prefs.getString(_getUserKey(_keyName, userId));
      if (perUser != null && perUser.isNotEmpty) return perUser;
    }
    // Fallback to current session
    return prefs.getString(_keyName);
  }

  // Get user phone (checks per-user storage first, then current session)
  static Future<String?> getUserPhone([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      // Try per-user storage first
      final perUser = prefs.getString(_getUserKey(_keyPhone, userId));
      if (perUser != null && perUser.isNotEmpty) return perUser;
    }
    // Fallback to current session
    return prefs.getString(_keyPhone);
  }

  // Get full user profile (restores from per-user storage if available)
  static Future<Map<String, String?>> getUserProfile([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString(_keyUserId);
    
    String? name;
    String? phone;
    
    if (currentUserId != null) {
      // Try to restore from per-user storage
      name = prefs.getString(_getUserKey(_keyName, currentUserId));
      phone = prefs.getString(_getUserKey(_keyPhone, currentUserId));
    }
    
    // Fallback to current session if per-user data not found
    name ??= prefs.getString(_keyName);
    phone ??= prefs.getString(_keyPhone);
    
    return {
      'name': name,
      'phone': phone,
      'userId': currentUserId,
    };
  }

  // Clear user profile (on logout) - only clears current session, keeps per-user data
  static Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    // Only clear current session keys, keep per-user data for restoration on next login
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyUserId);
    // Profile image path is cleared from current session, but per-user data is kept
    await prefs.remove(_keyProfileImage);
  }

  // Restore user profile on login (loads per-user data into current session)
  static Future<void> restoreUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_getUserKey(_keyName, userId));
    final phone = prefs.getString(_getUserKey(_keyPhone, userId));
    final profileImage = prefs.getString(_getUserKey(_keyProfileImage, userId));
    
    await prefs.setString(_keyUserId, userId);
    if (name != null) await prefs.setString(_keyName, name);
    if (phone != null) await prefs.setString(_keyPhone, phone);
    if (profileImage != null) await prefs.setString(_keyProfileImage, profileImage);
  }

  // Update user name (saves to both per-user and current session)
  static Future<void> updateUserName(String name, [String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString(_keyUserId);
    
    // Update current session
    await prefs.setString(_keyName, name);
    
    // Also update per-user storage if userId available
    if (currentUserId != null) {
      await prefs.setString(_getUserKey(_keyName, currentUserId), name);
    }
  }

  // Update user phone (saves to both per-user and current session)
  static Future<void> updateUserPhone(String phone, [String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString(_keyUserId);
    
    // Update current session
    await prefs.setString(_keyPhone, phone);
    
    // Also update per-user storage if userId available
    if (currentUserId != null) {
      await prefs.setString(_getUserKey(_keyPhone, currentUserId), phone);
    }
  }

  // Save profile image path (per-user for persistence)
  static Future<void> saveProfileImagePath(String imagePath, [String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString(_keyUserId);
    
    // Save to current session
    await prefs.setString(_keyProfileImage, imagePath);
    
    // Also save to per-user storage if userId available
    if (currentUserId != null) {
      await prefs.setString(_getUserKey(_keyProfileImage, currentUserId), imagePath);
    }
  }

  // Get profile image path (checks per-user storage first)
  static Future<String?> getProfileImagePath([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString(_keyUserId);
    
    // Try per-user storage first
    if (currentUserId != null) {
      final perUserPath = prefs.getString(_getUserKey(_keyProfileImage, currentUserId));
      if (perUserPath != null && perUserPath.isNotEmpty) return perUserPath;
    }
    
    // Fallback to current session
    return prefs.getString(_keyProfileImage);
  }

  // Clear profile image (clears both current session and per-user storage)
  static Future<void> clearProfileImage([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = userId ?? prefs.getString(_keyUserId);
    
    // Clear current session
    await prefs.remove(_keyProfileImage);
    
    // Also clear per-user storage if userId available
    if (currentUserId != null) {
      await prefs.remove(_getUserKey(_keyProfileImage, currentUserId));
    }
  }
}

