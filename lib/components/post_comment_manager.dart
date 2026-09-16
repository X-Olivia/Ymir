import 'package:flutter/material.dart';
import 'dart:async';
import '../models/post_model.dart';
import '../services/comment_service.dart';
import '../services/background_comment_service.dart';
import '../services/notes_service.dart';
import '../services/post_interaction_service.dart';
import '../components/comment_input_modal.dart';
import '../components/comment_item.dart';

// Comment manager controller extracted from post_view_page
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
  // Comment-related state
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  Map<String, bool> _commentLikes = {}; // Stores comment like states
  String? _replyingToCommentId; // ID of the comment being replied to
  String? _replyingToUserName; // Name of the user being replied to
  
  // AI comment state
  bool _isLoadingAIComments = false;
  StreamSubscription<List<Map<String, dynamic>>>? _commentStreamSubscription;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _loadExistingComments(); // Loads existing comments
    _setupCommentStream(); // Subscribes to the comment stream
    _checkForInterruptedCommentGeneration(); // Checks for and resumes interrupted comment generation
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _commentStreamSubscription?.cancel(); // Cancels the stream subscription
    super.dispose();
  }

  // Loads existing comments
  Future<void> _loadExistingComments() async {
    try {
      final existingComments = await CommentService.getPostComments(widget.post.id);
      final savedLikes = await CommentService.getPostCommentLikes(widget.post.id);
      
      if (mounted) {
        setState(() {
          _comments = existingComments;
          // Loads saved like states
          _commentLikes = Map<String, bool>.from(savedLikes);
          
          // Initializes missing comment like states to false
          for (final comment in existingComments) {
            final commentId = comment['id'];
            if (commentId != null && commentId is String && !_commentLikes.containsKey(commentId)) {
              _commentLikes[commentId] = false;
            }
          }
        });
        
        // Notifies the parent that comments were updated
        widget.onCommentsUpdated(_comments);
      }
    } catch (e) {
      print('Failed to load comments: $e');
    }
  }

  // Subscribes to the comment stream
  void _setupCommentStream() {
    final commentStream = BackgroundCommentService.getCommentStream(widget.post.id);
    if (commentStream != null) {
      _commentStreamSubscription = commentStream.listen((comments) {
        if (mounted) {
          print('📱 Comment update received, count: ${comments.length}');
          setState(() {
            _comments = comments;
            // Initializes like states for new comments
            for (final comment in comments) {
              final commentId = comment['id'];
              if (commentId != null && commentId is String && !_commentLikes.containsKey(commentId)) {
                _commentLikes[commentId] = false; // Not liked by default
              }
            }
            // Updates loading state based only on whether the background task has stopped
            final isGenerating = BackgroundCommentService.isGeneratingComments(widget.post.id);
            _isLoadingAIComments = isGenerating;
            print('🔄 Update loading state: isGenerating=$isGenerating, commentsCount=${comments.length}, _isLoadingAIComments=$_isLoadingAIComments');
          });
          // Updates comments in the post data
          _updatePostComments(comments);
          // Notifies the parent that comments were updated
          widget.onCommentsUpdated(comments);
        }
      });
    } else {
      // Logs only in debug mode to avoid noise during normal use
      // print('⚠️ Unable to get comment stream, postId: ${widget.post.id}');
    }
  }

  // Checks for and resumes interrupted comment generation
  Future<void> _checkForInterruptedCommentGeneration() async {
    // Checks for an interrupted comment generation task
    final isGenerating = await CommentService.getCommentGenerationStatus(widget.post.id);
    final hasBackgroundTask = BackgroundCommentService.isGeneratingComments(widget.post.id);

    // Restarts only when generation is marked active but no background task is running
    if (isGenerating && !hasBackgroundTask) {
      print('🔄 Resuming interrupted comment generation task: ${widget.post.id}');
      await BackgroundCommentService.startCommentGeneration(widget.post);
      _setupCommentStream(); // Resubscribes to the stream
      
      if (mounted) {
        setState(() {
          _isLoadingAIComments = true;
        });
        
        // Starts interactive features
        widget.interactionService.startInteractiveFeatures();
      }
    } else if (isGenerating && hasBackgroundTask) {
      // The task is running; only updates UI state to avoid duplicate logs
      if (mounted) {
        setState(() {
          _isLoadingAIComments = true;
        });
        
        widget.interactionService.startInteractiveFeatures();
      }
    }
  }

  // Updates post comment data
  void _updatePostComments(List<Map<String, dynamic>> comments) async {
    try {
      final updatedPost = widget.post.copyWith(
        comments: comments,
        isGeneratingComments: BackgroundCommentService.isGeneratingComments(widget.post.id),
      );
      
      // Updates the post data stored in the note
      await NotesService.savePostAsNote(updatedPost);
    } catch (e) {
      print('Failed to update post comments: $e');
    }
  }

  // Toggles a comment's like state
  void _toggleCommentLike(String commentId) async {
    setState(() {
      final commentIndex = _comments.indexWhere((comment) => comment['id'] == commentId);
      if (commentIndex != -1) {
        // Ensures commentId has a value in _commentLikes
        _commentLikes[commentId] = !(_commentLikes[commentId] ?? false);
        
        // Ensures the likes field is an int, defaulting to zero
        final currentLikes = _comments[commentIndex]['likes'] ?? 0;
        if (_commentLikes[commentId]!) {
          _comments[commentIndex]['likes'] = (currentLikes as int) + 1;
        } else {
          _comments[commentIndex]['likes'] = (currentLikes as int) - 1;
        }
      }
    });

    // Saves the like state to persistent storage
    try {
      // Updates the comment in persistent storage
      final commentIndex = _comments.indexWhere((comment) => comment['id'] == commentId);
      if (commentIndex != -1) {
        await CommentService.updateCommentInPost(widget.post.id, _comments[commentIndex]);
      }
      
      // Saves the like state
      await CommentService.saveCommentLikeStatus(widget.post.id, commentId, _commentLikes[commentId] ?? false);
    } catch (e) {
      print('Failed to save like status: $e');
    }
  }

  // Replies to a comment
  void _replyToComment(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    _showInputModal(); // Shows the input modal instead of only focusing the field
  }

  // Focuses the comment input field
  void _focusCommentInput() {
    _commentFocusNode.requestFocus();
  }

  // Submits a comment
  void _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      // Handles a reply
      if (_replyingToCommentId != null) {
        // Creates the reply object
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

        // Finds the target comment and adds the reply
        setState(() {
          final commentIndex = _comments.indexWhere((comment) => comment['id'] == _replyingToCommentId);
          if (commentIndex != -1) {
            // Ensures the replies array exists and has the correct type
            if (_comments[commentIndex]['replies'] == null) {
              _comments[commentIndex]['replies'] = <Map<String, dynamic>>[];
            }
            // Safely accesses the replies array
            final replies = _comments[commentIndex]['replies'] as List;
            final repliesTyped = replies.cast<Map<String, dynamic>>();
            // Adds the reply to the original comment
            repliesTyped.add(reply);
            
            // Initializes the reply's like state
            final replyId = reply['id'];
            if (replyId != null && replyId is String) {
              _commentLikes[replyId] = false;
            }
          }
          
          _commentController.clear();
          _replyingToCommentId = null;
          _replyingToUserName = null;
        });

        // Saves to persistent storage
        await CommentService.savePostComments(widget.post.id, _comments);
      } else {
        // Creates a top-level comment
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

        // Saves to persistent storage
        await CommentService.addCommentToPost(widget.post.id, userComment);
        
        // Updates the UI immediately
        setState(() {
          _comments.add(userComment);
          // Initializes the new comment's like state
          final commentId = userComment['id'];
          if (commentId != null && commentId is String) {
            _commentLikes[commentId] = false;
          }
          _commentController.clear();
        });
      }

      // Updates the post data
      _updatePostComments(_comments);
      // Notifies the parent that comments were updated
      widget.onCommentsUpdated(_comments);

      _commentFocusNode.unfocus();
    } catch (e) {
      print('Failed to submit comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send comment. Please try again.')),
        );
      }
    }
  }

  // Cancels the reply
  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  // Shows the input modal
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

  // Deletes a comment
  Future<void> _deleteComment(String commentId) async {
    try {
      setState(() {
        // First attempts to delete a top-level comment
        bool found = false;
        _comments.removeWhere((comment) {
          if (comment['id'] == commentId) {
            found = true;
            return true;
          }
          return false;
        });
        
        // Otherwise, finds and deletes it from the replies
        if (!found) {
          for (final comment in _comments) {
            if (comment['replies'] != null) {
              final replies = comment['replies'] as List;
              final repliesTyped = replies.cast<Map<String, dynamic>>();
              repliesTyped.removeWhere((reply) => reply['id'] == commentId);
            }
          }
        }
        
        // Removes its like state
        _commentLikes.remove(commentId);
      });

      // Updates persistent storage
      await CommentService.savePostComments(widget.post.id, _comments);
      
      // Updates the post data
      _updatePostComments(_comments);
      // Notifies the parent that comments were updated
      widget.onCommentsUpdated(_comments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      print('Failed to delete comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment, please try again')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comment section title
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Comments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Comment list
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
                        'No comments yet. Be the first to comment!',
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
                  // Existing comments
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
                  
                  // AI comment loading state
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
                            'Someone is commenting...',
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