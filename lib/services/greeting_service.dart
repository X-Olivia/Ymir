import 'package:shared_preferences/shared_preferences.dart';

class GreetingService {
  static const String _greetingEnabledKey = 'greeting_enabled';
  static const String _lastMorningGreetingKey = 'last_morning_greeting';
  static const String _lastAfternoonGreetingKey = 'last_afternoon_greeting';
  static const String _lastEveningGreetingKey = 'last_evening_greeting';
  static SharedPreferences? _prefs;
  
  // 初始化服务
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // 检查问候功能是否启用
  static bool isGreetingEnabled() {
    return _prefs?.getBool(_greetingEnabledKey) ?? true;
  }
  
  // 设置问候功能启用状态
  static Future<void> setGreetingEnabled(bool enabled) async {
    await _prefs?.setBool(_greetingEnabledKey, enabled);
  }

  // 获取当前时段
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

  // 获取问候语
  static String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '早安';
    } else if (hour >= 12 && hour < 18) {
      return '午安';
    } else {
      return '晚安';
    }
  }
  
  // 检查当前时段是否应该显示问候
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
  
  // 标记当前时段的问候已显示
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

  // 清除所有问候记录
  static Future<void> clearAllGreetingRecords() async {
    await _prefs?.remove(_lastMorningGreetingKey);
    await _prefs?.remove(_lastAfternoonGreetingKey);
    await _prefs?.remove(_lastEveningGreetingKey);
  }
} 