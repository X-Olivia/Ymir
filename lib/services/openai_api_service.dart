import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/ai_characters_config.dart';
import '../config/api_config.dart';

/// OpenAI-compatible API response model adapted for the Groq API
class OpenAIResponse {
  final String content;
  final bool success;
  final String? error;
  final int? tokensUsed;

  OpenAIResponse({
    required this.content,
    required this.success,
    this.error,
    this.tokensUsed,
  });

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) {
    try {
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        final content = message['content'] ?? '';
        final usage = json['usage'];
        final tokensUsed = usage?['total_tokens'];
        
        return OpenAIResponse(
          content: content,
          success: true,
          tokensUsed: tokensUsed,
        );
      } else {
        return OpenAIResponse(
          content: '',
          success: false,
          error: 'No valid response from API',
        );
      }
    } catch (e) {
      return OpenAIResponse(
        content: '',
        success: false,
        error: 'Failed to parse response: $e',
      );
    }
  }

  factory OpenAIResponse.error(String error) {
    return OpenAIResponse(
      content: '',
      success: false,
      error: error,
    );
  }
}

/// OpenAI-compatible API service adapted for the Groq API
class OpenAIApiService {
  /// Send image comment request
  static Future<OpenAIResponse> getImageComment({
    required String characterName,
    required List<String> imagePaths,
    String? userContext,
    String? scenario,
  }) async {
    try {
      final character = AICharactersConfig.getCharacterByName(characterName);
      if (character == null) {
        return OpenAIResponse.error('The specified AI role was not found: $characterName');
      }

      // Build the prompt
      String prompt = character.imageCommentPrompt;
      
      // Add user context
      if (userContext != null && userContext.isNotEmpty) {
        prompt += '\n\nAdditional user context: $userContext';
      }
      
      // Add scene information
      if (scenario != null && scenario.isNotEmpty) {
        prompt += '\n\nUse case: $scenario';
      }
      
      // Add image quantity information
      if (imagePaths.length > 1) {
        prompt += '\n\nThe user uploaded ${imagePaths.length} images. Help select the most suitable one or offer suggestions.';
      }

      // Build message content
      List<Map<String, dynamic>> content = [
        {
          'type': 'text',
          'text': prompt,
        },
      ];

      // Add images
      for (String imagePath in imagePaths) {
        content.add({
          'type': 'image_url',
          'image_url': {
            'url': _encodeImageToBase64(imagePath),
            'detail': 'high', // Maintain high quality settings
          },
        });
      }

      final messages = [
        {
          'role': 'user',
          'content': content,
        },
      ];

      return await _sendRequest(
        messages: messages,
        temperature: character.temperature,
        maxTokens: character.maxTokens,
        hasImages: true, // Mark the request as containing images
      );
    } catch (e) {
      return OpenAIResponse.error('Failed to send image comment request: $e');
    }
  }

  /// Send a request for caption suggestions
  static Future<OpenAIResponse> getCaptionSuggestion({
    required String characterName,
    required List<String> imagePaths,
    String? userTitle,
    String? userDescription,
    List<String>? topics,
  }) async {
    try {
      final character = AICharactersConfig.getCharacterByName(characterName);
      if (character == null) {
        return OpenAIResponse.error('The specified AI role was not found: $characterName');
      }

      // Build the prompt
      String prompt = character.captionSuggestPrompt;
      
      // Add user-entered information
      if (userTitle != null && userTitle.isNotEmpty) {
        prompt += '\n\nUser title: $userTitle';
      }
      
      if (userDescription != null && userDescription.isNotEmpty) {
        prompt += '\n\nUser description: $userDescription';
      }
      
      if (topics != null && topics.isNotEmpty) {
        prompt += '\n\nRelated topics: ${topics.join(', ')}';
      }

      // Build message content
      List<Map<String, dynamic>> content = [
        {
          'type': 'text',
          'text': prompt,
        },
      ];

      // Add images
      for (String imagePath in imagePaths) {
        content.add({
          'type': 'image_url',
          'image_url': {
            'url': _encodeImageToBase64(imagePath),
            'detail': 'high',
          },
        });
      }

      final messages = [
        {
          'role': 'user',
          'content': content,
        },
      ];

      return await _sendRequest(
        messages: messages,
        temperature: character.temperature,
        maxTokens: character.maxTokens,
        hasImages: true, // Mark the request as containing images
      );
    } catch (e) {
      return OpenAIResponse.error('Failed to send caption suggestion request: $e');
    }
  }

  /// Send a generic text request (without images)
  static Future<OpenAIResponse> sendTextRequest({
    required String characterName,
    required String prompt,
    double? temperature,
    int? maxTokens,
    bool isCommentGeneration = false, // Whether this request generates a comment
    bool useRawPrompt = false, // Whether to use the raw prompt without adding a character prompt
  }) async {
    try {
      final character = AICharactersConfig.getCharacterByName(characterName);
      if (character == null) {
        return OpenAIResponse.error('The specified AI role was not found: $characterName');
      }

      String fullPrompt;
      if (useRawPrompt) {
        // Use original prompt, do not add a role prompt
        fullPrompt = prompt;
      } else {
        // Choose the appropriate character prompt for the request
        String characterPrompt;
        if (isCommentGeneration) {
          characterPrompt = character.imageCommentPrompt;
        } else {
          characterPrompt = character.basePersonality;
        }
        // Build the complete prompt
        fullPrompt = '$characterPrompt\n\n$prompt';
      }
      
      final messages = [
        {
          'role': 'user',
          'content': fullPrompt,
        },
      ];

      return await _sendRequest(
        messages: messages,
        temperature: temperature ?? character.temperature,
        maxTokens: maxTokens ?? character.maxTokens,
        hasImages: false, // Mark the request as containing no images
      );
    } catch (e) {
      return OpenAIResponse.error('Failed to send text request: $e');
    }
  }

  /// Send an HTTP request to the API
  static Future<OpenAIResponse> _sendRequest({
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
    bool hasImages = false,
  }) async {
    try {
      if (!ApiConfig.isApiKeyConfigured) {
        return OpenAIResponse.error('The API key is not configured. Set a valid key in ApiConfig.');
      }

      // Choose the appropriate model based on whether it contains images or not
      String modelToUse;
      if (hasImages) {
        // Use visual models
        modelToUse = ApiConfig.defaultVisionModel;
        // Check if the model supports vision
        if (!ApiConfig.isVisionModelSupported(modelToUse)) {
          return OpenAIResponse.error('The currently configured visual model does not support image analysis: $modelToUse');
        }
      } else {
        // Use text model
        modelToUse = ApiConfig.defaultModel;
      }

      final requestBody = {
        'model': modelToUse,
        'messages': messages,
        'temperature': temperature ?? ApiConfig.defaultTemperature,
        'max_tokens': maxTokens ?? (hasImages ? ApiConfig.visionMaxTokens : ApiConfig.defaultMaxTokens),
      };

      print('🚀 Sending API request - model: $modelToUse, contains images: $hasImages');

      final response = await http.post(
        Uri.parse(ApiConfig.apiUrl),
        headers: ApiConfig.headers,
        body: json.encode(requestBody),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final result = OpenAIResponse.fromJson(responseData);
        print('✅ API request succeeded - token usage: ${result.tokensUsed}');
        return result;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        print('❌ API request failed (${response.statusCode}): $errorMessage');
        return OpenAIResponse.error('API request failed (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ API request error: $e');
      if (e.toString().contains('TimeoutException')) {
        return OpenAIResponse.error('Request timed out, please check network connection');
      } else {
        return OpenAIResponse.error('Network request failed: $e');
      }
    }
  }

  /// Encode a local image in base64 format
  static String _encodeImageToBase64(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('Image file does not exist: $imagePath');
      }
      
      final bytes = file.readAsBytesSync();
      
      // Check file size
      if (bytes.length > ApiConfig.maxImageSize) {
        throw Exception('The image file is too large. The maximum supported size is ${ApiConfig.maxImageSize ~/ (1024 * 1024)} MB.');
      }
      
      final base64String = base64Encode(bytes);
      
      // Determine the MIME type from the file extension
      String mimeType = 'image/jpeg';
      final extension = imagePath.toLowerCase().split('.').last;
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }
      
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      throw Exception('Image encoding failed: $e');
    }
  }

  /// Verify that the API key is valid
  static Future<bool> validateApiKey() async {
    try {
      final response = await sendTextRequest(
        characterName: 'Chaos Primarch Y',
        prompt: 'Please reply with "Test successful".',
        maxTokens: 10,
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Get API usage statistics
  static Future<Map<String, dynamic>?> getUsageStats() async {
    // The Groq API does not expose usage statistics directly.
    // Consider recording API call counts and token usage locally.
    return null;
  }
} 