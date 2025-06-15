import 'package:shared_preferences/shared_preferences.dart';
import '../config/ai_characters_config.dart';
import 'openai_api_service.dart';

/// AI服务管理器 - 服务管理层
/// 
/// 职责：
/// 1. 管理AI角色选择和配置（用户偏好、随机模式）
/// 2. 提供统一的AI服务接口，封装底层API调用
/// 3. 处理并发请求和结果格式化
/// 4. 作为业务层和API层之间的桥梁
/// 
/// 不负责：
/// - 业务流程管理（由BackgroundCommentService等业务服务负责）
/// - 状态管理和Stream通知（由具体业务服务负责）
/// - 数据持久化（由具体业务服务负责）
class AIServiceManager {
  static const String _selectedAIFriendsKey = 'selected_ai_friends';
  static const String _randomModeKey = 'random_mode';

  // ==================== AI角色管理 ====================

  /// 获取所有AI角色信息
  static List<Map<String, dynamic>> getAllAICharacters() {
    return AICharactersConfig.getAllCharactersInfo();
  }

  /// 获取当前选中的AI朋友
  static Future<List<AICharacterConfig>> getSelectedAIFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final isRandomMode = prefs.getBool(_randomModeKey) ?? false;
    
    if (isRandomMode) {
      // 随机模式：随机选择6个AI朋友
      final allCharacters = AICharactersConfig.characters;
      final shuffled = List<AICharacterConfig>.from(allCharacters)..shuffle();
      return shuffled.take(6).toList();
    } else {
      // 用户选择模式：获取用户保存的选择
      final selectedIndices = prefs.getStringList(_selectedAIFriendsKey) ?? [];
      if (selectedIndices.isEmpty) {
        // 如果没有保存的选择，返回全部角色（与AI角色选择页面的默认全选保持一致）
        return AICharactersConfig.characters;
      }
      
      final selectedCharacters = <AICharacterConfig>[];
      for (String indexStr in selectedIndices) {
        final index = int.tryParse(indexStr);
        if (index != null && index < AICharactersConfig.characters.length) {
          selectedCharacters.add(AICharactersConfig.characters[index]);
        }
      }
      return selectedCharacters;
    }
  }

  /// 保存选中的AI朋友
  static Future<void> saveSelectedAIFriends(List<int> selectedIndices) async {
    final prefs = await SharedPreferences.getInstance();
    final stringIndices = selectedIndices.map((i) => i.toString()).toList();
    await prefs.setStringList(_selectedAIFriendsKey, stringIndices);
  }

  /// 保存随机模式设置
  static Future<void> saveRandomMode(bool isRandomMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_randomModeKey, isRandomMode);
  }

  /// 获取随机模式设置
  static Future<bool> getRandomMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_randomModeKey) ?? false;
  }

  /// 根据名称查找AI角色
  static AICharacterConfig? findAIByName(String name) {
    return AICharactersConfig.getCharacterByName(name);
  }

  // ==================== AI服务接口 ====================

  /// 获取图片评论建议
  /// 
  /// 这是一个通用接口，支持：
  /// - 指定特定AI角色或使用用户选择的AI角色
  /// - 并发请求多个AI角色
  /// - 统一的结果格式化
  static Future<List<Map<String, dynamic>>> getImageComments({
    required List<String> imagePaths,
    String? userContext,
    String? scenario,
    List<String>? specificCharacters,
  }) async {
    try {
      // 获取要使用的AI角色
      List<AICharacterConfig> characters;
      if (specificCharacters != null && specificCharacters.isNotEmpty) {
        characters = specificCharacters
            .map((name) => AICharactersConfig.getCharacterByName(name))
            .where((char) => char != null)
            .cast<AICharacterConfig>()
            .toList();
      } else {
        characters = await getSelectedAIFriends();
      }

      // 并发请求所有AI角色的建议
      final futures = characters.map((character) async {
        final response = await OpenAIApiService.getImageComment(
          characterName: character.name,
          imagePaths: imagePaths,
          userContext: userContext,
          scenario: scenario,
        );

        return {
          'characterName': character.name,
          'characterAvatar': character.avatar,
          'characterColor': character.avatarColor,
          'content': response.content,
          'success': response.success,
          'error': response.error,
          'tokensUsed': response.tokensUsed,
        };
      }).toList();

      final results = await Future.wait(futures);
      return results;
    } catch (e) {
      return [
        {
          'characterName': 'Error',
          'content': '获取AI建议时发生错误: $e',
          'success': false,
          'error': e.toString(),
        }
      ];
    }
  }

  /// 获取配文建议
  /// 
  /// 类似getImageComments，但专门用于配文场景
  static Future<List<Map<String, dynamic>>> getCaptionSuggestions({
    required List<String> imagePaths,
    String? userTitle,
    String? userDescription,
    List<String>? topics,
    List<String>? specificCharacters,
  }) async {
    try {
      // 获取要使用的AI角色
      List<AICharacterConfig> characters;
      if (specificCharacters != null && specificCharacters.isNotEmpty) {
        characters = specificCharacters
            .map((name) => AICharactersConfig.getCharacterByName(name))
            .where((char) => char != null)
            .cast<AICharacterConfig>()
            .toList();
      } else {
        characters = await getSelectedAIFriends();
      }

      // 并发请求所有AI角色的建议
      final futures = characters.map((character) async {
        final response = await OpenAIApiService.getCaptionSuggestion(
          characterName: character.name,
          imagePaths: imagePaths,
          userTitle: userTitle,
          userDescription: userDescription,
          topics: topics,
        );

        return {
          'characterName': character.name,
          'characterAvatar': character.avatar,
          'characterColor': character.avatarColor,
          'content': response.content,
          'success': response.success,
          'error': response.error,
          'tokensUsed': response.tokensUsed,
        };
      }).toList();

      final results = await Future.wait(futures);
      return results;
    } catch (e) {
      return [
        {
          'characterName': 'Error',
          'content': '获取配文建议时发生错误: $e',
          'success': false,
          'error': e.toString(),
        }
      ];
    }
  }

  /// 发送文本消息给特定AI角色
  /// 
  /// 用于单个AI角色的文本对话
  static Future<Map<String, dynamic>> sendTextMessage({
    required String characterName,
    required String message,
    bool isCommentGeneration = false,
  }) async {
    try {
      final response = await OpenAIApiService.sendTextRequest(
        characterName: characterName,
        prompt: message,
        isCommentGeneration: isCommentGeneration,
      );

      final character = AICharactersConfig.getCharacterByName(characterName);
      
      return {
        'characterName': characterName,
        'characterAvatar': character?.avatar,
        'characterColor': character?.avatarColor,
        'content': response.content,
        'success': response.success,
        'error': response.error,
        'tokensUsed': response.tokensUsed,
      };
    } catch (e) {
      return {
        'characterName': characterName,
        'content': '发送消息时发生错误: $e',
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== 系统管理 ====================

  /// 验证API配置
  static Future<bool> validateApiConfiguration() async {
    return await OpenAIApiService.validateApiKey();
  }
} 