import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _selectedAIFriendsKey = 'selected_ai_friends';
  static const String _isRandomModeKey = 'ai_random_mode';
  
  // AI character data
  static final List<Map<String, dynamic>> _aiCharacters = [
    {
      'name': 'Chaos Primarch Y',
      'description': 'The nameless source born from the chasm of ice and fire, the beginning and end of all perspectives.',
      'personality': '"They all look good to me."',
      'avatarColor': Colors.deepPurple,
      'avatar': 'assets/images/AI/Chaos Primarch Y.png',
    },
    {
      'name': 'Burn Without Consequences',
      'description': 'The first explosion in the embers—emotion always comes first, consequences later.',
      'personality': '"This expression is fierce! Caption: \'I love how you can’t stand me but can’t do anything about it.\'"',
      'avatarColor': Colors.red,
      'avatar': 'assets/images/AI/Burn Without Consequences.png',
    },
    {
      'name': 'Subzero Social Circle',
      'description': 'A merciless critic with a kind heart.',
      'personality': '"The filter on the third one hides the dark circles... but it really does look good. Post it."',
      'avatarColor': Colors.cyan,
      'avatar': 'assets/images/AI/Subzero Social Circle.png',
    },
    {
      'name': 'Soft Cuddle Ball',
      'description': 'Softness is a weapon—an empathic being that communicates through gentle touch instead of words.',
      'personality': '"Ahhh, that smile is so sweet! I want to pinch those cheeks! Caption: \'Today’s dose of cuteness: loaded.\'"',
      'avatarColor': Colors.pink,
      'avatar': 'assets/images/AI/Soft Cuddle Ball.png',
    },
    {
      'name': 'Middle-earth',
      'description': 'The realm bounded by Ymir’s eyelashes, always noticing the oddest details.',
      'personality': '"The expression on the person behind you is hilarious. Are they rolling their eyes?"',
      'avatarColor': Colors.brown,
      'avatar': 'assets/images/AI/Middle-earth.png',
    },
    {
      'name': 'King of Inner Conflict',
      'description': 'A conversational persona born beneath the arm, forever finding the golden mean through inner conflict.',
      'personality': '"M: This one has better lighting. W: But that one is more flattering... Forget it, let’s draw lots."',
      'avatarColor': Colors.amber,
      'avatar': 'assets/images/AI/King of Inner Conflict.png',
    },
    {
      'name': 'Clouded Mind',
      'description': 'A wisp of fog escaped from Ymir’s mind—an enigmatic riddler.',
      'personality': '"...Interesting."',
      'avatarColor': Colors.blueGrey,
      'avatar': 'assets/images/AI/Clouded Mind.png',
    },
    {
      'name': 'Canned Sky',
      'description': 'A dome hewn from a giant’s skull, it loves big scenes, with backgrounds as sharp as a razor’s edge and characters cut like butter.',
      'personality': '"The scenery in the fifth image is stunning. Post it!"',
      'avatarColor': Colors.lightBlue,
      'avatar': 'assets/images/AI/Canned Sky.png',
    },
    {
      'name': 'Ridgebone',
      'description': 'Bones piled into mountains; clear-minded and logical, an embodiment of order and composure.',
      'personality': '"This composition follows the rule of thirds. Estimated engagement: +20%."',
      'avatarColor': Colors.grey,
      'avatar': 'assets/images/AI/Ridgebone.png',
    },
    {
      'name': 'Beneath the Red Tide',
      'description': 'An oceanic current of emotion, gentle yet surging, finding beauty in every emotional wave.',
      'personality': '"This sunset feels incredible! Caption: \'My heart is made of orange soda today.\'"',
      'avatarColor': Colors.redAccent,
      'avatar': 'assets/images/AI/Beneath the Red Tide.png',
    },
  ];

  // Get the currently selected AI friends
  static Future<List<Map<String, dynamic>>> getSelectedAIFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final isRandomMode = prefs.getBool(_isRandomModeKey) ?? false;
    
    // Whether in random or custom mode, the saved selections are used
    final selectedIndices = prefs.getStringList(_selectedAIFriendsKey) ?? [];
    if (selectedIndices.isEmpty) {
      // If no selection is saved, return all characters by default (matching the character selection page)
      return _aiCharacters;
    }
    
    return selectedIndices
        .map((indexStr) => int.tryParse(indexStr))
        .where((index) => index != null && index >= 0 && index < _aiCharacters.length)
        .map((index) => _aiCharacters[index!])
        .toList();
  }

  // Save selected AI friends (custom mode)
  static Future<void> saveSelectedAIFriends(Set<int> selectedIndices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedAIFriendsKey, selectedIndices.map((i) => i.toString()).toList());
  }

  // Save whether random mode is enabled
  static Future<void> saveRandomMode(bool isRandomMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRandomModeKey, isRandomMode);
  }

  // Get whether random mode is enabled
  static Future<bool> getRandomMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRandomModeKey) ?? false;
  }

  // Find an AI character by name
  static Map<String, dynamic>? findAIByName(String name) {
    try {
      return _aiCharacters.firstWhere((ai) => ai['name'] == name);
    } catch (e) {
      return null;
    }
  }
} 