import 'dart:async';
import '../models/post_model.dart';
import '../services/comment_service.dart';
import '../services/image_analysis_service.dart';
import '../services/ai_service_manager.dart';
import '../config/ai_characters_config.dart';
import '../services/openai_api_service.dart';

/// AI comment generation process management service
/// Responsibilities: manage the complete comment-generation workflow, state, and stream notifications
class BackgroundCommentService {
  static final Map<String, StreamController<List<Map<String, dynamic>>>> _commentStreams = {};
  // Track posts that have completed comment generation, ensuring each post is only generated once
  static final Set<String> _completedPosts = {};
  // Track posts that are generating comments
  static final Set<String> _generatingPosts = {};

  /// Start generating comments for a post in the user's selected AI order
  static Future<void> startCommentGeneration(PostModel post) async {
    final postId = post.id;
    
    // If already completed or being generated, do not start again
    if (_completedPosts.contains(postId) || _generatingPosts.contains(postId)) {
      print('📋 Post $postId is complete or already generating comments; skipping');
      return;
    }

    // Mark as generating
    _generatingPosts.add(postId);
    await CommentService.setCommentGenerationStatus(postId, true);

    // Create a comment stream controller
    if (!_commentStreams.containsKey(postId)) {
      _commentStreams[postId] = StreamController<List<Map<String, dynamic>>>.broadcast();
    }

    try {
      print('🚀 Starting AI comment generation for post $postId');
      
      // Step 1: Analyze images
      print('📸 Step 1: Analyzing images...');
      final imageAnalysisResult = await _analyzePostImages(post);
      
      if (!imageAnalysisResult['success']) {
        throw Exception('Image analysis failed: ${imageAnalysisResult['error']}');
      }
      
      final imageAnalysis = imageAnalysisResult['analysis'] as String;
      print('✅ Image analysis completed');
      print('📋 Image analysis result details:');
      print('=' * 50);
      
      // Print long text in segments to avoid truncation
      final lines = imageAnalysis.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          print(line);
        }
      }
      
      print('=' * 50);
      
      // Step 2: Get the user's selected AI characters
      print('🎭 Step 2: Getting selected AI characters...');
      final selectedAIs = await AIServiceManager.getSelectedAIFriends();
      
      if (selectedAIs.isEmpty) {
        throw Exception('The user did not select any AI characters');
      }
      
      print('📝 User selected ${selectedAIs.length} AI characters: ${selectedAIs.map((ai) => ai.name).join(', ')}');
      
      // Step 3: Generate each AI comment in sequence
      print('💬 Step 3: Generating AI comments in sequence...');
      await _generateCommentsSequentially(post, imageAnalysis, selectedAIs);
      
      // Step 4: Mark the workflow complete
      print('🎉 AI comment generation completed for post $postId');
      _completedPosts.add(postId);
      
    } catch (e) {
      print('❌ Comment generation failed for post $postId: $e');
    } finally {
      // Clean status
      _generatingPosts.remove(postId);
      await CommentService.setCommentGenerationStatus(postId, false);
    }
  }

  /// Analyze post images
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
        'error': 'Image analysis error: $e',
      };
    }
  }

  /// Generate a comment from each AI character in sequence
  static Future<void> _generateCommentsSequentially(
    PostModel post, 
    String imageAnalysis, 
    List<AICharacterConfig> selectedAIs
  ) async {
    // Choose the prompt type based on the post source
    final bool isImagePost = post.source == PostSource.imagePost;
    final bool isCaptionSuggest = post.source == PostSource.captionSuggest;
    
    print('📋 Post source: ${post.source}; using the ${isImagePost ? 'imageComment' : 'captionSuggest'} prompt');
    
    final userContext = _buildUserContext(post, imageAnalysis, isImagePost);
    
    for (int i = 0; i < selectedAIs.length; i++) {
      final aiCharacter = selectedAIs[i];
      
      try {
        print('🎭 Generating ${aiCharacter.name} comments (${i + 1}/${selectedAIs.length})...');
        
        // Choose the appropriate prompt for the post type
        String characterPrompt;
        if (isImagePost) {
          characterPrompt = aiCharacter.imageCommentPrompt;
        } else {
          characterPrompt = aiCharacter.captionSuggestPrompt;
        }
        
        // Generate a comment for each AI character using custom logic instead of sendTextMessage
        final response = await _generateCommentWithCustomPrompt(
          aiCharacter: aiCharacter,
          characterPrompt: characterPrompt,
          userContext: userContext,
        );
        
        if (response['success'] == true) {
          // Build a complete comment object
          final comment = _buildCommentObject(response, aiCharacter);
          await CommentService.addCommentToPost(post.id, comment);
          
          // Notify stream listeners
          await _notifyCommentUpdate(post.id);
          
          print('✅ ${aiCharacter.name} generated a comment successfully: ${response['content']}');
          
          // Add a delay to avoid sending API requests too frequently
          if (i < selectedAIs.length - 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          final error = response['error'] ?? 'Unknown error';
          print('❌ ${aiCharacter.name} Comment generation failed: $error');
        }
        
      } catch (e) {
        print('❌ Error generating a comment from ${aiCharacter.name}: $e');
      }
    }
  }

  /// Generate a comment using a custom prompt
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
        'content': 'An error occurred while sending the message: $e',
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Extract image path (reuse logic)
  static List<String> _extractImagePaths(PostModel post) {
    return post.images.map((file) => file.path).toList();
  }

  /// Build user context (optimized based on post type)
  static String _buildUserContext(PostModel post, String imageAnalysis, bool isImagePost) {
    if (isImagePost) {
      // Image selection page - The point is to help choose images
      return '''
The user is sharing content from the "Select Images" page and wants your advice and comments as a friend.

[Content shared by the user]
Title: ${post.title}
Description: ${post.description ?? 'No specific description'}

[Image content]
$imageAnalysis

[Your mission]
Use your unique personality and perspective to comment on these images or offer suggestions. Speak naturally, as if chatting with a friend, and keep your response under 50 words.
''';
    } else {
      // Caption suggestion page - Focus on helping the user develop a caption
      return '''
[User request]
Desired caption theme: ${post.title}
Specific requirements: ${post.description ?? 'No specific requirements'}

[Image content]
$imageAnalysis

[Your mission]
Use your unique creative style to suggest captions or inspiration for these images. Preserve your personality and keep your response under 50 words.
''';
    }
  }

  /// Build comment objects (reuse logic)
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

  /// Notify of comment updates
  static Future<void> _notifyCommentUpdate(String postId) async {
    final streamController = _commentStreams[postId];
    if (streamController != null && !streamController.isClosed) {
      final allComments = await CommentService.getPostComments(postId);
      streamController.add(allComments);
      print('📡 Stream listener has been notified, current number of comments: ${allComments.length}');
    }
  }

  /// Stop generating comments on a post
  static Future<void> stopCommentGeneration(String postId) async {
    _generatingPosts.remove(postId);
    await CommentService.setCommentGenerationStatus(postId, false);

    // Close flow controller
    final streamController = _commentStreams[postId];
    if (streamController != null) {
      streamController.close();
      _commentStreams.remove(postId);
    }
  }

  /// Get the comment stream for a post
  static Stream<List<Map<String, dynamic>>>? getCommentStream(String postId) {
    return _commentStreams[postId]?.stream;
  }

  /// Check if the post is generating comments
  static bool isGeneratingComments(String postId) {
    return _generatingPosts.contains(postId);
  }

  /// Check whether the post has finished generating comments
  static bool isCommentGenerationCompleted(String postId) {
    return _completedPosts.contains(postId);
  }

  /// Clean up all background tasks (called when the app is closed)
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