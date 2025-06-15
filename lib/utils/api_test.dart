import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/openai_api_service.dart';
import '../services/ai_service_manager.dart';

/// API测试工具类
class ApiTest {
  /// 测试基本的文本请求
  static Future<void> testTextRequest() async {
    print('🧪 开始测试文本请求...');
    
    try {
      final response = await OpenAIApiService.sendTextRequest(
        characterName: '混沌原体Y',
        prompt: '请简单回复"测试成功"',
        maxTokens: 20,
      );
      
      if (response.success) {
        print('✅ 文本请求测试成功！');
        print('📝 回复内容: ${response.content}');
        print('🔢 使用Token: ${response.tokensUsed}');
      } else {
        print('❌ 文本请求测试失败: ${response.error}');
      }
    } catch (e) {
      print('❌ 文本请求测试异常: $e');
    }
    
    print('');
  }

  /// 测试图片请求支持
  static Future<void> testImageSupport() async {
    print('🖼️ 开始测试图片请求支持...');
    
    try {
      // 创建一个简单的测试图片base64编码
      final testImageBase64 = _createTestImageBase64();
      
      final requestBody = {
        'model': ApiConfig.defaultModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '请描述这张图片，如果你能看到图片请回复"我可以看到图片"，如果不能请回复"我无法看到图片"',
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
          
          print('✅ 图片请求测试成功！');
          print('📝 回复内容: $content');
          print('🔢 使用Token: ${usage?['total_tokens']}');
          
          // 判断是否支持图片
          if (content.contains('可以看到') || content.toLowerCase().contains('image') || content.toLowerCase().contains('picture')) {
            print('🎉 API支持图片请求！');
          } else {
            print('⚠️ API可能不支持图片请求，或者图片格式有问题');
          }
        } else {
          print('❌ 图片请求测试失败: 无有效响应');
        }
      } else {
        final errorData = json.decode(response.body);
        print('❌ 图片请求测试失败 (${response.statusCode}): ${errorData['error']?['message']}');
        
        // 检查是否是不支持图片的错误
        final errorMessage = errorData['error']?['message']?.toString().toLowerCase() ?? '';
        if (errorMessage.contains('image') || errorMessage.contains('vision') || errorMessage.contains('multimodal')) {
          print('💡 提示: 该API可能不支持图片功能，建议使用纯文本模式');
        }
      }
    } catch (e) {
      print('❌ 图片请求测试异常: $e');
    }
    
    print('');
  }

  /// 测试AI服务管理器
  static Future<void> testAIServiceManager() async {
    print('🤖 开始测试AI服务管理器...');
    
    try {
      // 测试获取AI角色信息
      final characters = AIServiceManager.getAllAICharacters();
      print('✅ 获取到${characters.length}个AI角色');
      
      // 测试发送文本消息
      final textResult = await AIServiceManager.sendTextMessage(
        characterName: '混沌原体Y',
        message: '你好，请简单介绍一下自己',
      );
      
      if (textResult['success'] == true) {
        print('✅ AI角色对话测试成功！');
        print('📝 ${textResult['characterName']}: ${textResult['content']}');
      } else {
        print('❌ AI角色对话测试失败: ${textResult['error']}');
      }
      
    } catch (e) {
      print('❌ AI服务管理器测试异常: $e');
    }
    
    print('');
  }

  /// 运行所有测试
  static Future<void> runAllTests() async {
    print('🚀 开始API功能测试...\n');
    
    // 检查API配置
    if (!ApiConfig.isApiKeyConfigured) {
      print('❌ API密钥未配置！');
      return;
    }
    
    print('🔑 API密钥已配置');
    print('🌐 API地址: ${ApiConfig.apiUrl}');
    print('🤖 使用模型: ${ApiConfig.defaultModel}\n');
    
    // 运行测试
    await testTextRequest();
    await testImageSupport();
    await testAIServiceManager();
    
    print('🏁 测试完成！');
  }

  /// 创建一个简单的测试图片base64编码（1x1像素的红色PNG）
  static String _createTestImageBase64() {
    // 这是一个1x1像素红色PNG图片的base64编码
    const pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
    return 'data:image/png;base64,$pngBase64';
  }

  /// 测试特定图片文件（如果存在）
  static Future<void> testWithImageFile(String imagePath) async {
    print('🖼️ 测试指定图片文件: $imagePath');
    
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        print('❌ 图片文件不存在: $imagePath');
        return;
      }
      
      final response = await OpenAIApiService.getImageComment(
        characterName: '混沌原体Y',
        imagePaths: [imagePath],
        userContext: '这是一个测试图片',
        scenario: '测试场景',
      );
      
      if (response.success) {
        print('✅ 图片文件测试成功！');
        print('📝 AI评论: ${response.content}');
        print('🔢 使用Token: ${response.tokensUsed}');
      } else {
        print('❌ 图片文件测试失败: ${response.error}');
      }
    } catch (e) {
      print('❌ 图片文件测试异常: $e');
    }
  }
} 