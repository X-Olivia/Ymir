import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/user_service.dart';
import '../services/post_interaction_service.dart';
import '../components/post_view_ui_components.dart';
import '../components/post_comment_manager.dart';

class PostViewPage extends StatefulWidget {
  final PostModel? postData; // Post data
  final Color? themeColor; // Theme color parameter
  final VoidCallback? onBack; // Back callback

  const PostViewPage({super.key, this.postData, this.themeColor, this.onBack});

  @override
  State<PostViewPage> createState() => PostViewPageState();
}

class PostViewPageState extends State<PostViewPage> {
  // User information
  String _userNickname = 'Username';
  String _userAvatarPlaceholder = 'U';
  Color _userAvatarColor = Colors.blue;
  String? _userAvatarPath; // Avatar path
  bool _isLoadingUserInfo = true;
  
  // Current image carousel page index
  int _currentImageIndex = 0;
  late PageController _pageController;
  
  // Interaction state
  bool _isLiked = false;
  int _likeCount = 42;
  bool _isCollected = false;
  
  // Comment data (updated by the comment manager)
  List<Map<String, dynamic>> _comments = [];
  
  // Interaction service
  late PostInteractionService _interactionService;
  
  // Comment manager controller
  final PostCommentManagerController _commentController = PostCommentManagerController();

  // Get the theme color
  Color get themeColor => widget.themeColor ?? Theme.of(context).primaryColor;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeInteractionService();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _interactionService.dispose(); // Dispose of the interaction service
    super.dispose();
  }

  // Initialize the interaction service
  void _initializeInteractionService() {
    _interactionService = PostInteractionService(
      onLikeCountChanged: (newCount) {
        if (mounted) {
          setState(() {
            _likeCount = newCount;
          });
        }
      },
    );
  }

  // Load user information
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      setState(() {
        _userNickname = userInfo['nickname'];
        _userAvatarPlaceholder = userInfo['avatarPlaceholder'];
        _userAvatarColor = userInfo['avatarColor'];
        _userAvatarPath = userInfo['avatarPath']; // Load the avatar path
        _isLoadingUserInfo = false;
      });
    } catch (e) {
      print('Failed to load user information: $e');
      setState(() {
        _isLoadingUserInfo = false;
      });
    }
  }

  // Handle the comment update callback
  void _onCommentsUpdated(List<Map<String, dynamic>> comments) {
    setState(() {
      _comments = comments;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show an error page if no post data was provided
    if (widget.postData == null || !widget.postData!.isValid) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Post data not found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final post = widget.postData!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info section
            PostViewUIComponents.buildUserInfoSection(
              isLoadingUserInfo: _isLoadingUserInfo,
              userNickname: _userNickname,
              userAvatarPlaceholder: _userAvatarPlaceholder,
              userAvatarColor: _userAvatarColor,
              userAvatarPath: _userAvatarPath,
              createdAt: post.createdAt,
              source: post.source,
              sourceName: post.sourceName,
              formatDate: _formatDate,
              getSourceColor: _getSourceColor,
            ),

            // Post content
            PostViewUIComponents.buildPostContent(
              title: post.title,
              description: post.description,
              topics: post.topics,
              images: post.images,
              themeColor: themeColor,
              pageController: _pageController,
              currentImageIndex: _currentImageIndex,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            ),

            // Comment manager
            PostCommentManager(
              post: post,
              userNickname: _userNickname,
              userAvatarPlaceholder: _userAvatarPlaceholder,
              userAvatarColor: _userAvatarColor,
              userAvatarPath: _userAvatarPath,
              themeColor: themeColor,
              interactionService: _interactionService,
              onCommentsUpdated: _onCommentsUpdated,
              controller: _commentController,
            ),
            
            // Bottom padding for the fixed interaction bar
            const SizedBox(height: 100),
          ],
        ),
      ),
      // Interaction bar fixed at the bottom
      bottomNavigationBar: PostViewUIComponents.buildBottomInteractionBar(
        replyingToCommentId: _commentController.replyingToCommentId,
        replyingToUserName: _commentController.replyingToUserName,
        themeColor: themeColor,
        isLiked: _isLiked,
        likeCount: _likeCount,
        isCollected: _isCollected,
        onToggleLike: _toggleLike,
        onToggleCollect: _toggleCollect,
        onShowInputModal: _commentController.showInputModal,
        onSubmitComment: _commentController.submitComment,
        onCancelReply: _commentController.cancelReply,
      ),
    );
  }

  // Format the date
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Get the source color
  Color _getSourceColor(PostSource source) {
    switch (source) {
      case PostSource.imagePost:
        return Colors.blue;
      case PostSource.captionSuggest:
        return Colors.purple;
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });
  }

  void _toggleCollect() {
    setState(() {
      _isCollected = !_isCollected;
    });
  }
} 