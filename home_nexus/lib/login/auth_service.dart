import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<bool> isSeller() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type') == 'Seller';
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_type');
    await prefs.remove('is_logged_in');
  }
}