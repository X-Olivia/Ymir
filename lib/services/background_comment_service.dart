import 'dart:async';
import '../models/post_model.dart';
import '../services/comment_service.dart';
import '../services/image_analysis_service.dart';
import '../services/ai_service_manager.dart';
import '../config/ai_characters_config.dart';
import '../services/openai_api_service.dart';

/// AI评论生成流程管理服务
/// 职责：管理评论生成的完整业务流程、状态管理、Stream通知
class BackgroundCommentService {
  static final Map<String, StreamController<List<Map<String, dynamic>>>> _commentStreams = {};
  // 跟踪已完成评论生成的帖子，确保每个帖子只生成一次
  static final Set<String> _completedPosts = {};
  // 跟踪正在生成评论的帖子
  static final Set<String> _generatingPosts = {};

  /// 开始为帖子生成评论（按照用户选择的AI顺序）
  static Future<void> startCommentGeneration(PostModel post) async {
    final postId = post.id;
    
    // 如果已经完成或正在生成，不重复开始
    if (_completedPosts.contains(postId) || _generatingPosts.contains(postId)) {
      print('📋 帖子 $postId 已完成或正在生成评论，跳过');
      return;
    }

    // 标记为正在生成
    _generatingPosts.add(postId);
    await CommentService.setCommentGenerationStatus(postId, true);

    // 创建评论流控制器
    if (!_commentStreams.containsKey(postId)) {
      _commentStreams[postId] = StreamController<List<Map<String, dynamic>>>.broadcast();
    }

    try {
      print('🚀 开始为帖子 $postId 生成AI评论');
      
      // 步骤1：图片分析
      print('📸 步骤1：开始图片分析...');
      final imageAnalysisResult = await _analyzePostImages(post);
      
      if (!imageAnalysisResult['success']) {
        throw Exception('图片分析失败: ${imageAnalysisResult['error']}');
      }
      
      final imageAnalysis = imageAnalysisResult['analysis'] as String;
      print('✅ 图片分析完成');
      print('📋 图片分析结果详情：');
      print('=' * 50);
      
      // 分段打印长文本，避免被截断
      final lines = imageAnalysis.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          print(line);
        }
      }
      
      print('=' * 50);
      
      // 步骤2：获取用户选择的AI角色
      print('🎭 步骤2：获取用户选择的AI角色...');
      final selectedAIs = await AIServiceManager.getSelectedAIFriends();
      
      if (selectedAIs.isEmpty) {
        throw Exception('用户未选择任何AI角色');
      }
      
      print('📝 用户选择了 ${selectedAIs.length} 个AI角色: ${selectedAIs.map((ai) => ai.name).join(', ')}');
      
      // 步骤3：按顺序为每个AI生成评论
      print('💬 步骤3：开始按顺序生成AI评论...');
      await _generateCommentsSequentially(post, imageAnalysis, selectedAIs);
      
      // 步骤4：标记完成
      print('🎉 帖子 $postId 的AI评论生成流程完成');
      _completedPosts.add(postId);
      
    } catch (e) {
      print('❌ 帖子 $postId 评论生成失败: $e');
    } finally {
      // 清理状态
      _generatingPosts.remove(postId);
      await CommentService.setCommentGenerationStatus(postId, false);
    }
  }

  /// 分析帖子图片
  static Future<Map<String, dynamic>> _analyzePostImages(PostModel post) async {
    try {
      final imagePaths = _extractImagePaths(post);
      
      final analysisResult = await ImageAnalysisService.analyzeImages(
        imagePaths: imagePaths,
      );
      
      return analysisResult;
    } catch (e) {
      return {
        'success': false,
        'error': '图片分析异常: $e',
      };
    }
  }

  /// 按顺序为每个AI生成评论
  static Future<void> _generateCommentsSequentially(
    PostModel post, 
    String imageAnalysis, 
    List<AICharacterConfig> selectedAIs
  ) async {
    // 根据帖子来源确定prompt类型
    final bool isImagePost = post.source == PostSource.imagePost;
    final bool isCaptionSuggest = post.source == PostSource.captionSuggest;
    
    print('📋 帖子来源: ${post.source}, 使用${isImagePost ? 'imageComment' : 'captionSuggest'}Prompt');
    
    final userContext = _buildUserContext(post, imageAnalysis, isImagePost);
    
    for (int i = 0; i < selectedAIs.length; i++) {
      final aiCharacter = selectedAIs[i];
      
      try {
        print('🎭 正在生成 ${aiCharacter.name} 的评论 (${i + 1}/${selectedAIs.length})...');
        
        // 根据帖子类型选择合适的prompt
        String characterPrompt;
        if (isImagePost) {
          characterPrompt = aiCharacter.imageCommentPrompt;
        } else {
          characterPrompt = aiCharacter.captionSuggestPrompt;
        }
        
        // 为每个AI角色生成评论 - 使用自定义逻辑而不是sendTextMessage
        final response = await _generateCommentWithCustomPrompt(
          aiCharacter: aiCharacter,
          characterPrompt: characterPrompt,
          userContext: userContext,
        );
        
        if (response['success'] == true) {
          // 构建完整的评论对象
          final comment = _buildCommentObject(response, aiCharacter);
          await CommentService.addCommentToPost(post.id, comment);
          
          // 通知流监听者
          await _notifyCommentUpdate(post.id);
          
          print('✅ ${aiCharacter.name} 评论生成成功: ${response['content']}');
          
          // 添加延迟，避免API请求过于频繁
          if (i < selectedAIs.length - 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          final error = response['error'] ?? '未知错误';
          print('❌ ${aiCharacter.name} 评论生成失败: $error');
        }
        
      } catch (e) {
        print('❌ ${aiCharacter.name} 评论生成异常: $e');
      }
    }
  }

  /// 使用自定义prompt生成评论
  static Future<Map<String, dynamic>> _generateCommentWithCustomPrompt({
    required AICharacterConfig aiCharacter,
    required String characterPrompt,
    required String userContext,
  }) async {
    try {
      final response = await OpenAIApiService.sendTextRequest(
        characterName: aiCharacter.name,
        prompt: '$characterPrompt\n\n$userContext',
        temperature: aiCharacter.temperature,
        maxTokens: aiCharacter.maxTokens,
        useRawPrompt: true,
      );

      return {
        'characterName': aiCharacter.name,
        'characterAvatar': aiCharacter.avatar,
        'characterColor': aiCharacter.avatarColor,
        'content': response.content,
        'success': response.success,
        'error': response.error,
        'tokensUsed': response.tokensUsed,
      };
    } catch (e) {
      return {
        'characterName': aiCharacter.name,
        'content': '发送消息时发生错误: $e',
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 提取图片路径（复用逻辑）
  static List<String> _extractImagePaths(PostModel post) {
    return post.images.map((file) => file.path).toList();
  }

  /// 构建用户上下文（根据帖子类型优化）
  static String _buildUserContext(PostModel post, String imageAnalysis, bool isImagePost) {
    if (isImagePost) {
      // 图片选择页面 - 重点是帮助选择图片
      return '''
用户在"选图片"页面分享了内容，需要你作为朋友给出建议和评论。

【用户分享的内容】
标题：${post.title}
描述：${post.description ?? '无具体描述'}

【图片内容】
$imageAnalysis

【你的任务】
用你独特的性格和视角，对这些图片给出评价或建议。保持你的说话风格，像朋友间自然聊天。控制在50字以内。
''';
    } else {
      // 配文建议页面 - 重点是帮助想文案
      return '''
【用户需求】
想要的文案主题：${post.title}
具体需求：${post.description ?? '无具体需求'}

【图片内容】
$imageAnalysis

【你的任务】
用你独特的创作风格，为这些图片提供配文建议或灵感。保持你的个性特色，控制在50字以内。
''';
    }
  }

  /// 构建评论对象（复用逻辑）
  static Map<String, dynamic> _buildCommentObject(
    Map<String, dynamic> aiResult, 
    AICharacterConfig aiCharacter
  ) {
    return {
      'id': '${DateTime.now().millisecondsSinceEpoch}_${aiCharacter.name}',
      'content': aiResult['content'],
      'name': aiCharacter.name,
      'author': aiCharacter.name,
      'avatar': aiCharacter.avatar,
      'avatarColor': aiCharacter.avatarColor.toARGB32(),
      'timestamp': DateTime.now().toIso8601String(),
      'isAI': true,
      'likes': 0,
      'replies': <Map<String, dynamic>>[],
    };
  }

  /// 通知评论更新
  static Future<void> _notifyCommentUpdate(String postId) async {
    final streamController = _commentStreams[postId];
    if (streamController != null && !streamController.isClosed) {
      final allComments = await CommentService.getPostComments(postId);
      streamController.add(allComments);
      print('📡 已通知流监听者，当前评论数: ${allComments.length}');
    }
  }

  /// 停止为帖子生成评论
  static Future<void> stopCommentGeneration(String postId) async {
    _generatingPosts.remove(postId);
    await CommentService.setCommentGenerationStatus(postId, false);

    // 关闭流控制器
    final streamController = _commentStreams[postId];
    if (streamController != null) {
      streamController.close();
      _commentStreams.remove(postId);
    }
  }

  /// 获取帖子的评论流
  static Stream<List<Map<String, dynamic>>>? getCommentStream(String postId) {
    return _commentStreams[postId]?.stream;
  }

  /// 检查帖子是否正在生成评论
  static bool isGeneratingComments(String postId) {
    return _generatingPosts.contains(postId);
  }

  /// 检查帖子是否已完成评论生成
  static bool isCommentGenerationCompleted(String postId) {
    return _completedPosts.contains(postId);
  }

  /// 清理所有后台任务（应用关闭时调用）
  static void cleanupAllTasks() {
    _generatingPosts.clear();
    _completedPosts.clear();

    for (final controller in _commentStreams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _commentStreams.clear();
  }
} 