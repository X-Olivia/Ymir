import 'package:shared_preferences/shared_preferences.dart';
import '../config/ai_characters_config.dart';
import 'openai_api_service.dart';

/// AI service manager - service management
/// 
/// Responsibilities:
/// 1. Manage AI character selection and configuration (user preferences and random mode)
/// 2. Provide a unified AI service interface that encapsulates low-level API calls
/// 3. Handling concurrent requests and result formatting
/// 4. Bridge the business and API layers
/// 
/// Not responsible for:
/// - Business workflows (handled by BackgroundCommentService and other business services)
/// - State management and stream notifications (handled by specific business services)
/// - Data persistence (handled by specific business services)
class AIServiceManager {
  static const String _selectedAIFriendsKey = 'selected_ai_friends';
  static const String _randomModeKey = 'random_mode';

  // ==================== AI character management ====================

  /// Get information about all AI characters
  static List<Map<String, dynamic>> getAllAICharacters() {
    return AICharactersConfig.getAllCharactersInfo();
  }

  /// Get the currently selected AI friends
  static Future<List<AICharacterConfig>> getSelectedAIFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final isRandomMode = prefs.getBool(_randomModeKey) ?? false;
    
    if (isRandomMode) {
      // Random mode: randomly select six AI friends
      final allCharacters = AICharactersConfig.characters;
      final shuffled = List<AICharacterConfig>.from(allCharacters)..shuffle();
      return shuffled.take(6).toList();
    } else {
      // User selection mode: Get the user’s saved selections
      final selectedIndices = prefs.getStringList(_selectedAIFriendsKey) ?? [];
      if (selectedIndices.isEmpty) {
        // If no selection is saved, return all characters to match the selection page default
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

  /// Save the selected AI friends
  static Future<void> saveSelectedAIFriends(List<int> selectedIndices) async {
    final prefs = await SharedPreferences.getInstance();
    final stringIndices = selectedIndices.map((i) => i.toString()).toList();
    await prefs.setStringList(_selectedAIFriendsKey, stringIndices);
  }

  /// Save random mode settings
  static Future<void> saveRandomMode(bool isRandomMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_randomModeKey, isRandomMode);
  }

  /// Get random mode settings
  static Future<bool> getRandomMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_randomModeKey) ?? false;
  }

  /// Find an AI character by name
  static AICharacterConfig? findAIByName(String name) {
    return AICharactersConfig.getCharacterByName(name);
  }

  // ==================== AI service interface ====================

  /// Get image comment suggestions
  /// 
  /// This is a general interface that supports:
  /// - Specify AI characters or use the user's selected characters
  /// - Send concurrent requests for multiple AI characters
  /// - Unified result formatting
  static Future<List<Map<String, dynamic>>> getImageComments({
    required List<String> imagePaths,
    String? userContext,
    String? scenario,
    List<String>? specificCharacters,
  }) async {
    try {
      // Get the AI characters to use
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

      // Request suggestions from all AI characters concurrently
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
          'content': 'An error occurred while getting AI suggestions: $e',
          'success': false,
          'error': e.toString(),
        }
      ];
    }
  }

  /// Get caption suggestions
  /// 
  /// Similar to getImageComments, but intended specifically for caption suggestions
  static Future<List<Map<String, dynamic>>> getCaptionSuggestions({
    required List<String> imagePaths,
    String? userTitle,
    String? userDescription,
    List<String>? topics,
    List<String>? specificCharacters,
  }) async {
    try {
      // Get the AI characters to use
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

      // Request suggestions from all AI characters concurrently
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
          'content': 'An error occurred while getting caption suggestions: $e',
          'success': false,
          'error': e.toString(),
        }
      ];
    }
  }

  /// Send a text message to a specific AI character
  /// 
  /// Used for text conversations with a single AI character
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
        'content': 'An error occurred while sending the message: $e',
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== System management ====================

  /// Verify the API configuration
  static Future<bool> validateApiConfiguration() async {
    return await OpenAIApiService.validateApiKey();
  }
} 