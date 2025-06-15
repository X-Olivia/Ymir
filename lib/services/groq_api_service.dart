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
          error: '响应格式错误：未找到有效内容',
        );
      }
    } catch (e) {
      return GroqResponse(
        success: false,
        error: '解析响应失败: $e',
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
        return GroqResponse.error('未找到指定的AI角色: $characterName');
      }

      // 构建prompt
      String prompt = character['imageCommentPrompt'] ?? '';
      
      // 添加用户上下文
      if (customPrompt != null && customPrompt.isNotEmpty) {
        prompt += '\n\n用户补充信息: $customPrompt';
      }
      
      // 添加图片数量信息
      if (imagePaths.length > 1) {
        prompt += '\n\n用户上传了${imagePaths.length}张图片，请生成详细的图片描述';
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
        temperature: character['temperature'] ?? ApiConfig.defaultTemperature,
        maxTokens: character['maxTokens'] ?? ApiConfig.defaultMaxTokens,
        hasImages: true,
      );
    } catch (e) {
      return GroqResponse.error('发送图片评论请求失败: $e');
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
        return GroqResponse.error('未找到指定的AI角色: $characterName');
      }

      // 构建prompt
      String prompt = character['captionSuggestPrompt'] ?? '';
      
      // 添加用户输入的信息
      if (customPrompt != null && customPrompt.isNotEmpty) {
        prompt += '\n\n用户标题: $customPrompt';
      }
      
      if (customPrompt != null && customPrompt.isNotEmpty) {
        prompt += '\n\n用户描述: $customPrompt';
      }
      
      // 添加图片数量信息
      if (imagePaths.length > 1) {
        prompt += '\n\n用户上传了${imagePaths.length}张图片，请生成详细的图片描述';
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
        temperature: character['temperature'] ?? ApiConfig.defaultTemperature,
        maxTokens: character['maxTokens'] ?? ApiConfig.defaultMaxTokens,
        hasImages: true,
      );
    } catch (e) {
      return GroqResponse.error('发送配文建议请求失败: $e');
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
        return GroqResponse.error('未找到指定的AI角色: $characterName');
      }

      // 构建完整prompt
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
      return GroqResponse.error('发送文本请求失败: $e');
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
        return GroqResponse.error('API密钥未配置，请在ApiConfig中设置正确的Groq API密钥');
      }

      // 根据是否包含图片选择合适的模型
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
        return GroqResponse.error('API请求失败 (${response.statusCode}): $errorMessage');
      }
    } on SocketException {
      return GroqResponse.error('网络连接失败，请检查网络设置');
    } on HttpException {
      final statusCode = response?.statusCode ?? 0;
      return GroqResponse.error('HTTP请求失败 ($statusCode)');
    } on FormatException {
      return GroqResponse.error('响应数据格式错误');
    } on TimeoutException {
      return GroqResponse.error('请求超时，请检查网络连接');
    } catch (e) {
      return GroqResponse.error('网络请求失败: $e');
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
        message: '请回复"测试成功"',
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// 获取API使用统计（Groq不直接提供此功能）
  static Future<Map<String, dynamic>?> getUsageStats() async {
    // Groq API不直接提供使用统计，需要通过其他方式获取
    // 可以考虑在本地记录API调用次数和token使用量
    return null;
  }
} 