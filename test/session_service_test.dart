import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theventapp/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionService tests', () {
    test('returns false when no user is logged in', () async {
      final session = SessionService();
      final isValid = await session.isSessionValid();
      expect(isValid, isFalse);
    });

    test('onLogin stores session and marks session valid', () async {
      final session = SessionService();
      await session.onLogin('test_user_123');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('session_is_logged_in'), isTrue);
      expect(prefs.getString('session_user_id'), 'test_user_123');
      expect(prefs.getInt('session_last_active_timestamp'), isNotNull);

      final isValid = await session.isSessionValid();
      expect(isValid, isTrue);
    });

    test('session expires after 7 days of inactivity (1 week policy)', () async {
      final session = SessionService();
      final prefs = await SharedPreferences.getInstance();

      // Set session logged in 8 days ago
      final eightDaysAgo = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      await prefs.setBool('session_is_logged_in', true);
      await prefs.setString('session_user_id', 'test_user_123');
      await prefs.setInt('session_last_active_timestamp', eightDaysAgo);

      final isValid = await session.isSessionValid();
      // Should expire and return false
      expect(isValid, isFalse);

      // Session flags should be cleared
      expect(prefs.getBool('session_is_logged_in'), isNull);
      expect(prefs.getString('session_user_id'), isNull);
    });

    test('session stays active within 7 days and updates activity timestamp', () async {
      final session = SessionService();
      final prefs = await SharedPreferences.getInstance();

      // Set session logged in 3 days ago
      final threeDaysAgo = DateTime.now()
          .subtract(const Duration(days: 3))
          .millisecondsSinceEpoch;
      await prefs.setBool('session_is_logged_in', true);
      await prefs.setString('session_user_id', 'test_user_123');
      await prefs.setInt('session_last_active_timestamp', threeDaysAgo);

      final isValid = await session.isSessionValid();
      expect(isValid, isTrue);

      final updatedTime = prefs.getInt('session_last_active_timestamp');
      expect(updatedTime, isNotNull);
      expect(updatedTime! > threeDaysAgo, isTrue);
    });

    test('onLogout clears all session data', () async {
      final session = SessionService();
      await session.onLogin('test_user_123');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('session_is_logged_in'), isTrue);

      await session.onLogout();
      expect(prefs.getBool('session_is_logged_in'), isNull);
      expect(prefs.getString('session_user_id'), isNull);
      expect(prefs.getInt('session_last_active_timestamp'), isNull);
    });
  });
}
