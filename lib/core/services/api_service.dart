import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/session_manager.dart';

class ApiService {
  static const String baseUrl = 'https://staging.twicely.sg/wp-json/twicely/v1';

  // Global callback set by main.dart or UI to force redirect to login
  static void Function()? onUnauthorized;

  static Map<String, String> _getHeaders({bool authenticated = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated && SessionManager.accessToken != null) {
      headers['Authorization'] = 'Bearer ${SessionManager.accessToken}';
    }
    return headers;
  }

  // Generic POST Request helper
  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = _getHeaders(authenticated: authenticated);
    final bodyStr = jsonEncode(body);

    http.Response response = await http.post(url, headers: headers, body: bodyStr);

    if (response.statusCode == 401 && authenticated) {
      // Check if it is expired_token
      try {
        final decoded = jsonDecode(response.body);
        final code = decoded['code'];
        if (code == 'expired_token') {
          // Attempt to refresh token
          final refreshSuccess = await _refreshTokens();
          if (refreshSuccess) {
            // Retry the original request with new token
            final newHeaders = _getHeaders(authenticated: true);
            response = await http.post(url, headers: newHeaders, body: bodyStr);
          } else {
            _handleForcedLogout();
          }
        } else if (code == 'invalid_token' || code == 'invalid_refresh_token') {
          _handleForcedLogout();
        }
      } catch (_) {
        _handleForcedLogout();
      }
    }

    return response;
  }

  // Token refresh logic
  static Future<bool> _refreshTokens() async {
    final refreshToken = SessionManager.refreshToken;
    if (refreshToken == null) return false;

    final url = Uri.parse('$baseUrl/auth/refresh');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({'refresh_token': refreshToken});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'];
          final newAccess = data['access_token'] as String;
          final newRefresh = data['refresh_token'] as String;
          await SessionManager.updateTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          return true;
        }
      }
    } catch (_) {
      // Ignore and return false
    }
    return false;
  }

  static void _handleForcedLogout() {
    SessionManager.logout();
    if (onUnauthorized != null) {
      onUnauthorized!();
    }
  }

  static String _getMessage(Map<String, dynamic> decoded, String defaultMsg) {
    if (decoded['message'] != null) return decoded['message'] as String;
    if (decoded['data'] is Map && decoded['data']['message'] != null) {
      return decoded['data']['message'] as String;
    }
    return defaultMsg;
  }

  // --- API Authentication Endpoints ---

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post('/auth/login', {
      'email': email,
      'password': password,
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      final data = decoded['data'];
      final user = data['user'] as Map<String, dynamic>;
      await SessionManager.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: user,
      );
      return {'success': true, 'user': user};
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Login failed. Please try again.'),
      };
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await post('/auth/logout', {}, authenticated: true);
    } catch (_) {}
    await SessionManager.logout();
  }

  // User Registration (C2C buyer/seller)
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/register/user', {
      'name': name,
      'email': email,
      'password': password,
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      final data = decoded['data'];
      final user = data['user'] as Map<String, dynamic>;
      await SessionManager.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: user,
      );
      return {'success': true, 'message': _getMessage(decoded, 'Registration successful!')};
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Registration failed.'),
        'data': decoded['data'],
      };
    }
  }

  // Merchant Registration
  static Future<Map<String, dynamic>> registerMerchant({
    required String email,
    required String password,
    required String confirmPassword,
    required String businessName,
    required String phone,
    String? firstName,
    String? lastName,
    String? businessType,
    String? businessRegistration,
    String? businessAddress,
    String? websiteLink,
  }) async {
    final response = await post('/auth/register/merchant', {
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
      'business_name': businessName,
      'phone': phone,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      'business_type': businessType ?? 'individual',
      if (businessRegistration != null) 'business_registration': businessRegistration,
      if (businessAddress != null) 'business_address': businessAddress,
      if (websiteLink != null) 'website_link': websiteLink,
      'merchant_onboarding_type': 'biz_plus', // default
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      final data = decoded['data'];
      final user = data['user'] as Map<String, dynamic>;
      await SessionManager.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: user,
      );
      return {'success': true, 'message': _getMessage(decoded, 'Registration successful!')};
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Merchant registration failed.'),
        'data': decoded['data'],
      };
    }
  }

  // Forgot Password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await post('/auth/forgot-password', {
      'email': email,
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      return {'success': true, 'message': _getMessage(decoded, 'Reset link sent.')};
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Failed to send reset link.'),
      };
    }
  }

  // Reset Password
  static Future<Map<String, dynamic>> resetPassword({
    required String key,
    required String login,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await post('/auth/reset-password', {
      'key': key,
      'login': login,
      'password': password,
      'confirm_password': confirmPassword,
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      final data = decoded['data'];
      final user = data['user'] as Map<String, dynamic>;
      await SessionManager.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: user,
      );
      return {'success': true, 'message': _getMessage(decoded, 'Password reset successfully!')};
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Failed to reset password.'),
      };
    }
  }

  // OTP Send
  static Future<Map<String, dynamic>> sendOtp({
    String type = 'email',
    String? email,
    String? phone,
    String purpose = 'registration',
  }) async {
    final response = await post('/auth/otp/send', {
      'otp_type': type,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'purpose': purpose,
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      return {'success': true, 'message': _getMessage(decoded, 'OTP sent successfully.')};
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Failed to send OTP.'),
      };
    }
  }

  // OTP Verify
  static Future<Map<String, dynamic>> verifyOtp({
    required String otpCode,
    String? email,
    String? phone,
    String purpose = 'registration',
  }) async {
    final response = await post('/auth/otp/verify', {
      'otp_code': otpCode,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'purpose': purpose,
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      return {'success': true, 'message': _getMessage(decoded, 'OTP verified successfully.')};
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'OTP verification failed.'),
      };
    }
  }
}
