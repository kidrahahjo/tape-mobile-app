import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  // Helper class to store data for persistance.
  // This helps in avoiding multiple calls to server.

  static String userIdKey = "USER_ID_KEY";
  static String userPhoneNumber = "USER_PHONE_NUMBER";

  Future<bool> saveUserId(String getUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, getUserId);
  }

  Future<bool> saveUserPhoneNumber(String getUserPhoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userPhoneNumber, getUserPhoneNumber);
  }

  Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String> getUserPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userPhoneNumber);
  }
}