import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _selectedAIFriendsKey = 'selected_ai_friends';
  static const String _isRandomModeKey = 'ai_random_mode';
  
  // AI角色数据
  static final List<Map<String, dynamic>> _aiCharacters = [
    {
      'name': '混沌原体Y',
      'description': '生于冰火鸿沟的无名之源，一切视角的起点与终点。',
      'personality': '"我看，个个都好"',
      'avatarColor': Colors.deepPurple,
      'avatar': 'assets/images/AI/混沌原体Y.png',
    },
    {
      'name': '烧起来不顾后果',
      'description': '余烬中的第一声爆炸，情绪永远在前，后果在后。',
      'personality': '"这张表情够拽！配文：\'就喜欢你看不惯我又干不掉我的样子\'。"',
      'avatarColor': Colors.red,
      'avatar': 'assets/images/AI/烧起来不顾后果.png',
    },
    {
      'name': '零下社交圈',
      'description': '无情的拆台机器，但是善良。',
      'personality': '"第三章的滤镜遮住了黑眼圈……但确实好看，发吧。"',
      'avatarColor': Colors.cyan,
      'avatar': 'assets/images/AI/零下社交圈.png',
    },
    {
      'name': '松软贴贴球',
      'description': '柔软是一种武器，用轻触代替言语的共情体。',
      'personality': '"啊啊啊这张笑得好甜！想捏脸！配文：\'今日份可爱已加载\'。"',
      'avatarColor': Colors.pink,
      'avatar': 'assets/images/AI/松软贴贴球.png',
    },
    {
      'name': '中土',
      'description': 'Ymir的睫毛所限之地，总能发现奇怪的细节。',
      'personality': '"你背后那人的表情好搞笑，他是不是在翻白眼？"',
      'avatarColor': Colors.brown,
      'avatar': 'assets/images/AI/中土.png',
    },
    {
      'name': '左右互搏王',
      'description': '生于腋下的对话体人格，永远在自我拉扯中找到黄金中值。',
      'personality': '"M：这张光线好；W：但那张显瘦……算了，抓阄吧。"',
      'avatarColor': Colors.amber,
      'avatar': 'assets/images/AI/左右互搏王.png',
    },
    {
      'name': '阴云之脑',
      'description': 'Ymir脑中逸出的雾气，谜语人。',
      'personality': '"……有意思。"',
      'avatarColor': Colors.blueGrey,
      'avatar': 'assets/images/AI/阴云之脑.png',
    },
    {
      'name': '天空罐头',
      'description': '从巨人头骨中凿出的穹顶，喜欢大场面，背景如刀锋般锋利，人物如奶油般划开。',
      'personality': '"第五张风景很绝，发！"',
      'avatarColor': Colors.lightBlue,
      'avatar': 'assets/images/AI/天空罐头.png',
    },
    {
      'name': '山脊之骨',
      'description': '白骨成山，逻辑清晰，是冷静中的秩序派代表。',
      'personality': '"这张构图符合三分法则，点赞率预估+20%"',
      'avatarColor': Colors.grey,
      'avatar': 'assets/images/AI/山脊之骨.png',
    },
    {
      'name': '红潮之下',
      'description': '海洋般的情绪流动者，温柔且汹涌，情绪波动即美感本身。',
      'personality': '"这张夕阳的氛围绝了！配文：\'今天的心是橘子汽水做的\'。"',
      'avatarColor': Colors.redAccent,
      'avatar': 'assets/images/AI/红潮之下.png',
    },
  ];

  // 获取当前选中的AI好友列表
  static Future<List<Map<String, dynamic>>> getSelectedAIFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final isRandomMode = prefs.getBool(_isRandomModeKey) ?? false;
    
    // 无论是随机模式还是自定义模式，都使用保存的选择
    final selectedIndices = prefs.getStringList(_selectedAIFriendsKey) ?? [];
    if (selectedIndices.isEmpty) {
      // 如果没有选择，默认返回全部角色（与AI角色选择页面的默认全选保持一致）
      return _aiCharacters;
    }
    
    return selectedIndices
        .map((indexStr) => int.tryParse(indexStr))
        .where((index) => index != null && index >= 0 && index < _aiCharacters.length)
        .map((index) => _aiCharacters[index!])
        .toList();
  }

  // 保存选中的AI好友（自定义模式）
  static Future<void> saveSelectedAIFriends(Set<int> selectedIndices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedAIFriendsKey, selectedIndices.map((i) => i.toString()).toList());
  }

  // 保存是否为随机模式
  static Future<void> saveRandomMode(bool isRandomMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRandomModeKey, isRandomMode);
  }

  // 获取是否为随机模式
  static Future<bool> getRandomMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRandomModeKey) ?? false;
  }

  // 根据名称查找AI角色
  static Map<String, dynamic>? findAIByName(String name) {
    try {
      return _aiCharacters.firstWhere((ai) => ai['name'] == name);
    } catch (e) {
      return null;
    }
  }
} 