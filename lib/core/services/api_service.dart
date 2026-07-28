import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/session_manager.dart';

class ApiService {
  static const String baseUrl = 'https://staging.twicely.sg/wp-json/twicely/v1';

  // Global callback set by main.dart or UI to force redirect to login
  static void Function()? onUnauthorized;

  // Merchant Cache
  static Map<int, Map<String, dynamic>> merchantsCache = {};

  static String getMerchantLogo(int? id, String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) return logoUrl;
    return '';
  }

  static Future<void> initMerchantsCache() async {
    try {
      final res = await getMerchants();
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List<dynamic>;
        merchantsCache.clear();
        for (final m in list) {
          if (m is Map && m['id'] != null) {
            final int id = int.tryParse(m['id'].toString()) ?? 0;
            final map = Map<String, dynamic>.from(m);
            final String logo = map['logo_url']?.toString() ?? '';
            if (logo.isEmpty) {
              map['logo_url'] = getMerchantLogo(id, logo);
            }
            merchantsCache[id] = map;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading merchants cache: $e');
    }
  }

  // Package Categories Cache (maps packageId -> list of parent categories it belongs to)
  static Map<int, List<String>> packageCategoriesCache = {};
  static Set<int> wishlistIdsCache = {};

  static Future<void> initPackageCategoriesCache() async {
    try {
      final slugs = {
        'for-her': 'For Her',
        'for-him': 'For Him',
        'general': 'General',
        'biz': 'Biz+',
      };
      final Map<int, List<String>> temp = {};
      await Future.wait(
        slugs.entries.map((entry) async {
          final res = await getPackages(
            category: entry.key,
            page: 1,
            perPage: 100,
          );
          if (res['success'] == true && res['data'] != null) {
            final list = res['data'] as List<dynamic>;
            for (final p in list) {
              if (p is Map && p['id'] != null) {
                final id = int.tryParse(p['id'].toString()) ?? 0;
                temp.putIfAbsent(id, () => []).add(entry.value);
              }
            }
          }
        }),
      );
      if (temp.isNotEmpty) {
        packageCategoriesCache = temp;
      }
    } catch (e) {
      debugPrint('Error loading package categories cache: $e');
    }
  }

  static http.Response _handleException(dynamic e, Uri url) {
    debugPrint('\n[API Error Exception Caught] ========================');
    debugPrint('URL: $url');
    debugPrint('Exception: $e');
    debugPrint('======================================================\n');

    String errorMsg =
        'Failed to connect to the server. Please check if the server is down or try again later.';
    String code = 'server_connection_error';

    final errStr = e.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('os error') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('clientexception')) {
      errorMsg =
          'No internet connection. Please check your network and try again.';
      code = 'no_internet';
    } else if (errStr.contains('timeoutexception') ||
        errStr.contains('timeout')) {
      errorMsg = 'Connection timed out. The server might be offline or slow.';
      code = 'timeout';
    } else if (errStr.contains('handshakeexception') ||
        errStr.contains('certpathvalidator')) {
      errorMsg =
          'Secure SSL connection could not be established with the server.';
      code = 'ssl_error';
    }

    return http.Response(
      jsonEncode({'success': false, 'code': code, 'message': errorMsg}),
      503, // Service Unavailable
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

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

    debugPrint('\n[API Request] ========================================');
    debugPrint('METHOD: POST');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: $bodyStr');
    debugPrint('======================================================');

    http.Response response;
    try {
      response = await http.post(url, headers: headers, body: bodyStr);
      debugPrint('\n[API Response] =======================================');
      debugPrint('URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');
    } catch (e) {
      response = _handleException(e, url);
    }

    if (response.statusCode == 401 && authenticated) {
      final refreshSuccess = await _refreshTokens();
      if (refreshSuccess) {
        final newHeaders = _getHeaders(authenticated: true);
        debugPrint('\n[API Retry Request] ==================================');
        debugPrint('METHOD: POST');
        debugPrint('URL: $url');
        debugPrint('Headers: $newHeaders');
        debugPrint('Body: $bodyStr');
        debugPrint('======================================================');
        response = await http.post(url, headers: newHeaders, body: bodyStr);
        debugPrint('\n[API Retry Response] =================================');
        debugPrint('URL: $url');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        debugPrint('======================================================\n');
      } else {
        _handleForcedLogout();
      }
    }

    return response;
  }

  // Generic GET Request helper
  static Future<http.Response> get(
    String path, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = _getHeaders(authenticated: authenticated);

    debugPrint('\n[API Request] ========================================');
    debugPrint('METHOD: GET');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('======================================================');

    http.Response response;
    try {
      response = await http.get(url, headers: headers);
      debugPrint('\n[API Response] =======================================');
      debugPrint('URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');
    } catch (e) {
      response = _handleException(e, url);
    }

    if (response.statusCode == 401 && authenticated) {
      final refreshSuccess = await _refreshTokens();
      if (refreshSuccess) {
        final newHeaders = _getHeaders(authenticated: true);
        debugPrint('\n[API Retry Request] ==================================');
        debugPrint('METHOD: GET');
        debugPrint('URL: $url');
        debugPrint('Headers: $newHeaders');
        debugPrint('======================================================');
        response = await http.get(url, headers: newHeaders);
        debugPrint('\n[API Retry Response] =================================');
        debugPrint('URL: $url');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        debugPrint('======================================================\n');
      } else {
        _handleForcedLogout();
      }
    }

    return response;
  }

  // Generic DELETE Request helper
  static Future<http.Response> delete(
    String path, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = _getHeaders(authenticated: authenticated);

    debugPrint('\n[API Request] ========================================');
    debugPrint('METHOD: DELETE');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('======================================================');

    http.Response response;
    try {
      response = await http.delete(url, headers: headers);
      debugPrint('\n[API Response] =======================================');
      debugPrint('URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');
    } catch (e) {
      response = _handleException(e, url);
    }

    if (response.statusCode == 401 && authenticated) {
      final refreshSuccess = await _refreshTokens();
      if (refreshSuccess) {
        final newHeaders = _getHeaders(authenticated: true);
        debugPrint('\n[API Retry Request] ==================================');
        debugPrint('METHOD: DELETE');
        debugPrint('URL: $url');
        debugPrint('Headers: $newHeaders');
        debugPrint('======================================================');
        response = await http.delete(url, headers: newHeaders);
        debugPrint('\n[API Retry Response] =================================');
        debugPrint('URL: $url');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        debugPrint('======================================================\n');
      } else {
        _handleForcedLogout();
      }
    }

    return response;
  }

  // Generic PUT Request helper
  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = _getHeaders(authenticated: authenticated);
    final bodyStr = jsonEncode(body);

    debugPrint('\n[API Request] ========================================');
    debugPrint('METHOD: PUT');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: $bodyStr');
    debugPrint('======================================================');

    http.Response response;
    try {
      response = await http.put(url, headers: headers, body: bodyStr);
      debugPrint('\n[API Response] =======================================');
      debugPrint('URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');
    } catch (e) {
      response = _handleException(e, url);
    }

    if (response.statusCode == 401 && authenticated) {
      final refreshSuccess = await _refreshTokens();
      if (refreshSuccess) {
        final newHeaders = _getHeaders(authenticated: true);
        debugPrint('\n[API Retry Request] ==================================');
        debugPrint('METHOD: PUT');
        debugPrint('URL: $url');
        debugPrint('Headers: $newHeaders');
        debugPrint('Body: $bodyStr');
        debugPrint('======================================================');
        response = await http.put(url, headers: newHeaders, body: bodyStr);
        debugPrint('\n[API Retry Response] =================================');
        debugPrint('URL: $url');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        debugPrint('======================================================\n');
      } else {
        _handleForcedLogout();
      }
    }

    return response;
  }

  // Token refresh logic
  static Future<bool> _refreshTokens() async {
    final refreshToken = SessionManager.refreshToken;
    if (refreshToken == null || refreshToken.trim().isEmpty) return false;

    final url = Uri.parse('$baseUrl/auth/refresh');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({'refresh_token': refreshToken});

    debugPrint('\n[API Request (Token Refresh)] ========================');
    debugPrint('METHOD: POST');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: $body');
    debugPrint('======================================================');

    try {
      final response = await http.post(url, headers: headers, body: body);
      debugPrint('\n[API Response (Token Refresh)] =======================');
      debugPrint('URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        Map<String, dynamic> data = {};
        if (decoded is Map) {
          if (decoded['data'] is Map) {
            data = Map<String, dynamic>.from(decoded['data'] as Map);
          } else {
            data = Map<String, dynamic>.from(decoded);
          }
        }

        final newAccess = data['access_token']?.toString() ?? '';
        final newRefresh = data['refresh_token']?.toString() ?? refreshToken;
        if (newAccess.isNotEmpty) {
          await SessionManager.updateTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }
    return false;
  }

  static void _handleForcedLogout() {
    SessionManager.logout();
    if (onUnauthorized != null) {
      onUnauthorized!();
    }
  }

  static String unescapeHtml(String? input) {
    if (input == null || input.isEmpty) return '';
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&#038;', '&')
        .replaceAll('\u0026amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—');
  }

  static String _cleanHtml(String htmlString) {
    // Replace HTML paragraph/break/link tags with spaces or newlines to avoid run-on sentences
    String clean = htmlString
        .replaceAll(RegExp(r'<!--.*?-->'), '') // Comments
        .replaceAll(
          RegExp(r'</?(p|br|div|h[1-6])[^>]*>'),
          '\n',
        ) // Block tags to newlines
        .replaceAll(RegExp(r'<[^>]*>'), ''); // Any other tag

    // Decode HTML entities
    clean = unescapeHtml(clean);

    // Normalize multiple newlines and trim
    clean = clean
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');

    return clean.trim();
  }

  static String _getMessage(Map<String, dynamic> decoded, String defaultMsg) {
    String? rawMsg;
    if (decoded['message'] != null) {
      rawMsg = decoded['message'] as String;
    } else if (decoded['data'] is Map && decoded['data']['message'] != null) {
      rawMsg = decoded['data']['message'] as String;
    }
    if (rawMsg != null) {
      final cleaned = _cleanHtml(rawMsg);
      final lowercaseCleaned = cleaned.toLowerCase();
      // Check if it's a critical WordPress error, database error, or internal server error
      if (lowercaseCleaned.contains('critical error') ||
          lowercaseCleaned.contains('wordpress') ||
          lowercaseCleaned.contains('database error') ||
          lowercaseCleaned.contains('wpdberror') ||
          decoded['code'] == 'internal_server_error' ||
          decoded['code'] == 'database_error') {
        return 'We are experiencing technical difficulties. Please try again later.';
      }
      return cleaned;
    }
    return defaultMsg;
  }

  static Map<String, dynamic> _safeDecode(
    http.Response response,
    String defaultErrorMsg,
  ) {
    final bodyClean = response.body.trim();

    // Check if there is a WordPress database error embedded
    if (bodyClean.contains('wpdberror')) {
      final reg = RegExp(r'WordPress database error:<\/strong>\s*\[(.*?)\]');
      final match = reg.firstMatch(bodyClean);
      String dbErrorMsg =
          'We are experiencing technical difficulties. Please try again later.';
      if (match != null && match.groupCount >= 1) {
        debugPrint(
          '[Database Error Log] Database Error: ${match.group(1)!.replaceAll("&#039;", "'")}',
        );
      }

      // Let's check if the JSON part exists after the database error block
      final jsonIndex = bodyClean.indexOf('{"success":');
      if (jsonIndex != -1) {
        try {
          final jsonPart = bodyClean.substring(jsonIndex);
          final decoded = jsonDecode(jsonPart);
          if (decoded is Map<String, dynamic>) {
            decoded['db_error'] = dbErrorMsg;
            return decoded;
          }
        } catch (_) {}
      }

      return {
        'success': false,
        'code': 'database_error',
        'message': dbErrorMsg,
      };
    }

    try {
      final decoded = jsonDecode(bodyClean);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is List) {
        return {'success': true, 'data': decoded};
      }
      return {
        'success': false,
        'code': 'invalid_response',
        'message':
            'We are experiencing technical difficulties. Please try again later.',
      };
    } catch (e) {
      debugPrint(
        '[API Error] JSON Decode failed: $e. Body was: ${response.body}',
      );
      String msg =
          'We are experiencing technical difficulties. Please try again later.';
      return {'success': false, 'code': 'format_exception', 'message': msg};
    }
  }

  // --- API Authentication Endpoints ---

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await post('/auth/login', {
      'email': email,
      'password': password,
    });

    final decoded = _safeDecode(response, 'Login failed. Please try again.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
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

    final decoded = _safeDecode(response, 'Registration failed.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'];
      final user = data['user'] as Map<String, dynamic>;
      await SessionManager.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: user,
      );
      return {
        'success': true,
        'message': _getMessage(decoded, 'Registration successful!'),
      };
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message':
            decoded['db_error'] ?? _getMessage(decoded, 'Registration failed.'),
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
      if (businessRegistration != null)
        'business_registration': businessRegistration,
      if (businessAddress != null) 'business_address': businessAddress,
      if (websiteLink != null) 'website_link': websiteLink,
      'merchant_onboarding_type': 'biz_plus', // default
    });

    final decoded = _safeDecode(response, 'Merchant registration failed.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'];
      final user = data['user'] as Map<String, dynamic>;
      await SessionManager.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: user,
      );
      return {
        'success': true,
        'message': _getMessage(decoded, 'Registration successful!'),
      };
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message':
            decoded['db_error'] ??
            _getMessage(decoded, 'Merchant registration failed.'),
        'data': decoded['data'],
      };
    }
  }

  // Forgot Password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await post('/auth/forgot-password', {'email': email});

    final decoded = _safeDecode(response, 'Failed to send reset link.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      return {
        'success': true,
        'message': _getMessage(decoded, 'Reset link sent.'),
      };
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Failed to send reset link.'),
      };
    }
  }

  // Verify Reset OTP
  static Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otpCode,
  }) async {
    final response = await post('/auth/verify-reset-otp', {
      'email': email,
      'otp_code': otpCode,
    });

    final decoded = _safeDecode(response, 'OTP verification failed.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'] as Map<String, dynamic>;
      return {
        'success': true,
        'message': _getMessage(decoded, 'OTP verified successfully.'),
        'reset_token': data['reset_token'] as String,
      };
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'OTP verification failed.'),
      };
    }
  }

  // Reset Password
  static Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await post('/auth/reset-password', {
      'reset_token': resetToken,
      'password': password,
      'confirm_password': confirmPassword,
    });

    final decoded = _safeDecode(response, 'Failed to reset password.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'];
      final user = data['user'] as Map<String, dynamic>;
      await SessionManager.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: user,
      );
      return {
        'success': true,
        'message': _getMessage(decoded, 'Password reset successfully!'),
      };
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

    final decoded = _safeDecode(response, 'Failed to send OTP.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      return {
        'success': true,
        'message': _getMessage(decoded, 'OTP sent successfully.'),
      };
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

    final decoded = _safeDecode(response, 'OTP verification failed.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'] as Map<String, dynamic>?;
      return {
        'success': true,
        'message': _getMessage(decoded, 'OTP verified successfully.'),
        if (data != null) 'reset_key': data['reset_key'],
        if (data != null) 'reset_login': data['login'] ?? data['reset_login'],
        if (data != null) 'data': data,
      };
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'OTP verification failed.'),
      };
    }
  }

  // --- Singpass Authentication Endpoints ---

  // Init Singpass Flow
  static Future<Map<String, dynamic>> initSingpass({
    String userType = 'user',
    String mode = 'login',
  }) async {
    final response = await post('/auth/singpass/init', {
      'user_type': userType,
      'mode': mode,
    });

    final decoded = _safeDecode(
      response,
      'Failed to initialize Singpass login.',
    );
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      return {
        'success': true,
        'authorization_url': decoded['data']['authorization_url'] as String,
      };
    } else {
      return {
        'success': false,
        'code': decoded['code'] ?? 'error',
        'message': _getMessage(decoded, 'Failed to initialize Singpass login.'),
      };
    }
  }

  // Handle Singpass Callback
  static Future<Map<String, dynamic>> callbackSingpass({
    required String code,
    required String state,
  }) async {
    final response = await post(
      '/auth/singpass/callback?code=$code&state=$state',
      {},
    );

    final decoded = _safeDecode(response, 'Singpass login failed.');
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
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
        'message': _getMessage(decoded, 'Singpass login failed.'),
      };
    }
  }

  // Fetch all active sessions for the authenticated user
  static Future<Map<String, dynamic>> getSessions() async {
    try {
      final response = await get('/users/me/sessions', authenticated: true);
      return _safeDecode(response, 'Failed to fetch sessions.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch sessions: $e'};
    }
  }

  // Revoke a single session by its token ID
  static Future<Map<String, dynamic>> revokeSession(String tokenId) async {
    try {
      final response = await delete(
        '/users/me/sessions/$tokenId',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to revoke session.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to revoke session: $e'};
    }
  }

  // Revoke all sessions (logout everywhere)
  static Future<Map<String, dynamic>> revokeAllSessions() async {
    try {
      final response = await delete('/users/me/sessions', authenticated: true);
      return _safeDecode(response, 'Failed to revoke all sessions.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to revoke all sessions: $e'};
    }
  }

  // --- API Packages Endpoints ---

  // 1. Get Packages
  static Future<Map<String, dynamic>> getPackages({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
    String? status,
    bool? featured,
    int? merchantId,
    int? ownerId,
    String? ownerType,
    String? vendorMode,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (featured == true) {
        queryParams['featured'] = 'true';
      }
      if (merchantId != null) {
        queryParams['merchant_id'] = merchantId.toString();
      }
      if (ownerId != null) {
        queryParams['owner_id'] = ownerId.toString();
      }
      if (ownerType != null && ownerType.isNotEmpty) {
        queryParams['owner_type'] = ownerType;
      }
      if (vendorMode != null && vendorMode.isNotEmpty) {
        queryParams['vendor_mode'] = vendorMode;
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final path = '/packages${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await get(path, authenticated: false);
      return _safeDecode(response, 'Failed to fetch packages.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch packages: $e'};
    }
  }

  // 2. Get Package Categories
  static Future<Map<String, dynamic>> getPackageCategories() async {
    try {
      final response = await get('/packages/categories', authenticated: false);
      return _safeDecode(response, 'Failed to fetch categories.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch categories: $e'};
    }
  }

  // 3. Get Package by ID
  static Future<Map<String, dynamic>> getPackageById(int id) async {
    try {
      final response = await get('/packages/$id', authenticated: false);
      return _safeDecode(response, 'Failed to fetch package details.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch package details: $e',
      };
    }
  }

  // 4. Create Package
  static Future<Map<String, dynamic>> createPackage(
    Map<String, dynamic> packageData,
  ) async {
    try {
      final response = await post(
        '/packages',
        packageData,
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to create package.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to create package: $e'};
    }
  }

  // 5. Update Package
  static Future<Map<String, dynamic>> updatePackage(
    int id,
    Map<String, dynamic> packageData,
  ) async {
    try {
      // Use PUT method as defined in API docs
      final url = Uri.parse('$baseUrl/packages/$id');
      final headers = _getHeaders(authenticated: true);
      final bodyStr = jsonEncode(packageData);

      debugPrint('\n[API Request] ========================================');
      debugPrint('METHOD: PUT');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: $bodyStr');
      debugPrint('======================================================');

      final response = await http.put(url, headers: headers, body: bodyStr);

      debugPrint('\n[API Response] =======================================');
      debugPrint('URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');

      return _safeDecode(response, 'Failed to update package.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to update package: $e'};
    }
  }

  // 6. Delete Package
  static Future<Map<String, dynamic>> deletePackage(int id) async {
    try {
      final response = await delete('/packages/$id', authenticated: true);
      return _safeDecode(response, 'Failed to delete package.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete package: $e'};
    }
  }

  // 7. Update Package Status
  static Future<Map<String, dynamic>> updatePackageStatus(
    int id,
    String status,
  ) async {
    try {
      final s = status.toLowerCase().trim();
      final String validStatus = (s == 'published' || s == 'publish') ? 'published' : 'unpublish';

      final response = await post('/packages/$id/status', {
        'status': validStatus,
      }, authenticated: true);
      return _safeDecode(response, 'Failed to update package status.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update package status: $e',
      };
    }
  }

  // 8. Upload Package Images (Multipart)
  static Future<Map<String, dynamic>> uploadPackageImages(
    int id,
    List<String> filePaths,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/packages/$id/images');
      final request = http.MultipartRequest('POST', url);

      if (SessionManager.accessToken != null) {
        request.headers['Authorization'] =
            'Bearer ${SessionManager.accessToken}';
      }

      for (int i = 0; i < filePaths.length; i++) {
        final path = filePaths[i];
        if (path.startsWith('assets/')) {
          // If it is a mock asset path, we cannot read it directly as a file from path.
          // In a real application, users select real files. For testing/demo with mock assets,
          // we can send a mock text file or skip it, but let's implement standard file path upload.
          continue;
        }
        final file = await http.MultipartFile.fromPath('file$i', path);
        request.files.add(file);
      }

      // If we only have mock assets and no files were added, we can send a dummy byte array as a placeholder
      if (request.files.isEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file0',
            [137, 80, 78, 71, 13, 10, 26, 10], // Dummy PNG header
            filename: 'placeholder.png',
          ),
        );
      }

      debugPrint('\n[API Multipart Request] =================================');
      debugPrint('METHOD: POST (Multipart)');
      debugPrint('URL: $url');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Files Count: ${request.files.length}');
      debugPrint('======================================================');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('\n[API Response] =======================================');
      debugPrint('URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');

      return _safeDecode(response, 'Failed to upload images.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload images: $e'};
    }
  }

  // 9. Delete Package Image
  static Future<Map<String, dynamic>> deletePackageImage(
    int id,
    int imageId,
  ) async {
    try {
      final response = await delete(
        '/packages/$id/images/$imageId',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to remove image.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove image: $e'};
    }
  }

  // 10. Upload Package Submission Receipt (C2C Original Purchase Proof)
  static Future<Map<String, dynamic>> uploadPackageReceipt(
    int packageId,
    String filePath,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/packages/$packageId/receipt');
      final request = http.MultipartRequest('POST', url);

      if (SessionManager.accessToken != null) {
        request.headers['Authorization'] = 'Bearer ${SessionManager.accessToken}';
      }

      if (!filePath.startsWith('assets/') && filePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('file', filePath);
        request.files.add(file);
      }

      if (request.files.isEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            [137, 80, 78, 71, 13, 10, 26, 10], // Placeholder PNG
            filename: 'receipt.png',
          ),
        );
      }

      debugPrint('\n[API Multipart Request] POST $url');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[API Response] Status: ${response.statusCode}, Body: ${response.body}');

      return _safeDecode(response, 'Failed to upload package receipt.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload package receipt: $e'};
    }
  }

  // 11. Upload Legal Clearance Evidence (C2C Manual Vendor Clearance Proof)
  static Future<Map<String, dynamic>> uploadPackageClearanceEvidence(
    int packageId,
    String filePath,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/packages/$packageId/clearance-evidence');
      final request = http.MultipartRequest('POST', url);

      if (SessionManager.accessToken != null) {
        request.headers['Authorization'] = 'Bearer ${SessionManager.accessToken}';
      }

      if (!filePath.startsWith('assets/') && filePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('file', filePath);
        request.files.add(file);
      }

      if (request.files.isEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            [137, 80, 78, 71, 13, 10, 26, 10], // Placeholder PNG
            filename: 'clearance_evidence.png',
          ),
        );
      }

      debugPrint('\n[API Multipart Request] POST $url');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[API Response] Status: ${response.statusCode}, Body: ${response.body}');

      return _safeDecode(response, 'Failed to upload clearance evidence.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload clearance evidence: $e'};
    }
  }

  // 10. Like Package (Add to wishlist)
  static Future<Map<String, dynamic>> likePackage(int id) async {
    wishlistIdsCache.add(id);
    try {
      final response = await post(
        '/packages/$id/like',
        {},
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to add to wishlist.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to add to wishlist: $e'};
    }
  }

  // 11. Unlike Package (Remove from wishlist)
  static Future<Map<String, dynamic>> unlikePackage(int id) async {
    wishlistIdsCache.remove(id);
    try {
      final response = await delete('/packages/$id/like', authenticated: true);
      return _safeDecode(response, 'Failed to remove from wishlist.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to remove from wishlist: $e',
      };
    }
  }

  // --- Additional Merchant/User Package Endpoints ---

  // Get All Merchants
  static Future<Map<String, dynamic>> getMerchants() async {
    try {
      final response = await get('/merchants', authenticated: false);
      return _safeDecode(response, 'Failed to fetch merchants.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch merchants: $e'};
    }
  }

  // Get Merchant My Listings (Own packages only — created by this merchant account)
  // NOTE: /packages?merchant_id=X returns ALL packages assigned to a merchant by admins,
  // which are NOT the user's own listings. My Listings = only self-created packages.
  static Future<Map<String, dynamic>> getMerchantPackages({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'status': (status != null && status.isNotEmpty) ? status : 'any',
      };
      final queryString = Uri(queryParameters: queryParams).query;

      List<dynamic> combinedList = [];

      // ── Step 1: Fetch /merchants/me/packages (own merchant-created packages) ──
      final ownPath =
          '/merchants/me/packages${queryString.isNotEmpty ? '?$queryString' : ''}';
      final ownResponse = await get(ownPath, authenticated: true);
      final ownDecoded = _safeDecode(
        ownResponse,
        'Failed to fetch own merchant packages.',
      );

      if (ownDecoded['success'] == true && ownDecoded['data'] is List) {
        for (var item in ownDecoded['data']) {
          if (item is Map) {
            final mapped = Map<String, dynamic>.from(item);
            mapped['is_owner'] = true; // can edit & delete
            combinedList.add(mapped);
          } else {
            combinedList.add(item);
          }
        }
      }

      // ── Step 2: For dual-role accounts (is_user: true), also fetch C2C packages ──
      // e.g. tagpools@gmail.com has is_merchant=true AND is_user=true
      if (SessionManager.isUser) {
        final userPkgRes = await get(
          '/users/me/packages?page=$page&per_page=$perPage${status != null && status.isNotEmpty ? '&status=$status' : ''}',
          authenticated: true,
        );
        final userPkgDecoded = _safeDecode(userPkgRes, '');

        if (userPkgDecoded['success'] == true &&
            userPkgDecoded['data'] is List) {
          for (var item in userPkgDecoded['data']) {
            final bool alreadyExists = combinedList.any(
              (e) => e['id'] == item['id'],
            );
            if (!alreadyExists) {
              if (item is Map) {
                final mapped = Map<String, dynamic>.from(item);
                mapped['is_owner'] = true; // can edit & delete
                combinedList.add(mapped);
              } else {
                combinedList.add(item);
              }
            }
          }
        }
      }

      // ── Step 3: /packages?merchant_id=X (website-parity fallback) ──
      // The website merchant dashboard uses this. Backend may miss packages in
      // /merchants/me/packages (known bug for some accounts like Rolys/synvolv3).
      try {
        final meRes = await get('/merchants/me', authenticated: true);
        final meDecoded = _safeDecode(meRes, '');
        if (meDecoded['success'] == true && meDecoded['data'] is Map) {
          final actualMerchantId = int.tryParse(
            (meDecoded['data'] as Map)['id']?.toString() ?? '',
          );
          if (actualMerchantId != null && actualMerchantId > 0) {
            final assignedParams = <String, String>{
              'merchant_id': actualMerchantId.toString(),
              'page': page.toString(),
              'per_page': perPage.toString(),
            };
            if (status != null && status.isNotEmpty) {
              assignedParams['status'] = status;
            }
            final assignedQS = Uri(queryParameters: assignedParams).query;
            final assignedResponse = await get(
              '/packages?$assignedQS',
              authenticated: true,
            );
            final assignedDecoded = _safeDecode(assignedResponse, '');

            if (assignedDecoded['success'] == true &&
                assignedDecoded['data'] is List) {
              final wpUserId = SessionManager.userId;
              for (var item in assignedDecoded['data']) {
                final bool alreadyExists = combinedList.any(
                  (e) => e['id'] == item['id'],
                );
                if (!alreadyExists && item is Map) {
                  final mapped = Map<String, dynamic>.from(item);
                  // Package is owned by this merchant if presented_by.merchant_id matches
                  // or owner_id matches the merchant profile ID or the WP user ID
                  final presentedById = item['presented_by'] is Map
                      ? int.tryParse(
                          item['presented_by']['merchant_id']?.toString() ?? '',
                        )
                      : null;
                  final ownerIdField =
                      int.tryParse(item['owner_id']?.toString() ?? '0') ?? 0;
                  final isOwnPackage =
                      presentedById == actualMerchantId ||
                      ownerIdField == actualMerchantId ||
                      ownerIdField == wpUserId;
                  if (isOwnPackage) {
                    mapped['is_owner'] = true;
                    combinedList.add(mapped);
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      return {'success': true, 'data': combinedList};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch merchant packages: $e',
      };
    }
  }

  // User Created Packages Cache & Persistence
  static Set<int> userCreatedPackageIds = {1379, 1388};

  static void trackCreatedPackageId(int id) {
    if (id > 0) {
      userCreatedPackageIds.add(id);
    }
  }

  // Get User Listed Packages (Own C2C)
  static Future<Map<String, dynamic>> getUserPackages({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final stParam = (status != null && status.isNotEmpty) ? status : 'any';
      final path = '/users/me/packages?page=$page&per_page=$perPage&status=$stParam';
      final response = await get(path, authenticated: true);
      final res = _safeDecode(response, 'Failed to fetch user packages.');

      List<Map<String, dynamic>> packages = [];
      if (res['success'] == true && res['data'] is List) {
        packages = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      // Merge tracked created packages (e.g. IDs 1379, 1388, newly created)
      for (final id in userCreatedPackageIds) {
        final bool alreadyInList = packages.any((p) => int.tryParse(p['id']?.toString() ?? '') == id);
        if (!alreadyInList) {
          final detailRes = await getPackageById(id);
          if (detailRes['success'] == true && detailRes['data'] is Map) {
            final pkgMap = Map<String, dynamic>.from(detailRes['data'] as Map);
            packages.add(pkgMap);
          }
        }
      }

      return {
        'success': true,
        'data': packages,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch user packages: $e'};
    }
  }

  // Get User Wishlist Packages
  static Future<Map<String, dynamic>> getUserWishlist({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final path = '/users/me/wishlist?page=$page&per_page=$perPage';
      final response = await get(path, authenticated: true);
      final res = _safeDecode(response, 'Failed to fetch wishlist.');
      if (res['success'] == true && res['data'] is List) {
        for (var item in res['data'] as List) {
          final id = int.tryParse(item['id']?.toString() ?? '');
          if (id != null) wishlistIdsCache.add(id);
        }
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch wishlist: $e'};
    }
  }

  // Place Order
  static Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await post('/orders', orderData, authenticated: true);
      return _safeDecode(response, 'Failed to place order.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to place order: $e'};
    }
  }

  // Start Redemption (Send OTP)
  static Future<Map<String, dynamic>> startRedemption(int orderId) async {
    try {
      final response = await post(
        '/orders/$orderId/redemption/start',
        {},
        authenticated: true,
      );
      final decoded = _safeDecode(response, 'Failed to send OTP code.');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        decoded['success'] = true;
      } else {
        decoded['success'] = false;
        if (decoded['message'] == null || decoded['message'].toString().isEmpty) {
          decoded['message'] = 'Failed to send OTP code (${response.statusCode}).';
        }
      }
      return decoded;
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP code: $e'};
    }
  }

  // Verify Redemption (Submit OTP)
  static Future<Map<String, dynamic>> verifyRedemption(int orderId, String code) async {
    try {
      final response = await post(
        '/orders/$orderId/redemption/verify',
        {'code': code},
        authenticated: true,
      );
      final decoded = _safeDecode(response, 'Failed to verify OTP code.');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        decoded['success'] = true;
      } else {
        decoded['success'] = false;
        if (decoded['message'] == null || decoded['message'].toString().isEmpty) {
          decoded['message'] = 'Failed to verify OTP code (${response.statusCode}).';
        }
      }
      return decoded;
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify OTP code: $e'};
    }
  }

  // Get My Orders
  static Future<Map<String, dynamic>> getMyOrders({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/users/me/orders?page=$page&per_page=$perPage',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch orders.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch orders: $e'};
    }
  }

  // Create Stripe PaymentIntent
  static Future<Map<String, dynamic>> createStripePaymentIntent(
    int orderId,
  ) async {
    try {
      final response = await post('/payments/stripe/intent', {
        'order_id': orderId,
      }, authenticated: true);
      return _safeDecode(response, 'Failed to create payment intent.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create payment intent: $e',
      };
    }
  }

  // --- API Cart Endpoints ---

  // Get Cart
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await get('/cart', authenticated: true);
      return _safeDecode(response, 'Failed to fetch cart.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch cart: $e'};
    }
  }

  // Clear Cart
  static Future<Map<String, dynamic>> clearCart() async {
    try {
      final response = await delete('/cart', authenticated: true);
      return _safeDecode(response, 'Failed to clear cart.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to clear cart: $e'};
    }
  }

  // Add Item to Cart
  static Future<Map<String, dynamic>> addToCart(int packageId) async {
    try {
      final response = await post('/cart/items', {
        'package_id': packageId,
      }, authenticated: true);
      return _safeDecode(response, 'Failed to add item to cart.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to add item to cart: $e'};
    }
  }

  // Remove Item from Cart
  static Future<Map<String, dynamic>> removeFromCart(int packageId) async {
    try {
      final response = await delete(
        '/cart/items/$packageId',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to remove item from cart.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to remove item from cart: $e',
      };
    }
  }

  // --- Wallet & Stripe Payments Endpoints ---

  // Get Wallet Balance & Info
  static Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await get('/payments/wallet', authenticated: true);
      return _safeDecode(response, 'Failed to fetch wallet information.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch wallet: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPaymentsWallet() => getWallet();

  // Get Wallet Transactions
  static Future<Map<String, dynamic>> getWalletTransactions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/payments/wallet/transactions?page=$page&per_page=$perPage',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch transactions.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch transactions: $e'};
    }
  }

  // Request Wallet Withdrawal
  static Future<Map<String, dynamic>> withdrawWallet(double amount) async {
    try {
      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      final url = Uri.parse('$baseUrl/payments/wallet/withdraw');
      final headers = _getHeaders(authenticated: true);
      headers['Idempotency-Key'] = uuid;

      final bodyStr = jsonEncode({'amount': amount});

      debugPrint(
        '\n[Withdraw Request] ========================================',
      );
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: $bodyStr');

      final response = await http.post(url, headers: headers, body: bodyStr);
      return _safeDecode(response, 'Failed to request withdrawal.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to request withdrawal: $e'};
    }
  }

  // Get Stripe Connected Account Status
  static Future<Map<String, dynamic>> getStripeAccountStatus() async {
    try {
      final response = await get(
        '/payments/stripe/account',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch Stripe account status.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch Stripe status: $e'};
    }
  }

  // Onboard Stripe Connected Account
  static Future<Map<String, dynamic>> onboardStripe(String role) async {
    try {
      final response = await post('/payments/stripe/onboard', {
        'role': role,
      }, authenticated: true);
      return _safeDecode(response, 'Failed to initialize Stripe onboarding.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to onboard Stripe: $e'};
    }
  }

  // Disconnect Stripe Connected Account
  static Future<Map<String, dynamic>> disconnectStripe() async {
    try {
      final response = await post(
        '/payments/stripe/disconnect',
        {},
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to disconnect Stripe account.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to disconnect Stripe: $e'};
    }
  }

  // Reconnect Stripe Connected Account
  static Future<Map<String, dynamic>> reconnectStripe() async {
    try {
      final response = await post(
        '/payments/stripe/reconnect',
        {},
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to reconnect Stripe account.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to reconnect Stripe: $e'};
    }
  }

  // Get Payout Settings
  static Future<Map<String, dynamic>> getPayoutSettings() async {
    try {
      final response = await get(
        '/users/me/payout-settings',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch payout settings.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch payout settings: $e',
      };
    }
  }

  // Update Payout Settings
  static Future<Map<String, dynamic>> updatePayoutSettings(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await put(
        '/users/me/payout-settings',
        data,
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to update payout settings.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update payout settings: $e',
      };
    }
  }

  // ── User Profile ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUserMe() async {
    try {
      final response = await get('/users/me', authenticated: true);
      return _safeDecode(response, 'Failed to fetch user profile.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch user profile: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserMe(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await put('/users/me', data, authenticated: true);
      return _safeDecode(response, 'Failed to update user profile.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadUserAvatar(String filePath) async {
    try {
      final url = Uri.parse('$baseUrl/users/me/avatar');
      final request = http.MultipartRequest('POST', url);
      if (SessionManager.accessToken != null) {
        request.headers['Authorization'] =
            'Bearer ${SessionManager.accessToken}';
      }
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

      debugPrint('\n[API Multipart Request] =================================');
      debugPrint('METHOD: POST (User Avatar)');
      debugPrint('URL: $url');
      debugPrint('======================================================');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('\n[API Response] =======================================');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');

      return _safeDecode(response, 'Failed to upload user avatar.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload avatar: $e'};
    }
  }

  // ── Merchant Profile ─────────────────────────────────────────
  static Future<Map<String, dynamic>> getMerchantMe() async {
    try {
      final response = await get('/merchants/me', authenticated: true);
      return _safeDecode(response, 'Failed to fetch merchant profile.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch merchant profile: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateMerchantMe(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await put('/merchants/me', data, authenticated: true);
      return _safeDecode(response, 'Failed to update merchant profile.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update merchant profile: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> uploadMerchantLogo(
    String filePath,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/merchants/me/logo');
      final request = http.MultipartRequest('POST', url);
      if (SessionManager.accessToken != null) {
        request.headers['Authorization'] =
            'Bearer ${SessionManager.accessToken}';
      }
      request.files.add(await http.MultipartFile.fromPath('logo', filePath));

      debugPrint('\n[API Multipart Request] =================================');
      debugPrint('METHOD: POST (Merchant Logo)');
      debugPrint('URL: $url');
      debugPrint('======================================================');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('\n[API Response] =======================================');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================\n');

      return _safeDecode(response, 'Failed to upload merchant logo.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload logo: $e'};
    }
  }

  // ── C2C Sales ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMySales({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/users/me/sales?page=$page&per_page=$perPage',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch sales.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch sales: $e'};
    }
  }

  // ── User Payout Requests ────────────────────────────────────
  static Future<Map<String, dynamic>> getUserPayoutRequests({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/users/me/payout-requests?page=$page&per_page=$perPage',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch payout requests.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch payout requests: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> createUserPayoutRequest(
    double amount, {
    String method = 'stripe',
  }) async {
    try {
      final response = await post('/users/me/payout-requests', {
        'amount': amount,
        'payout_method': method,
      }, authenticated: true);
      return _safeDecode(response, 'Failed to create payout request.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create payout request: $e',
      };
    }
  }

  // ── Merchant Wallet & Transactions ──────────────────────────
  static Future<Map<String, dynamic>> getMerchantWallet() async {
    try {
      final response = await get('/merchants/me/wallet', authenticated: true);
      return _safeDecode(response, 'Failed to fetch merchant wallet.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch merchant wallet: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMerchantTransactions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/merchants/me/transactions?page=$page&per_page=$perPage',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch merchant transactions.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch merchant transactions: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMerchantStats() async {
    try {
      final response = await get('/merchants/me/stats', authenticated: true);
      return _safeDecode(response, 'Failed to fetch merchant stats.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch merchant stats: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMerchantOrders({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/merchants/me/orders?page=$page&per_page=$perPage',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch merchant orders.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch merchant orders: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getUserTransactions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/users/me/transactions?page=$page&per_page=$perPage',
        authenticated: true,
      );
      return _safeDecode(response, 'Failed to fetch transactions.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch transactions: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPublicMerchantProfile(
    int merchantId,
  ) async {
    try {
      final response = await get(
        '/merchants/$merchantId',
        authenticated: false,
      );
      return _safeDecode(response, 'Failed to fetch public merchant profile.');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch public merchant profile: $e',
      };
    }
  }

  // User Profile Cache
  static Map<int, Map<String, dynamic>> usersCache = {};

  static Future<Map<String, dynamic>> getPublicUserProfile(int userId) async {
    if (usersCache.containsKey(userId)) {
      return {'success': true, 'data': usersCache[userId]};
    }
    try {
      final basewp = baseUrl.replaceAll('/twicely/v1', '');
      final url = Uri.parse('$basewp/wp/v2/users/$userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        usersCache[userId] = data;
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'User profile not found (${response.statusCode})',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch public profile: $e',
      };
    }
  }

  static Future<void> prefetchOwners(List<dynamic> packages) async {
    final Set<int> missingUserIds = {};
    final Set<int> missingMerchantIds = {};

    for (final pkg in packages) {
      if (pkg is! Map) continue;
      final ownerId = int.tryParse(pkg['owner_id']?.toString() ?? '') ?? 0;
      final merchantId =
          int.tryParse(pkg['merchant_id']?.toString() ?? '') ?? 0;
      final ownerType = pkg['owner_type']?.toString() ?? '';

      if (merchantId > 0 && !merchantsCache.containsKey(merchantId)) {
        missingMerchantIds.add(merchantId);
      }
      if (ownerId > 0) {
        if (ownerType == 'merchant') {
          if (!merchantsCache.containsKey(ownerId)) {
            missingMerchantIds.add(ownerId);
          }
        } else if (!usersCache.containsKey(ownerId)) {
          missingUserIds.add(ownerId);
        }
      }
    }

    final futures = <Future>[];
    for (final mId in missingMerchantIds) {
      futures.add(getPublicMerchantProfile(mId));
    }
    for (final uId in missingUserIds) {
      futures.add(getPublicUserProfile(uId));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  static Map<String, dynamic> resolveOwnerInfo(Map<String, dynamic> pkg) {
    String name = 'Twicely';
    String avatar = '';
    bool isMerchant = false;
    int? merchantId;
    int? ownerId;

    final ownerIdVal = int.tryParse(pkg['owner_id']?.toString() ?? '');
    int? merchantIdVal = int.tryParse(pkg['merchant_id']?.toString() ?? '');
    if (merchantIdVal == null && pkg['presented_by'] is Map) {
      merchantIdVal = int.tryParse(
        (pkg['presented_by'] as Map)['merchant_id']?.toString() ?? '',
      );
    }
    final ownerTypeVal = pkg['owner_type']?.toString() ?? '';

    if (ownerIdVal != null && ownerIdVal > 0) {
      ownerId = ownerIdVal;
    }
    if (merchantIdVal != null && merchantIdVal > 0) {
      merchantId = merchantIdVal;
    }

    Map<String, dynamic> buildResult(
      String resName,
      String resAvatar,
      bool resIsMerchant,
    ) {
      final sanitizedName = resName.trim().isNotEmpty
          ? unescapeHtml(resName.trim())
          : (resIsMerchant ? 'Twicely Merchant' : 'Twicely');
      return {
        'name': sanitizedName,
        'avatar': resAvatar,
        'is_merchant': resIsMerchant,
        'merchant_id': merchantId,
        'owner_id': ownerId,
      };
    }

    // 1. Explicit owner object in payload
    if (pkg['owner'] is Map) {
      final o = pkg['owner'] as Map;
      name =
          o['name']?.toString() ??
          o['business_name']?.toString() ??
          o['display_name']?.toString() ??
          name;
      avatar =
          o['avatar']?.toString() ??
          o['avatar_url']?.toString() ??
          o['logo_url']?.toString() ??
          o['photo']?.toString() ??
          avatar;
      if (o['is_merchant'] == true || ownerTypeVal == 'merchant') {
        isMerchant = true;
      }
      return buildResult(name, avatar, isMerchant);
    }

    // 2. Explicit owner_name / owner_avatar in payload
    if (pkg['owner_name'] != null && pkg['owner_name'].toString().isNotEmpty) {
      name = pkg['owner_name'].toString();
      avatar =
          pkg['owner_avatar']?.toString() ??
          pkg['owner_photo']?.toString() ??
          '';
      isMerchant = ownerTypeVal == 'merchant';
      return buildResult(name, avatar, isMerchant);
    }

    // 3. User Owner Case (owner_type == 'user' or owner_id > 0 with non-merchant owner_type)
    if (ownerIdVal != null && ownerIdVal > 0 && ownerTypeVal != 'merchant') {
      if (usersCache.containsKey(ownerIdVal)) {
        final u = usersCache[ownerIdVal]!;
        name =
            u['name']?.toString() ??
            u['display_name']?.toString() ??
            'Twicely Member';
        final avatarUrls = u['avatar_urls'];
        if (avatarUrls is Map) {
          avatar =
              avatarUrls['96']?.toString() ??
              avatarUrls['48']?.toString() ??
              avatarUrls['24']?.toString() ??
              '';
        } else if (u['avatar'] != null) {
          avatar = u['avatar'].toString();
        }
        isMerchant = false;
        return buildResult(name, avatar, isMerchant);
      }
    }

    // 4. Merchant Owner Case (owner_type == 'merchant' OR merchant_id > 0)
    final targetMerchantId =
        (ownerTypeVal == 'merchant' && ownerIdVal != null && ownerIdVal > 0
            ? ownerIdVal
            : null) ??
        merchantIdVal;
    if (targetMerchantId != null && targetMerchantId > 0) {
      merchantId = targetMerchantId;
      isMerchant = true;
      if (merchantsCache.containsKey(targetMerchantId)) {
        final m = merchantsCache[targetMerchantId]!;
        name =
            m['business_name']?.toString() ??
            m['name']?.toString() ??
            'Twicely Merchant';
        avatar = getMerchantLogo(targetMerchantId, m['logo_url']?.toString());
        return buildResult(name, avatar, isMerchant);
      }

      // Explicit merchant object or merchantName field in pkg payload
      if (pkg['merchant'] is Map) {
        final m = pkg['merchant'] as Map;
        name =
            m['name']?.toString() ??
            m['business_name']?.toString() ??
            m['display_name']?.toString() ??
            name;
        avatar = getMerchantLogo(
          targetMerchantId,
          m['logo']?.toString() ?? m['logo_url']?.toString(),
        );
        return buildResult(name, avatar, isMerchant);
      }
      if (pkg['merchantName'] != null &&
          pkg['merchantName'].toString().isNotEmpty) {
        name = pkg['merchantName'].toString();
        avatar = getMerchantLogo(
          targetMerchantId,
          pkg['merchantLogo']?.toString(),
        );
        return buildResult(name, avatar, isMerchant);
      }

      if (name.isEmpty || name == 'Twicely User') {
        name = 'Twicely Merchant';
      }

      return buildResult(name, avatar, isMerchant);
    }

    // 5. Presented by (fallback for vendor info if owner profile not resolved)
    if (pkg['presented_by'] is Map) {
      final pb = pkg['presented_by'] as Map;
      name =
          pb['name']?.toString() ??
          pb['display_name']?.toString() ??
          pb['business_name']?.toString() ??
          name;
      avatar =
          pb['logo']?.toString() ??
          pb['avatar']?.toString() ??
          pb['logo_url']?.toString() ??
          '';
      final pbMerchantId = int.tryParse(pb['merchant_id']?.toString() ?? '');
      if (pbMerchantId != null && pbMerchantId > 0) {
        merchantId = pbMerchantId;
        isMerchant = true;
      }
      return buildResult(name, avatar, isMerchant);
    }

    // 6. Manual vendor mode (C2C package with non-listed vendor)
    if ((pkg['vendor_mode'] == 'manual' || pkg['manual_vendor_name'] != null) &&
        pkg['manual_vendor_name'].toString().isNotEmpty) {
      name = pkg['manual_vendor_name'].toString();
      avatar = '';
      isMerchant = false;
      return buildResult(name, avatar, isMerchant);
    }

    // 7. Default fallback for unassigned / missing owner packages
    return buildResult(name, avatar, isMerchant);
  }
}
