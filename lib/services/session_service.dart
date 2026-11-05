import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages local user session persistence and the 1-week inactivity timeout policy.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const String _keyIsLoggedIn = 'session_is_logged_in';
  static const String _keyUserId = 'session_user_id';
  static const String _keyLastActive = 'session_last_active_timestamp';

  /// Session timeout threshold: 7 days (1 week) of inactivity
  static const Duration sessionTimeout = Duration(days: 7);

  /// Called when a user successfully logs in or registers.
  Future<void> onLogin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setInt(_keyLastActive, DateTime.now().millisecondsSinceEpoch);
  }

  /// Called when a user manually logs out or session expires.
  Future<void> onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyLastActive);
  }

  /// Updates the last active timestamp to now.
  Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (isLoggedIn) {
      await prefs.setInt(_keyLastActive, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Checks if the current session is valid and within the 1-week activity window.
  /// If inactive for more than 1 week, logs out automatically and returns false.
  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final lastActiveMs = prefs.getInt(_keyLastActive);

    if (!isLoggedIn) {
      // Check if Firebase already has a logged-in user (e.g. from prior session or app update)
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await onLogin(currentUser.uid);
          return true;
        }
      } catch (_) {}
      return false;
    }

    if (lastActiveMs == null) {
      // If flag is true but timestamp is missing, initialize timestamp now
      await recordActivity();
      return true;
    }

    final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
    final now = DateTime.now();

    // Check if 7 days (1 week) of inactivity has elapsed
    if (now.difference(lastActive) > sessionTimeout) {
      // Session expired due to inactivity
      await onLogout();
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      return false;
    }

    // Still within active window -> refresh timestamp
    await recordActivity();
    return true;
  }
}
