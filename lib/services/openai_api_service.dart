import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/ai_characters_config.dart';
import '../config/api_config.dart';

/// OpenAI兼容API响应模型（适配Groq API）
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

/// OpenAI兼容API服务类（适配Groq API）
class OpenAIApiService {
  /// 发送图片评论请求
  static Future<OpenAIResponse> getImageComment({
    required String characterName,
    required List<String> imagePaths,
    String? userContext,
    String? scenario,
  }) async {
    try {
      final character = AICharactersConfig.getCharacterByName(characterName);
      if (character == null) {
        return OpenAIResponse.error('未找到指定的AI角色: $characterName');
      }

      // 构建prompt
      String prompt = character.imageCommentPrompt;
      
      // 添加用户上下文
      if (userContext != null && userContext.isNotEmpty) {
        prompt += '\n\n用户补充信息: $userContext';
      }
      
      // 添加场景信息
      if (scenario != null && scenario.isNotEmpty) {
        prompt += '\n\n使用场景: $scenario';
      }
      
      // 添加图片数量信息
      if (imagePaths.length > 1) {
        prompt += '\n\n用户上传了${imagePaths.length}张图片，请帮助选择最适合的图片或给出建议。';
      }

      // 构建消息内容
      List<Map<String, dynamic>> content = [
        {
          'type': 'text',
          'text': prompt,
        },
      ];

      // 添加图片
      for (String imagePath in imagePaths) {
        content.add({
          'type': 'image_url',
          'image_url': {
            'url': _encodeImageToBase64(imagePath),
            'detail': 'high', // 保持高质量设置
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
        hasImages: true, // 标记包含图片
      );
    } catch (e) {
      return OpenAIResponse.error('发送图片评论请求失败: $e');
    }
  }

  /// 发送配文建议请求
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
        return OpenAIResponse.error('未找到指定的AI角色: $characterName');
      }

      // 构建prompt
      String prompt = character.captionSuggestPrompt;
      
      // 添加用户输入的信息
      if (userTitle != null && userTitle.isNotEmpty) {
        prompt += '\n\n用户标题: $userTitle';
      }
      
      if (userDescription != null && userDescription.isNotEmpty) {
        prompt += '\n\n用户描述: $userDescription';
      }
      
      if (topics != null && topics.isNotEmpty) {
        prompt += '\n\n相关话题: ${topics.join(', ')}';
      }

      // 构建消息内容
      List<Map<String, dynamic>> content = [
        {
          'type': 'text',
          'text': prompt,
        },
      ];

      // 添加图片
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
        hasImages: true, // 标记包含图片
      );
    } catch (e) {
      return OpenAIResponse.error('发送配文建议请求失败: $e');
    }
  }

  /// 发送通用文本请求（不包含图片）
  static Future<OpenAIResponse> sendTextRequest({
    required String characterName,
    required String prompt,
    double? temperature,
    int? maxTokens,
    bool isCommentGeneration = false, // 新增参数，标识是否为评论生成
    bool useRawPrompt = false, // 新增参数，是否使用原始prompt（不自动添加角色prompt）
  }) async {
    try {
      final character = AICharactersConfig.getCharacterByName(characterName);
      if (character == null) {
        return OpenAIResponse.error('未找到指定的AI角色: $characterName');
      }

      String fullPrompt;
      if (useRawPrompt) {
        // 使用原始prompt，不添加角色prompt
        fullPrompt = prompt;
      } else {
        // 根据用途选择合适的prompt
        String characterPrompt;
        if (isCommentGeneration) {
          characterPrompt = character.imageCommentPrompt;
        } else {
          characterPrompt = character.basePersonality;
        }
        // 构建完整prompt
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
        hasImages: false, // 标记不包含图片
      );
    } catch (e) {
      return OpenAIResponse.error('发送文本请求失败: $e');
    }
  }

  /// 发送HTTP请求到API
  static Future<OpenAIResponse> _sendRequest({
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
    bool hasImages = false,
  }) async {
    try {
      if (!ApiConfig.isApiKeyConfigured) {
        return OpenAIResponse.error('API密钥未配置，请在ApiConfig中设置正确的API密钥');
      }

      // 根据是否包含图片选择合适的模型
      String modelToUse;
      if (hasImages) {
        // 使用视觉模型
        modelToUse = ApiConfig.defaultVisionModel;
        // 检查模型是否支持视觉
        if (!ApiConfig.isVisionModelSupported(modelToUse)) {
          return OpenAIResponse.error('当前配置的视觉模型不支持图片分析: $modelToUse');
        }
      } else {
        // 使用文本模型
        modelToUse = ApiConfig.defaultModel;
      }

      final requestBody = {
        'model': modelToUse,
        'messages': messages,
        'temperature': temperature ?? ApiConfig.defaultTemperature,
        'max_tokens': maxTokens ?? (hasImages ? ApiConfig.visionMaxTokens : ApiConfig.defaultMaxTokens),
      };

      print('🚀 发送API请求 - 模型: $modelToUse, 包含图片: $hasImages');

      final response = await http.post(
        Uri.parse(ApiConfig.apiUrl),
        headers: ApiConfig.headers,
        body: json.encode(requestBody),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final result = OpenAIResponse.fromJson(responseData);
        print('✅ API请求成功 - Token使用: ${result.tokensUsed}');
        return result;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        print('❌ API请求失败 (${response.statusCode}): $errorMessage');
        return OpenAIResponse.error('API请求失败 (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ API请求异常: $e');
      if (e.toString().contains('TimeoutException')) {
        return OpenAIResponse.error('请求超时，请检查网络连接');
      } else {
        return OpenAIResponse.error('网络请求失败: $e');
      }
    }
  }

  /// 将本地图片编码为base64格式
  static String _encodeImageToBase64(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('图片文件不存在: $imagePath');
      }
      
      final bytes = file.readAsBytesSync();
      
      // 检查文件大小
      if (bytes.length > ApiConfig.maxImageSize) {
        throw Exception('图片文件过大，最大支持${ApiConfig.maxImageSize ~/ (1024 * 1024)}MB');
      }
      
      final base64String = base64Encode(bytes);
      
      // 根据文件扩展名确定MIME类型
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
      throw Exception('图片编码失败: $e');
    }
  }

  /// 验证API密钥是否有效
  static Future<bool> validateApiKey() async {
    try {
      final response = await sendTextRequest(
        characterName: '混沌原体Y',
        prompt: '请回复"测试成功"',
        maxTokens: 10,
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// 获取API使用统计
  static Future<Map<String, dynamic>?> getUsageStats() async {
    // Groq API不直接提供使用统计，需要通过其他方式获取
    // 可以考虑在本地记录API调用次数和token使用量
    return null;
  }
} 