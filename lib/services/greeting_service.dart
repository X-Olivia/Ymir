import 'package:shared_preferences/shared_preferences.dart';

class GreetingService {
  static const String _greetingEnabledKey = 'greeting_enabled';
  static const String _lastMorningGreetingKey = 'last_morning_greeting';
  static const String _lastAfternoonGreetingKey = 'last_afternoon_greeting';
  static const String _lastEveningGreetingKey = 'last_evening_greeting';
  static SharedPreferences? _prefs;
  
  // Initialize service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Check if greeting feature is enabled
  static bool isGreetingEnabled() {
    return _prefs?.getBool(_greetingEnabledKey) ?? true;
  }
  
  // Set whether greetings are enabled
  static Future<void> setGreetingEnabled(bool enabled) async {
    await _prefs?.setBool(_greetingEnabledKey, enabled);
  }

  // Get the current period
  static String _getCurrentPeriod() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 18) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  // Get greeting
  static String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 18) {
      return 'Good afternoon';
    } else {
      return 'Good night';
    }
  }
  
  // Check if the greeting should be displayed for the current period
  static bool shouldShowGreetingNow() {
    if (!isGreetingEnabled()) return false;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final period = _getCurrentPeriod();
    String? lastGreetingDate;

    switch (period) {
      case 'morning':
        lastGreetingDate = _prefs?.getString(_lastMorningGreetingKey);
        break;
      case 'afternoon':
        lastGreetingDate = _prefs?.getString(_lastAfternoonGreetingKey);
        break;
      case 'evening':
        lastGreetingDate = _prefs?.getString(_lastEveningGreetingKey);
        break;
    }

    return lastGreetingDate != today;
  }
  
  // Mark the greeting for the current period as shown
  static Future<void> markGreetingShown() async {
    if (_prefs == null) return;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    final period = _getCurrentPeriod();

    switch (period) {
      case 'morning':
        await _prefs!.setString(_lastMorningGreetingKey, today);
        break;
      case 'afternoon':
        await _prefs!.setString(_lastAfternoonGreetingKey, today);
        break;
      case 'evening':
        await _prefs!.setString(_lastEveningGreetingKey, today);
        break;
    }
  }

  // Clear all greeting records
  static Future<void> clearAllGreetingRecords() async {
    await _prefs?.remove(_lastMorningGreetingKey);
    await _prefs?.remove(_lastAfternoonGreetingKey);
    await _prefs?.remove(_lastEveningGreetingKey);
  }
} 