import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/openai_api_service.dart';
import '../services/ai_service_manager.dart';

/// API testing utility
class ApiTest {
  /// Test basic text requests
  static Future<void> testTextRequest() async {
    print('🧪 Starting text request test...');
    
    try {
      final response = await OpenAIApiService.sendTextRequest(
        characterName: 'Chaos Primordial Y',
        prompt: 'Please reply with "Test successful."',
        maxTokens: 20,
      );
      
      if (response.success) {
        print('✅ Text request test succeeded!');
        print('📝 Response: ${response.content}');
        print('🔢 Tokens used: ${response.tokensUsed}');
      } else {
        print('❌ Text request test failed: ${response.error}');
      }
    } catch (e) {
      print('❌ Text request test threw an exception: $e');
    }
    
    print('');
  }

  /// Tests image request support
  static Future<void> testImageSupport() async {
    print('🖼️ Starting image request support test...');
    
    try {
      // Creates a simple Base64-encoded test image
      final testImageBase64 = _createTestImageBase64();
      
      final requestBody = {
        'model': ApiConfig.defaultModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Please describe this image. If you can see it, reply "I can see the image"; otherwise, reply "I cannot see the image."',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': testImageBase64,
                  'detail': 'low',
                },
              },
            ],
          },
        ],
        'max_tokens': 50,
        'temperature': 0.1,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.apiUrl),
        headers: ApiConfig.headers,
        body: json.encode(requestBody),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final choices = responseData['choices'] as List?;
        
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'] ?? '';
          final usage = responseData['usage'];
          
          print('✅ Image request test succeeded!');
          print('📝 Response: $content');
          print('🔢 Tokens used: ${usage?['total_tokens']}');
          
          // Determines whether image requests are supported
          if (content.contains('I can see the image') || content.toLowerCase().contains('image') || content.toLowerCase().contains('picture')) {
            print('🎉 The API supports image requests!');
          } else {
            print('⚠️ The API may not support image requests, or the image format may be invalid');
          }
        } else {
          print('❌ Image request test failed: no valid response');
        }
      } else {
        final errorData = json.decode(response.body);
        print('❌ Image request test failed (${response.statusCode}): ${errorData['error']?['message']}');
        
        // Checks whether the error indicates that images are unsupported
        final errorMessage = errorData['error']?['message']?.toString().toLowerCase() ?? '';
        if (errorMessage.contains('image') || errorMessage.contains('vision') || errorMessage.contains('multimodal')) {
          print('💡 Tip: This API may not support images; consider using text-only mode');
        }
      }
    } catch (e) {
      print('❌ Image request test threw an exception: $e');
    }
    
    print('');
  }

  /// Tests the AI service manager
  static Future<void> testAIServiceManager() async {
    print('🤖 Starting AI service manager test...');
    
    try {
      // Tests retrieving AI character information
      final characters = AIServiceManager.getAllAICharacters();
      print('✅ Retrieved ${characters.length} AI characters');
      
      // Tests sending a text message
      final textResult = await AIServiceManager.sendTextMessage(
        characterName: 'Chaos Primordial Y',
        message: 'Hello, please briefly introduce yourself.',
      );
      
      if (textResult['success'] == true) {
        print('✅ AI character conversation test succeeded!');
        print('📝 ${textResult['characterName']}: ${textResult['content']}');
      } else {
        print('❌ AI character conversation test failed: ${textResult['error']}');
      }
      
    } catch (e) {
      print('❌ AI service manager test threw an exception: $e');
    }
    
    print('');
  }

  /// Runs all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting API functionality tests...\n');
    
    // Checks the API configuration
    if (!ApiConfig.isApiKeyConfigured) {
      print('❌ API key is not configured!');
      return;
    }
    
    print('🔑 API key is configured');
    print('🌐 API URL: ${ApiConfig.apiUrl}');
    print('🤖 Model: ${ApiConfig.defaultModel}\n');
    
    // Runs the tests
    await testTextRequest();
    await testImageSupport();
    await testAIServiceManager();
    
    print('🏁 Tests complete!');
  }

  /// Creates a simple Base64-encoded test image (a 1x1 red PNG)
  static String _createTestImageBase64() {
    // Base64 encoding of a 1x1 red PNG image
    const pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
    return 'data:image/png;base64,$pngBase64';
  }

  /// Tests a specific image file (if it exists)
  static Future<void> testWithImageFile(String imagePath) async {
    print('🖼️ Testing image file: $imagePath');
    
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        print('❌ Image file does not exist: $imagePath');
        return;
      }
      
      final response = await OpenAIApiService.getImageComment(
        characterName: 'Chaos Primordial Y',
        imagePaths: [imagePath],
        userContext: 'This is a test image.',
        scenario: 'Test scenario',
      );
      
      if (response.success) {
        print('✅ Image file test succeeded!');
        print('📝 AI comment: ${response.content}');
        print('🔢 Tokens used: ${response.tokensUsed}');
      } else {
        print('❌ Image file test failed: ${response.error}');
      }
    } catch (e) {
      print('❌ Image file test threw an exception: $e');
    }
  }
} 