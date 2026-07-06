import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static SharedPreferences? _prefs;

  static String? _accessToken;
  static String? _refreshToken;
  static String? _userName;
  static String? _userEmail;
  static int? _userId;
  static bool _isMerchant = false;
  static bool _isUser = false;
  static Map<String, dynamic>? _userData;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accessToken = _prefs?.getString('access_token');
    _refreshToken = _prefs?.getString('refresh_token');
    _userName = _prefs?.getString('user_name');
    _userEmail = _prefs?.getString('user_email');
    _userId = _prefs?.getInt('user_id');
    _isMerchant = _prefs?.getBool('is_merchant') ?? false;
    _isUser = _prefs?.getBool('is_user') ?? false;
    final userDataStr = _prefs?.getString('user_data');
    if (userDataStr != null) {
      try {
        _userData = Map<String, dynamic>.from(jsonDecode(userDataStr));
      } catch (_) {}
    }
  }

  static bool get isLoggedIn => _accessToken != null;
  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static String? get userName => _userName;
  static String? get userEmail => _userEmail;
  static int? get userId => _userId;
  static bool get isMerchant => _isMerchant;
  static bool get isUser => _isUser;
  static Map<String, dynamic>? get userData => _userData;

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = user['id'] as int?;
    _userEmail = user['email'] as String?;
    _userName = user['name'] as String? ?? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    if (_userName == null || _userName!.isEmpty) {
      _userName = 'Twicely Member';
    }
    _isMerchant = user['is_merchant'] as bool? ?? false;
    _isUser = user['is_user'] as bool? ?? false;
    _userData = user;

    if (_prefs != null) {
      await _prefs!.setString('access_token', accessToken);
      await _prefs!.setString('refresh_token', refreshToken);
      await _prefs!.setInt('user_id', _userId ?? 0);
      if (_userEmail != null) await _prefs!.setString('user_email', _userEmail!);
      if (_userName != null) await _prefs!.setString('user_name', _userName!);
      await _prefs!.setBool('is_merchant', _isMerchant);
      await _prefs!.setBool('is_user', _isUser);
      await _prefs!.setString('user_data', jsonEncode(user));
    }
  }

  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    if (_prefs != null) {
      await _prefs!.setString('access_token', accessToken);
      await _prefs!.setString('refresh_token', refreshToken);
    }
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _isMerchant = false;
    _isUser = false;
    _userData = null;

    if (_prefs != null) {
      await _prefs!.remove('access_token');
      await _prefs!.remove('refresh_token');
      await _prefs!.remove('user_id');
      await _prefs!.remove('user_name');
      await _prefs!.remove('user_email');
      await _prefs!.remove('is_merchant');
      await _prefs!.remove('is_user');
      await _prefs!.remove('user_data');
    }
  }
}
