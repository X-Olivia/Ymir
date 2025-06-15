import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
//用于数据持久，将评论数据保存到本地存储

class CommentService {
  static const String _commentsKey = 'post_comments';
  static const String _generationStatusKey = 'comment_generation_status';
  static const String _commentLikesKey = 'comment_likes';

  // 保存帖子的评论
  static Future<void> savePostComments(String postId, List<Map<String, dynamic>> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey) ?? '{}';
      final Map<String, dynamic> allComments = json.decode(commentsJson);
      
      // 保存该帖子的评论
      allComments[postId] = comments;
      
      await prefs.setString(_commentsKey, json.encode(allComments));
    } catch (e) {
      print('保存评论失败: $e');
    }
  }

  // 获取帖子的评论
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
      print('获取评论失败: $e');
      return [];
    }
  }

  // 添加单个评论到帖子
  static Future<void> addCommentToPost(String postId, Map<String, dynamic> comment) async {
    try {
      final existingComments = await getPostComments(postId);
      existingComments.add(comment);
      await savePostComments(postId, existingComments);
    } catch (e) {
      print('添加评论失败: $e');
    }
  }

  // 设置帖子的评论生成状态
  static Future<void> setCommentGenerationStatus(String postId, bool isGenerating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_generationStatusKey) ?? '{}';
      final Map<String, dynamic> allStatus = json.decode(statusJson);
      
      allStatus[postId] = isGenerating;
      
      await prefs.setString(_generationStatusKey, json.encode(allStatus));
    } catch (e) {
      print('设置生成状态失败: $e');
    }
  }

  // 获取帖子的评论生成状态
  static Future<bool> getCommentGenerationStatus(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_generationStatusKey) ?? '{}';
      final Map<String, dynamic> allStatus = json.decode(statusJson);
      
      return allStatus[postId] ?? false;
    } catch (e) {
      print('获取生成状态失败: $e');
      return false;
    }
  }

  // 清理已完成生成的状态记录
  static Future<void> cleanupCompletedGenerationStatus(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_generationStatusKey) ?? '{}';
      final Map<String, dynamic> allStatus = json.decode(statusJson);
      
      allStatus.remove(postId);
      
      await prefs.setString(_generationStatusKey, json.encode(allStatus));
    } catch (e) {
      print('清理生成状态失败: $e');
    }
  }

  // 删除帖子的所有评论
  static Future<void> deletePostComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey) ?? '{}';
      final Map<String, dynamic> allComments = json.decode(commentsJson);
      
      allComments.remove(postId);
      
      await prefs.setString(_commentsKey, json.encode(allComments));
      
      // 同时清理生成状态
      await cleanupCompletedGenerationStatus(postId);
    } catch (e) {
      print('删除评论失败: $e');
    }
  }

  // 更新帖子中的单个评论
  static Future<void> updateCommentInPost(String postId, Map<String, dynamic> updatedComment) async {
    try {
      final existingComments = await getPostComments(postId);
      final commentIndex = existingComments.indexWhere((comment) => comment['id'] == updatedComment['id']);
      
      if (commentIndex != -1) {
        existingComments[commentIndex] = updatedComment;
        await savePostComments(postId, existingComments);
      }
    } catch (e) {
      print('更新评论失败: $e');
    }
  }

  // 保存评论点赞状态
  static Future<void> saveCommentLikeStatus(String postId, String commentId, bool isLiked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesJson = prefs.getString(_commentLikesKey) ?? '{}';
      final Map<String, dynamic> allLikes = json.decode(likesJson);
      
      // 使用 postId_commentId 作为键来存储点赞状态
      final likeKey = '${postId}_$commentId';
      allLikes[likeKey] = isLiked;
      
      await prefs.setString(_commentLikesKey, json.encode(allLikes));
    } catch (e) {
      print('保存点赞状态失败: $e');
    }
  }

  // 获取评论点赞状态
  static Future<bool> getCommentLikeStatus(String postId, String commentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesJson = prefs.getString(_commentLikesKey) ?? '{}';
      final Map<String, dynamic> allLikes = json.decode(likesJson);
      
      final likeKey = '${postId}_$commentId';
      return allLikes[likeKey] ?? false;
    } catch (e) {
      print('获取点赞状态失败: $e');
      return false;
    }
  }

  // 获取帖子所有评论的点赞状态
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
      print('获取帖子点赞状态失败: $e');
      return {};
    }
  }
} 