class SessionManager {
  static bool _isLoggedIn = false;
  static String? _userName;
  static String? _userEmail;

  static bool get isLoggedIn => _isLoggedIn;
  static String? get userName => _userName;
  static String? get userEmail => _userEmail;

  static void login(String email, {String name = 'Twicely Member'}) {
    _isLoggedIn = true;
    _userEmail = email;
    _userName = name;
  }

  static void logout() {
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
  }
}
