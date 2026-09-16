import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
//Used for data persistence, save comment data to local storage

class CommentService {
  static const String _commentsKey = 'post_comments';
  static const String _generationStatusKey = 'comment_generation_status';
  static const String _commentLikesKey = 'comment_likes';

  // Save comments on posts
  static Future<void> savePostComments(String postId, List<Map<String, dynamic>> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey) ?? '{}';
      final Map<String, dynamic> allComments = json.decode(commentsJson);
      
      // Save comments on this post
      allComments[postId] = comments;
      
      await prefs.setString(_commentsKey, json.encode(allComments));
    } catch (e) {
      print('Failed to save comment: $e');
    }
  }

  // Get comments on a post
  static Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey) ?? '{}';
      final Map<String, dynamic> allComments = json.decode(commentsJson);
      
      final postComments = allComments[postId];
      if (postComments is List) {
        return List<Map<String, dynamic>>.from(postComments);
      }
      return [];
    } catch (e) {
      print('Failed to get comments: $e');
      return [];
    }
  }

  // Add a single comment to a post
  static Future<void> addCommentToPost(String postId, Map<String, dynamic> comment) async {
    try {
      final existingComments = await getPostComments(postId);
      existingComments.add(comment);
      await savePostComments(postId, existingComments);
    } catch (e) {
      print('Failed to add comment: $e');
    }
  }

  // Set comment generation status for posts
  static Future<void> setCommentGenerationStatus(String postId, bool isGenerating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_generationStatusKey) ?? '{}';
      final Map<String, dynamic> allStatus = json.decode(statusJson);
      
      allStatus[postId] = isGenerating;
      
      await prefs.setString(_generationStatusKey, json.encode(allStatus));
    } catch (e) {
      print('Setting build status failed: $e');
    }
  }

  // Get the comment generation status of a post
  static Future<bool> getCommentGenerationStatus(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_generationStatusKey) ?? '{}';
      final Map<String, dynamic> allStatus = json.decode(statusJson);
      
      return allStatus[postId] ?? false;
    } catch (e) {
      print('Failed to get build status: $e');
      return false;
    }
  }

  // Clean up status records of completed builds
  static Future<void> cleanupCompletedGenerationStatus(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_generationStatusKey) ?? '{}';
      final Map<String, dynamic> allStatus = json.decode(statusJson);
      
      allStatus.remove(postId);
      
      await prefs.setString(_generationStatusKey, json.encode(allStatus));
    } catch (e) {
      print('Cleaning build status failed: $e');
    }
  }

  // Delete all comments on post
  static Future<void> deletePostComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey) ?? '{}';
      final Map<String, dynamic> allComments = json.decode(commentsJson);
      
      allComments.remove(postId);
      
      await prefs.setString(_commentsKey, json.encode(allComments));
      
      // Also clear build status
      await cleanupCompletedGenerationStatus(postId);
    } catch (e) {
      print('Failed to delete comment: $e');
    }
  }

  // Update a single comment in a post
  static Future<void> updateCommentInPost(String postId, Map<String, dynamic> updatedComment) async {
    try {
      final existingComments = await getPostComments(postId);
      final commentIndex = existingComments.indexWhere((comment) => comment['id'] == updatedComment['id']);
      
      if (commentIndex != -1) {
        existingComments[commentIndex] = updatedComment;
        await savePostComments(postId, existingComments);
      }
    } catch (e) {
      print('Failed to update comment: $e');
    }
  }

  // Save comment like status
  static Future<void> saveCommentLikeStatus(String postId, String commentId, bool isLiked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesJson = prefs.getString(_commentLikesKey) ?? '{}';
      final Map<String, dynamic> allLikes = json.decode(likesJson);
      
      // use postId_commentId As a key to store like status
      final likeKey = '${postId}_$commentId';
      allLikes[likeKey] = isLiked;
      
      await prefs.setString(_commentLikesKey, json.encode(allLikes));
    } catch (e) {
      print('Failed to save like status: $e');
    }
  }

  // Get comment like status
  static Future<bool> getCommentLikeStatus(String postId, String commentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesJson = prefs.getString(_commentLikesKey) ?? '{}';
      final Map<String, dynamic> allLikes = json.decode(likesJson);
      
      final likeKey = '${postId}_$commentId';
      return allLikes[likeKey] ?? false;
    } catch (e) {
      print('Failed to get like status: $e');
      return false;
    }
  }

  // Get the like status of all comments on a post
  static Future<Map<String, bool>> getPostCommentLikes(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesJson = prefs.getString(_commentLikesKey) ?? '{}';
      final Map<String, dynamic> allLikes = json.decode(likesJson);
      
      final Map<String, bool> postLikes = {};
      final prefix = '${postId}_';
      
      allLikes.forEach((key, value) {
        if (key.startsWith(prefix)) {
          final commentId = key.substring(prefix.length);
          postLikes[commentId] = value ?? false;
        }
      });
      
      return postLikes;
    } catch (e) {
      print('Failed to get post like status: $e');
      return {};
    }
  }
} 