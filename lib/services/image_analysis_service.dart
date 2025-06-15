import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ImageAnalysisService {
  // 添加简单的内存缓存
  static final Map<String, Map<String, dynamic>> _analysisCache = {};
  
  // 通用图片分析提示词
  static const String _imageAnalysisPrompt = '''
你是一个专业的图片分析师，请仔细观察用户上传的图片，并按照以下格式提供详细的分析报告：

**图片内容描述：**
- 主要物体/人物/场景
- 动作或状态描述
- 空间布局和位置关系
- 细节描述

**视觉元素细节：**
- 色彩搭配（主色调、辅助色、色彩对比）
- 光线条件（自然光/人工光、明暗对比、光影效果）
- 材质纹理（如有明显特征）
- 细节特征（重要的装饰、标识、文字等）

**构图特点：**
- 构图方式（居中、三分法、对称等）
- 视角和拍摄角度
- 景深效果
- 画面平衡感

**情感氛围：**
- 整体情绪感受
- 风格特征（现代、复古、简约、华丽等）
- 传达的意境或主题

**技术质量：**
- 清晰度和焦点
- 曝光情况
- 构图完整性

请用简洁明了的语言描述，重点突出每张图片的特色和亮点。如果有多张图片，请分别分析每张图片，并在最后总结整体的视觉风格和主题连贯性。
''';

  /// 分析图片内容
  static Future<Map<String, dynamic>> analyzeImages({
    required List<String> imagePaths,
  }) async {
    try {
      // 验证输入
      if (imagePaths.isEmpty) {
        return {
          'success': false,
          'error': '没有提供图片路径',
        };
      }

      // 过滤有效的图片文件
      final validImagePaths = imagePaths.where((path) => isValidImageFile(path)).toList();
      if (validImagePaths.isEmpty) {
        return {
          'success': false,
          'error': '没有有效的图片文件',
        };
      }

      print('📸 开始分析 ${validImagePaths.length} 张图片');

      // 检查缓存
      final cacheKey = _generateCacheKey(validImagePaths);
      final cachedResult = _analysisCache[cacheKey];
      if (cachedResult != null) {
        print('💾 使用缓存的分析结果');
        return cachedResult;
      }

      Map<String, dynamic> result;
      
      if (validImagePaths.length == 1) {
        // 单张图片：直接分析
        print('🔍 单张图片分析');
        result = await _sendAnalysisRequest(validImagePaths);
      } else {
        // 多张图片：分别分析然后合并
        print('🔍 多张图片分别分析');
        result = await _analyzeMultipleImagesSeparately(validImagePaths);
      }

      // 缓存结果
      if (result['success'] == true) {
        _analysisCache[cacheKey] = result;
        print('💾 分析结果已缓存');
        
        // 限制缓存大小，避免内存泄漏
        if (_analysisCache.length > 10) {
          final firstKey = _analysisCache.keys.first;
          _analysisCache.remove(firstKey);
          print('🗑️ 清理旧缓存，当前缓存数量: ${_analysisCache.length}');
        }
      }

      return result;
    } catch (e) {
      print('❌ 图片分析异常: $e');
      return {
        'success': false,
        'error': '图片分析服务异常: $e',
      };
    }
  }

  /// 分别分析多张图片然后合并结果
  static Future<Map<String, dynamic>> _analyzeMultipleImagesSeparately(List<String> imagePaths) async {
    try {
      List<String> analysisResults = [];
      int totalTokens = 0;
      
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        print('📸 分析第 ${i + 1}/${imagePaths.length} 张图片');
        
        final result = await _sendAnalysisRequest([imagePath]);
        
        if (result['success'] == true) {
          final analysis = result['analysis'] as String;
          final imageAnalysis = '【图片${i + 1}】\n$analysis';
          analysisResults.add(imageAnalysis);
          totalTokens += (result['tokensUsed'] as int? ?? 0);
          
          print('✅ 第 ${i + 1} 张图片分析完成');
          
          // 添加延迟避免API请求过于频繁
          if (i < imagePaths.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          print('❌ 第 ${i + 1} 张图片分析失败: ${result['error']}');
          analysisResults.add('【图片${i + 1}】\n分析失败: ${result['error']}');
        }
      }
      
      if (analysisResults.isEmpty) {
        return {
          'success': false,
          'error': '所有图片分析都失败了',
        };
      }
      
      // 合并分析结果
      final combinedAnalysis = '''
用户上传了${imagePaths.length}张图片，以下是详细分析：

${analysisResults.join('\n\n')}

【整体总结】
这${imagePaths.length}张图片展现了用户想要分享的内容。每张图片都有其独特的特点和表达意图，可以根据用户的具体需求选择最合适的图片或给出相应的建议。
''';
      
      print('✅ 多张图片分析完成，总Token使用: $totalTokens');
      
      return {
        'success': true,
        'analysis': combinedAnalysis,
        'tokensUsed': totalTokens,
      };
      
    } catch (e) {
      print('❌ 多张图片分析异常: $e');
      return {
        'success': false,
        'error': '多张图片分析异常: $e',
      };
    }
  }

  /// 生成缓存键
  static String _generateCacheKey(List<String> imagePaths) {
    final pathsString = imagePaths.join('|');
    final bytes = utf8.encode(pathsString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 发送图片分析请求到API
  static Future<Map<String, dynamic>> _sendAnalysisRequest(List<String> imagePaths) async {
    try {
      // 准备图片数据
      List<Map<String, dynamic>> imageContents = [];
      
      for (String imagePath in imagePaths) {
        final file = File(imagePath);
        if (!file.existsSync()) {
          print('❌ 图片文件不存在: $imagePath');
          continue;
        }

        // 检查文件大小
        final bytes = await file.readAsBytes();
        final sizeInMB = bytes.length / (1024 * 1024);
        
        Uint8List finalImageBytes;
        String processInfo;
        
        if (bytes.length > ApiConfig.maxAnalysisImageSize) {
          print('📸 图片过大，开始压缩...');
          
          // 尝试压缩图片
          final compressedBytes = await _compressImage(bytes, imagePath);
          if (compressedBytes != null) {
            final compressedSizeMB = compressedBytes.length / (1024 * 1024);
            if (compressedBytes.length <= ApiConfig.maxAnalysisImageSize) {
              finalImageBytes = compressedBytes;
              processInfo = '压缩后: ${compressedSizeMB.toStringAsFixed(2)}MB';
              print('✅ 压缩成功');
            } else {
              print('❌ 压缩后仍过大，跳过处理');
              continue;
            }
          } else {
            print('❌ 图片压缩失败，跳过处理');
            continue;
          }
        } else {
          finalImageBytes = bytes;
          processInfo = '原图: ${sizeInMB.toStringAsFixed(2)}MB';
        }
        
        // 转换为base64
        final base64Image = base64Encode(finalImageBytes);
        
        // 获取图片格式
        String format = 'jpeg';
        if (imagePath.toLowerCase().endsWith('.png')) {
          format = 'png';
        } else if (imagePath.toLowerCase().endsWith('.gif')) {
          format = 'gif';
        } else if (imagePath.toLowerCase().endsWith('.webp')) {
          format = 'webp';
        }

        imageContents.add({
          "type": "image_url",
          "image_url": {
            "url": "data:image/$format;base64,$base64Image"
          }
        });
      }

      if (imageContents.isEmpty) {
        return {
          'success': false,
          'error': '没有有效的图片文件（可能图片过大，请使用小于${ApiConfig.maxAnalysisImageSize ~/ (1024 * 1024)}MB的图片）',
        };
      }

      // 构建消息内容
      List<Map<String, dynamic>> messageContent = [
        {
          "type": "text",
          "text": _imageAnalysisPrompt
        },
        ...imageContents,
      ];

      // 构建请求体
      final requestBody = {
        "model": ApiConfig.defaultVisionModel,
        "messages": [
          {
            "role": "user",
            "content": messageContent
          }
        ],
        "max_tokens": ApiConfig.visionMaxTokens, // 使用配置中的视觉模型token限制
        "temperature": 0.3, // 较低的温度以获得更客观的分析
      };

      // 发送请求
      print('🚀 发送图片分析请求');
      
      final response = await http.post(
        Uri.parse(ApiConfig.apiUrl),
        headers: ApiConfig.headers,
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.requestTimeout); // 添加超时配置

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          final tokensUsed = data['usage']?['total_tokens'] ?? 0;
          
          print('✅ 图片分析成功 - Token使用: $tokensUsed');
          
          return {
            'success': true,
            'analysis': content,
            'tokensUsed': tokensUsed,
          };
        } else {
          print('❌ API返回数据格式错误');
          return {
            'success': false,
            'error': 'API返回数据格式错误',
          };
        }
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorData['error']?['message'] ?? '未知错误';
        print('❌ API请求失败: ${response.statusCode}');
        return {
          'success': false,
          'error': 'API请求失败: ${response.statusCode} - $errorMessage',
        };
      }
    } catch (e) {
      print('❌ 图片分析请求异常: $e');
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'error': '请求超时，请检查网络连接',
        };
      } else {
        return {
          'success': false,
          'error': '请求异常: $e',
        };
      }
    }
  }

  /// 获取图片分析的简化版本（用于调试或预览）
  static String getAnalysisPreview(String fullAnalysis) {
    // 提取主要内容，生成简化版本
    final lines = fullAnalysis.split('\n');
    final preview = <String>[];
    
    for (String line in lines) {
      if (line.trim().isNotEmpty && 
          (line.contains('主要') || 
           line.contains('色彩') || 
           line.contains('构图') || 
           line.contains('情感') ||
           line.contains('风格'))) {
        preview.add(line.trim());
        if (preview.length >= 5) break; // 限制预览长度
      }
    }
    
    return preview.join('\n');
  }

  /// 验证图片文件是否有效
  static bool isValidImageFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return false;
    
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// 获取图片文件大小（MB）
  static double getImageSizeMB(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return 0.0;
    
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// 智能压缩图片
  /// 根据原图大小动态调整压缩质量，确保压缩后小于5MB
  static Future<Uint8List?> _compressImage(Uint8List originalBytes, String imagePath) async {
    try {
      // 解码图片
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // 获取原图尺寸
      final int originalWidth = image.width;
      final int originalHeight = image.height;
      final double originalSizeMB = originalBytes.length / (1024 * 1024);
      
      // 计算压缩比例，确保能压缩到5MB以下
      // 更激进的压缩策略
      double scaleFactor = 1.0;
      
      // 根据文件大小动态计算缩放比例（更激进）
      if (originalSizeMB > 50) {
        scaleFactor = 0.2; // 超大文件：缩放到20%
      } else if (originalSizeMB > 30) {
        scaleFactor = 0.25; // 很大文件：缩放到25%
      } else if (originalSizeMB > 20) {
        scaleFactor = 0.3; // 大文件：缩放到30%
      } else if (originalSizeMB > 15) {
        scaleFactor = 0.35; // 中大文件：缩放到35%
      } else if (originalSizeMB > 10) {
        scaleFactor = 0.4; // 中等文件：缩放到40%
      } else if (originalSizeMB > 7) {
        scaleFactor = 0.5; // 稍大文件：缩放到50%
      } else {
        scaleFactor = 0.6; // 接近限制：缩放到60%
      }
      
      final int targetWidth = (originalWidth * scaleFactor).round();
      final int targetHeight = (originalHeight * scaleFactor).round();
      
      // 创建画布并绘制缩放后的图片
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      // 绘制缩放后的图片
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
        ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        ui.Paint(),
      );
      
      // 转换为图片
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage = await picture.toImage(targetWidth, targetHeight);
      
      // 尝试不同的压缩方式，优先使用压缩效果更好的格式
      Uint8List? bestResult;
      double bestSizeMB = double.infinity;
      
      // 尝试JPEG格式（通常压缩效果更好）
      try {
        // 注意：Flutter的ImageByteFormat没有JPEG，我们使用PNG然后手动处理
        final ByteData? pngData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
        if (pngData != null) {
          final pngBytes = pngData.buffer.asUint8List();
          final pngSizeMB = pngBytes.length / (1024 * 1024);
          
          if (pngSizeMB < bestSizeMB) {
            bestResult = pngBytes;
            bestSizeMB = pngSizeMB;
          }
        }
      } catch (e) {
        print('PNG压缩失败: $e');
      }
      
      // 如果PNG压缩后仍然过大，尝试进一步缩小
      if (bestSizeMB > (ApiConfig.maxAnalysisImageSize / (1024 * 1024))) {
        
        // 进一步缩小到原来的一半
        final int smallerWidth = (targetWidth * 0.7).round();
        final int smallerHeight = (targetHeight * 0.7).round();
        
        final ui.PictureRecorder smallerRecorder = ui.PictureRecorder();
        final ui.Canvas smallerCanvas = ui.Canvas(smallerRecorder);
        
        smallerCanvas.drawImageRect(
          image,
          ui.Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
          ui.Rect.fromLTWH(0, 0, smallerWidth.toDouble(), smallerHeight.toDouble()),
          ui.Paint(),
        );
        
        final ui.Picture smallerPicture = smallerRecorder.endRecording();
        final ui.Image smallerImage = await smallerPicture.toImage(smallerWidth, smallerHeight);
        
        final ByteData? smallerData = await smallerImage.toByteData(format: ui.ImageByteFormat.png);
        if (smallerData != null) {
          final smallerBytes = smallerData.buffer.asUint8List();
          final smallerSizeMB = smallerBytes.length / (1024 * 1024);
          
          if (smallerSizeMB < bestSizeMB) {
            bestResult = smallerBytes;
            bestSizeMB = smallerSizeMB;
          }
        }
        
        smallerImage.dispose();
      }
      
      image.dispose();
      resizedImage.dispose();
      
      if (bestResult != null) {
        return bestResult;
      }
      
      return null;
    } catch (e) {
      print('❌ 图片压缩异常: $e');
      return null;
    }
  }
} 