import 'package:flutter/material.dart';
import 'dart:async';
import '../models/post_model.dart';
import '../services/comment_service.dart';
import '../services/background_comment_service.dart';
import '../services/notes_service.dart';
import '../services/post_interaction_service.dart';
import '../components/comment_input_modal.dart';
import '../components/comment_item.dart';

// 评论管理器控制器-从post_view_page中分离出来的
class PostCommentManagerController {
  _PostCommentManagerState? _state;
  
  void _attach(_PostCommentManagerState state) {
    _state = state;
  }
  
  void _detach() {
    _state = null;
  }
  
  void showInputModal() => _state?._showInputModal();
  void submitComment() => _state?._submitComment();
  void cancelReply() => _state?._cancelReply();
  
  String? get replyingToCommentId => _state?._replyingToCommentId;
  String? get replyingToUserName => _state?._replyingToUserName;
}

class PostCommentManager extends StatefulWidget {
  final PostModel post;
  final String userNickname;
  final String userAvatarPlaceholder;
  final Color userAvatarColor;
  final String? userAvatarPath;
  final Color themeColor;
  final PostInteractionService interactionService;
  final Function(List<Map<String, dynamic>>) onCommentsUpdated;
  final PostCommentManagerController? controller;

  const PostCommentManager({
    super.key,
    required this.post,
    required this.userNickname,
    required this.userAvatarPlaceholder,
    required this.userAvatarColor,
    this.userAvatarPath,
    required this.themeColor,
    required this.interactionService,
    required this.onCommentsUpdated,
    this.controller,
  });

  @override
  State<PostCommentManager> createState() => _PostCommentManagerState();
}

class _PostCommentManagerState extends State<PostCommentManager> {
  // 评论相关状态
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  Map<String, bool> _commentLikes = {}; // 存储评论点赞状态
  String? _replyingToCommentId; // 当前回复的评论ID
  String? _replyingToUserName; // 当前回复的用户名
  
  // AI评论相关
  bool _isLoadingAIComments = false;
  StreamSubscription<List<Map<String, dynamic>>>? _commentStreamSubscription;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _loadExistingComments(); // 加载已有评论
    _setupCommentStream(); // 设置评论流监听
    _checkForInterruptedCommentGeneration(); // 检查并恢复被中断的评论生成任务
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _commentStreamSubscription?.cancel(); // 取消流订阅
    super.dispose();
  }

  // 加载已有评论
  Future<void> _loadExistingComments() async {
    try {
      final existingComments = await CommentService.getPostComments(widget.post.id);
      final savedLikes = await CommentService.getPostCommentLikes(widget.post.id);
      
      if (mounted) {
        setState(() {
          _comments = existingComments;
          // 加载已保存的点赞状态
          _commentLikes = Map<String, bool>.from(savedLikes);
          
          // 为没有点赞状态的评论初始化为false
          for (final comment in existingComments) {
            final commentId = comment['id'];
            if (commentId != null && commentId is String && !_commentLikes.containsKey(commentId)) {
              _commentLikes[commentId] = false;
            }
          }
        });
        
        // 通知父组件评论已更新
        widget.onCommentsUpdated(_comments);
      }
    } catch (e) {
      print('加载评论失败: $e');
    }
  }

  // 设置评论流监听
  void _setupCommentStream() {
    final commentStream = BackgroundCommentService.getCommentStream(widget.post.id);
    if (commentStream != null) {
      _commentStreamSubscription = commentStream.listen((comments) {
        if (mounted) {
          print('📱 收到评论更新，评论数: ${comments.length}');
          setState(() {
            _comments = comments;
            // 初始化新评论的点赞状态
            for (final comment in comments) {
              final commentId = comment['id'];
              if (commentId != null && commentId is String && !_commentLikes.containsKey(commentId)) {
                _commentLikes[commentId] = false; // 默认未点赞
              }
            }
            // 更新加载状态：只根据后台任务是否停止来判断
            final isGenerating = BackgroundCommentService.isGeneratingComments(widget.post.id);
            _isLoadingAIComments = isGenerating;
            print('🔄 更新加载状态: isGenerating=$isGenerating, commentsCount=${comments.length}, _isLoadingAIComments=$_isLoadingAIComments');
          });
          // 更新帖子数据中的评论
          _updatePostComments(comments);
          // 通知父组件评论已更新
          widget.onCommentsUpdated(comments);
        }
      });
    } else {
      // 只在调试模式下打印，避免正常使用时的日志干扰
      // print('⚠️ 无法获取评论流，postId: ${widget.post.id}');
    }
  }

  // 检查并恢复被中断的评论生成任务
  Future<void> _checkForInterruptedCommentGeneration() async {
    // 检查是否有被中断的评论生成任务
    final isGenerating = await CommentService.getCommentGenerationStatus(widget.post.id);
    final hasBackgroundTask = BackgroundCommentService.isGeneratingComments(widget.post.id);

    // 只有在状态显示正在生成但没有后台任务时，才重新启动（恢复中断的任务）
    if (isGenerating && !hasBackgroundTask) {
      print('🔄 恢复被中断的评论生成任务: ${widget.post.id}');
      await BackgroundCommentService.startCommentGeneration(widget.post);
      _setupCommentStream(); // 重新设置流监听
      
      if (mounted) {
        setState(() {
          _isLoadingAIComments = true;
        });
        
        // 启动交互功能
        widget.interactionService.startInteractiveFeatures();
      }
    } else if (isGenerating && hasBackgroundTask) {
      // 任务正在运行中，只需要设置UI状态（不打印日志，避免重复输出）
      if (mounted) {
        setState(() {
          _isLoadingAIComments = true;
        });
        
        widget.interactionService.startInteractiveFeatures();
      }
    }
  }

  // 更新帖子评论数据
  void _updatePostComments(List<Map<String, dynamic>> comments) async {
    try {
      final updatedPost = widget.post.copyWith(
        comments: comments,
        isGeneratingComments: BackgroundCommentService.isGeneratingComments(widget.post.id),
      );
      
      // 更新笔记中的帖子数据
      await NotesService.savePostAsNote(updatedPost);
    } catch (e) {
      print('更新帖子评论失败: $e');
    }
  }

  // 切换评论点赞状态
  void _toggleCommentLike(String commentId) async {
    setState(() {
      final commentIndex = _comments.indexWhere((comment) => comment['id'] == commentId);
      if (commentIndex != -1) {
        // 确保commentId在_commentLikes中有值，如果没有则初始化为false
        _commentLikes[commentId] = !(_commentLikes[commentId] ?? false);
        
        // 确保likes字段是int类型，如果为null则初始化为0
        final currentLikes = _comments[commentIndex]['likes'] ?? 0;
        if (_commentLikes[commentId]!) {
          _comments[commentIndex]['likes'] = (currentLikes as int) + 1;
        } else {
          _comments[commentIndex]['likes'] = (currentLikes as int) - 1;
        }
      }
    });

    // 保存点赞状态到持久化存储
    try {
      // 更新评论到持久化存储
      final commentIndex = _comments.indexWhere((comment) => comment['id'] == commentId);
      if (commentIndex != -1) {
        await CommentService.updateCommentInPost(widget.post.id, _comments[commentIndex]);
      }
      
      // 保存点赞状态
      await CommentService.saveCommentLikeStatus(widget.post.id, commentId, _commentLikes[commentId] ?? false);
    } catch (e) {
      print('保存点赞状态失败: $e');
    }
  }

  // 回复评论
  void _replyToComment(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    _showInputModal(); // 显示输入模态框而不是只聚焦输入框
  }

  // 聚焦评论输入框
  void _focusCommentInput() {
    _commentFocusNode.requestFocus();
  }

  // 提交评论
  void _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      // 如果是回复评论
      if (_replyingToCommentId != null) {
        // 创建回复对象
        final reply = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': commentText,
          'name': widget.userNickname,
          'author': widget.userNickname,
          'avatar': widget.userAvatarPath ?? '',
          'avatarPlaceholder': widget.userAvatarPlaceholder,
          'avatarColor': widget.userAvatarColor.value,
          'timestamp': DateTime.now().toIso8601String(),
          'isAI': false,
          'likes': 0,
          'replyTo': _replyingToCommentId!,
          'replyToUser': _replyingToUserName!,
          'isMyComment': true,
        };

        // 找到被回复的评论并添加回复
        setState(() {
          final commentIndex = _comments.indexWhere((comment) => comment['id'] == _replyingToCommentId);
          if (commentIndex != -1) {
            // 确保replies数组存在并且类型正确
            if (_comments[commentIndex]['replies'] == null) {
              _comments[commentIndex]['replies'] = <Map<String, dynamic>>[];
            }
            // 安全地获取replies数组
            final replies = _comments[commentIndex]['replies'] as List;
            final repliesTyped = replies.cast<Map<String, dynamic>>();
            // 添加回复到原评论的replies数组中
            repliesTyped.add(reply);
            
            // 初始化回复的点赞状态
            final replyId = reply['id'];
            if (replyId != null && replyId is String) {
              _commentLikes[replyId] = false;
            }
          }
          
          _commentController.clear();
          _replyingToCommentId = null;
          _replyingToUserName = null;
        });

        // 保存到持久化存储
        await CommentService.savePostComments(widget.post.id, _comments);
      } else {
        // 创建普通评论
        final userComment = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': commentText,
          'name': widget.userNickname,
          'author': widget.userNickname,
          'avatar': widget.userAvatarPath ?? '',
          'avatarPlaceholder': widget.userAvatarPlaceholder,
          'avatarColor': widget.userAvatarColor.value,
          'timestamp': DateTime.now().toIso8601String(),
          'isAI': false,
          'likes': 0,
          'replies': <Map<String, dynamic>>[],
          'isMyComment': true,
        };

        // 保存到持久化存储
        await CommentService.addCommentToPost(widget.post.id, userComment);
        
        // 立即更新UI
        setState(() {
          _comments.add(userComment);
          // 初始化新评论的点赞状态
          final commentId = userComment['id'];
          if (commentId != null && commentId is String) {
            _commentLikes[commentId] = false;
          }
          _commentController.clear();
        });
      }

      // 更新帖子数据
      _updatePostComments(_comments);
      // 通知父组件评论已更新
      widget.onCommentsUpdated(_comments);

      _commentFocusNode.unfocus();
    } catch (e) {
      print('提交评论失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论发送失败，请重试')),
        );
      }
    }
  }

  // 取消回复
  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  // 显示输入模态框
  void _showInputModal() {
    CommentInputModal.show(
      context: context,
      controller: _commentController,
      replyingToCommentId: _replyingToCommentId,
      replyingToUserName: _replyingToUserName,
      themeColor: widget.themeColor,
      onSubmit: _submitComment,
      onCancelReply: _cancelReply,
    );
  }

  // 删除评论
  Future<void> _deleteComment(String commentId) async {
    try {
      setState(() {
        // 首先尝试删除顶级评论
        bool found = false;
        _comments.removeWhere((comment) {
          if (comment['id'] == commentId) {
            found = true;
            return true;
          }
          return false;
        });
        
        // 如果不是顶级评论，则在回复中查找并删除
        if (!found) {
          for (final comment in _comments) {
            if (comment['replies'] != null) {
              final replies = comment['replies'] as List;
              final repliesTyped = replies.cast<Map<String, dynamic>>();
              repliesTyped.removeWhere((reply) => reply['id'] == commentId);
            }
          }
        }
        
        // 移除点赞状态
        _commentLikes.remove(commentId);
      });

      // 更新持久化存储
      await CommentService.savePostComments(widget.post.id, _comments);
      
      // 更新帖子数据
      _updatePostComments(_comments);
      // 通知父组件评论已更新
      widget.onCommentsUpdated(_comments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论已删除')),
        );
      }
    } catch (e) {
      print('删除评论失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除评论失败，请重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 评论区标题
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '评论',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 评论列表
        _comments.isEmpty && !_isLoadingAIComments
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '还没有评论，快来抢沙发吧！',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // 现有评论列表
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return CommentItem(
                        comment: comment,
                        commentLikes: _commentLikes,
                        userNickname: widget.userNickname,
                        userAvatarPlaceholder: widget.userAvatarPlaceholder,
                        userAvatarColor: widget.userAvatarColor,
                        themeColor: widget.themeColor,
                        onToggleLike: _toggleCommentLike,
                        onReply: _replyToComment,
                        onDelete: _deleteComment,
                      );
                    },
                  ),
                  
                  // AI评论加载状态
                  if (_isLoadingAIComments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.themeColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '有人正在评论...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ],
    );
  }
} 