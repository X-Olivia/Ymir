import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class UserService {
  static const String _nicknameKey = 'user_nickname';
  static const String _avatarPlaceholderKey = 'user_avatar_placeholder';
  static const String _avatarColorKey = 'user_avatar_color';
  static const String _avatarPathKey = 'user_avatar_path';
  static const String _ymirIdKey = 'ymir_id';
  static const String _genderKey = 'user_gender';

  // Default user information
  static const String _defaultNickname = 'User nickname';
  static const String _defaultAvatarPlaceholder = 'U';
  static const Color _defaultAvatarColor = Colors.blue;
  static const String _defaultGender = 'none';

  // Generate a random Ymir ID
  static String _generateYmirId() {
    final random = Random();
    String id = '';
    for (int i = 0; i < 10; i++) {
      id += random.nextInt(10).toString();
    }
    return id;
  }

  // Get or generate the Ymir ID
  static Future<String> getYmirId() async {
    final prefs = await SharedPreferences.getInstance();
    String? ymirId = prefs.getString(_ymirIdKey);
    
    if (ymirId == null) {
      ymirId = _generateYmirId();
      await prefs.setString(_ymirIdKey, ymirId);
    }
    
    return ymirId;
  }

  // Save user nickname
  static Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, nickname);
  }

  // Get user nickname
  static Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey) ?? _defaultNickname;
  }

  // Save avatar placeholder
  static Future<void> saveAvatarPlaceholder(String placeholder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPlaceholderKey, placeholder);
  }

  // Get avatar placeholder
  static Future<String> getAvatarPlaceholder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarPlaceholderKey) ?? _defaultAvatarPlaceholder;
  }

  // Save avatar color
  static Future<void> saveAvatarColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarColorKey, color.value);
  }

  // Get avatar color
  static Future<Color> getAvatarColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_avatarColorKey);
    if (colorValue != null) {
      return Color(colorValue);
    }
    return _defaultAvatarColor;
  }

  // Save avatar path
  static Future<void> saveAvatarPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_avatarPathKey, path);
    } else {
      await prefs.remove(_avatarPathKey);
    }
  }

  // Get avatar path
  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarPathKey);
  }

  // Save gender settings
  static Future<void> saveGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender);
  }

  // Get gender settings
  static Future<String> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey) ?? _defaultGender;
  }

  // Get complete user information
  static Future<Map<String, dynamic>> getUserInfo() async {
    final nickname = await getNickname();
    final avatarPlaceholder = await getAvatarPlaceholder();
    final avatarColor = await getAvatarColor();
    final avatarPath = await getAvatarPath();
    final ymirId = await getYmirId();
    final gender = await getGender();

    return {
      'nickname': nickname,
      'avatarPlaceholder': avatarPlaceholder,
      'avatarColor': avatarColor,
      'avatarPath': avatarPath,
      'ymirId': ymirId,
      'gender': gender,
    };
  }

  // Save complete user information
  static Future<void> saveUserInfo({
    required String nickname,
    required String avatarPlaceholder,
    required Color avatarColor,
    String? avatarPath,
    String? gender,
  }) async {
    final futures = [
      saveNickname(nickname),
      saveAvatarPlaceholder(avatarPlaceholder),
      saveAvatarColor(avatarColor),
      saveAvatarPath(avatarPath),
    ];
    
    if (gender != null) {
      futures.add(saveGender(gender));
    }
    
    await Future.wait(futures);
  }
} 