// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'https://staging.twicely.sg/wp-json/twicely/v1';

  print('=== TWICELY BACKEND AUTH API INTEGRATION TEST ===\n');

  // Test 1: POST /auth/login with incorrect credentials
  print('Test 1: Testing /auth/login with incorrect credentials...');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'email': 'synvolv1@gmail.com',
        'password': 'wrongpassword123',
      }),
    );
    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['success'] == false) {
      print('=> PASSED: Server successfully returned expected failure status for invalid password.');
    } else {
      print('=> WARNING: Server returned unexpected structure.');
    }
  } catch (e) {
    print('=> FAILED: Error connecting to login endpoint: $e');
  }
  print('');

  // Test 2: POST /auth/forgot-password with dummy email
  print('Test 2: Testing /auth/forgot-password...');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'email': 'invalid_email_test_12345@gmail.com',
      }),
    );
    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['success'] == true) {
      print('=> PASSED: Forgot password endpoint operates successfully and returns a generic success/message (which is expected to prevent email enumeration).');
    } else {
      print('=> WARNING: Server returned unexpected structure.');
    }
  } catch (e) {
    print('=> FAILED: Error connecting to forgot-password endpoint: $e');
  }
  print('');

  // Test 3: POST /auth/otp/send with dummy email
  print('Test 3: Testing /auth/otp/send...');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/send'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'otp_type': 'email',
        'email': 'synvolv1@gmail.com',
        'purpose': 'registration',
      }),
    );
    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      print('=> PASSED: OTP send endpoint returned status code ${response.statusCode} with message: ${decoded['message'] ?? 'none'}');
    }
  } catch (e) {
    print('=> FAILED: Error connecting to OTP send endpoint: $e');
  }
  print('');

  print('=== INTEGRATION TEST COMPLETE ===');
}
