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

  // 默认用户信息
  static const String _defaultNickname = '用户昵称';
  static const String _defaultAvatarPlaceholder = 'U';
  static const Color _defaultAvatarColor = Colors.blue;
  static const String _defaultGender = 'none';

  // 生成随机Ymir号
  static String _generateYmirId() {
    final random = Random();
    String id = '';
    for (int i = 0; i < 10; i++) {
      id += random.nextInt(10).toString();
    }
    return id;
  }

  // 获取或生成Ymir号
  static Future<String> getYmirId() async {
    final prefs = await SharedPreferences.getInstance();
    String? ymirId = prefs.getString(_ymirIdKey);
    
    if (ymirId == null) {
      ymirId = _generateYmirId();
      await prefs.setString(_ymirIdKey, ymirId);
    }
    
    return ymirId;
  }

  // 保存用户昵称
  static Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, nickname);
  }

  // 获取用户昵称
  static Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey) ?? _defaultNickname;
  }

  // 保存头像占位符
  static Future<void> saveAvatarPlaceholder(String placeholder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPlaceholderKey, placeholder);
  }

  // 获取头像占位符
  static Future<String> getAvatarPlaceholder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarPlaceholderKey) ?? _defaultAvatarPlaceholder;
  }

  // 保存头像颜色
  static Future<void> saveAvatarColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarColorKey, color.value);
  }

  // 获取头像颜色
  static Future<Color> getAvatarColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_avatarColorKey);
    if (colorValue != null) {
      return Color(colorValue);
    }
    return _defaultAvatarColor;
  }

  // 保存头像路径
  static Future<void> saveAvatarPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_avatarPathKey, path);
    } else {
      await prefs.remove(_avatarPathKey);
    }
  }

  // 获取头像路径
  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarPathKey);
  }

  // 保存性别设置
  static Future<void> saveGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender);
  }

  // 获取性别设置
  static Future<String> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey) ?? _defaultGender;
  }

  // 获取完整用户信息
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

  // 保存完整用户信息
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