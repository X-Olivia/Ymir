import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroqResponse {
  final String? content;
  final bool success;
  final String? error;

  GroqResponse({
    this.content,
    required this.success,
    this.error,
  });

  factory GroqResponse.fromJson(Map<String, dynamic> json) {
    try {
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        final content = message['content'] as String?;
        return GroqResponse(
          content: content,
          success: true,
        );
      } else {
        return GroqResponse(
          success: false,
          error: 'Response format error: No valid content found',
        );
      }
    } catch (e) {
      return GroqResponse(
        success: false,
        error: 'Failed to parse response: $e',
      );
    }
  }

  factory GroqResponse.error(String error) {
    return GroqResponse(
      success: false,
      error: error,
    );
  }
}

class GroqApiService {
  
  static Future<GroqResponse> getImageComment({
    required List<String> imagePaths,
    required String characterName,
    String? customPrompt,
  }) async {
    try {
      final character = ApiConfig.characters.firstWhere(
        (char) => char['name'] == characterName,
        orElse: () => {},
      );
      
      if (character.isEmpty) {
        return GroqResponse.error('The specified AI role was not found: $characterName');
      }

      // Build the prompt
      String prompt = character['imageCommentPrompt'] ?? '';
      
      // Add user context
      if (customPrompt != null && customPrompt.isNotEmpty) {
        prompt += '\n\nAdditional user context: $customPrompt';
      }
      
      // Add image quantity information
      if (imagePaths.length > 1) {
        prompt += '\n\nThe user uploaded ${imagePaths.length} images. Generate a detailed description of them.';
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
        temperature: character['temperature'] ?? ApiConfig.defaultTemperature,
        maxTokens: character['maxTokens'] ?? ApiConfig.defaultMaxTokens,
        hasImages: true,
      );
    } catch (e) {
      return GroqResponse.error('Failed to send image comment request: $e');
    }
  }

  static Future<GroqResponse> getCaptionSuggestion({
    required List<String> imagePaths,
    required String characterName,
    String? customPrompt,
  }) async {
    try {
      final character = ApiConfig.characters.firstWhere(
        (char) => char['name'] == characterName,
        orElse: () => {},
      );
      
      if (character.isEmpty) {
        return GroqResponse.error('The specified AI role was not found: $characterName');
      }

      // Build the prompt
      String prompt = character['captionSuggestPrompt'] ?? '';
      
      // Add user-entered information
      if (customPrompt != null && customPrompt.isNotEmpty) {
        prompt += '\n\nUser title: $customPrompt';
      }
      
      if (customPrompt != null && customPrompt.isNotEmpty) {
        prompt += '\n\nUser description: $customPrompt';
      }
      
      // Add image quantity information
      if (imagePaths.length > 1) {
        prompt += '\n\nThe user uploaded ${imagePaths.length} images. Generate a detailed description of them.';
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
        temperature: character['temperature'] ?? ApiConfig.defaultTemperature,
        maxTokens: character['maxTokens'] ?? ApiConfig.defaultMaxTokens,
        hasImages: true,
      );
    } catch (e) {
      return GroqResponse.error('Failed to send caption suggestion request: $e');
    }
  }

  static Future<GroqResponse> sendTextRequest({
    required String message,
    required String characterName,
  }) async {
    try {
      final character = ApiConfig.characters.firstWhere(
        (char) => char['name'] == characterName,
        orElse: () => {},
      );
      
      if (character.isEmpty) {
        return GroqResponse.error('The specified AI role was not found: $characterName');
      }

      // Build the complete prompt
      final fullPrompt = '${character['basePersonality']}\n\n$message';

      final messages = [
        {
          'role': 'user',
          'content': fullPrompt,
        },
      ];

      return await _sendRequest(
        messages: messages,
        temperature: character['temperature'] ?? ApiConfig.defaultTemperature,
        maxTokens: character['maxTokens'] ?? ApiConfig.defaultMaxTokens,
      );
    } catch (e) {
      return GroqResponse.error('Failed to send text request: $e');
    }
  }

  static Future<GroqResponse> _sendRequest({
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
    bool hasImages = false,
  }) async {
    http.Response? response;
    try {
      if (!ApiConfig.isApiKeyConfigured) {
        return GroqResponse.error('The API key is not configured. Set a valid Groq API key in ApiConfig.');
      }

      // Choose the appropriate model based on whether it contains images or not
      String modelToUse = hasImages ? ApiConfig.defaultVisionModel : ApiConfig.defaultModel;

      final requestBody = {
        'model': modelToUse,
        'messages': messages,
        'temperature': temperature ?? ApiConfig.defaultTemperature,
        'max_tokens': maxTokens ?? (hasImages ? ApiConfig.visionMaxTokens : ApiConfig.defaultMaxTokens),
      };

      response = await http.post(
        Uri.parse(ApiConfig.apiUrl),
        headers: ApiConfig.headers,
        body: json.encode(requestBody),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return GroqResponse.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        return GroqResponse.error('API request failed (${response.statusCode}): $errorMessage');
      }
    } on SocketException {
      return GroqResponse.error('Network connection failed, please check network settings');
    } on HttpException {
      final statusCode = response?.statusCode ?? 0;
      return GroqResponse.error('HTTP request failed ($statusCode)');
    } on FormatException {
      return GroqResponse.error('Response data format error');
    } on TimeoutException {
      return GroqResponse.error('Request timed out, please check network connection');
    } catch (e) {
      return GroqResponse.error('Network request failed: $e');
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
        message: 'Please reply with "Test successful".',
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Get API usage statistics (not provided directly by Groq)
  static Future<Map<String, dynamic>?> getUsageStats() async {
    // The Groq API does not expose usage statistics directly.
    // Consider recording API call counts and token usage locally.
    return null;
  }
} 