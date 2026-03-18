import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure - Token
  Future<void> saveToken(String token) async =>
      await _secureStorage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> getToken() async =>
      await _secureStorage.read(key: AppConstants.tokenKey);

  Future<void> deleteToken() async =>
      await _secureStorage.delete(key: AppConstants.tokenKey);

  // Prefs - Username
  Future<void> saveUsername(String username) async =>
      await _prefs.setString(AppConstants.usernameKey, username);

  String? getUsername() => _prefs.getString(AppConstants.usernameKey);

  Future<void> clearUsername() async =>
      await _prefs.remove(AppConstants.usernameKey);

  // Clear all on logout
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }

  // General prefs helpers
  Future<void> setBool(String key, bool value) async =>
      await _prefs.setBool(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> setString(String key, String value) async =>
      await _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);
}
