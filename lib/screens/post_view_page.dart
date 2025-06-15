import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/user_service.dart';
import '../services/post_interaction_service.dart';
import '../components/post_view_ui_components.dart';
import '../components/post_comment_manager.dart';

class PostViewPage extends StatefulWidget {
  final PostModel? postData; // 接收帖子数据
  final Color? themeColor; // 添加主题色参数
  final VoidCallback? onBack; // 添加返回回调

  const PostViewPage({super.key, this.postData, this.themeColor, this.onBack});

  @override
  State<PostViewPage> createState() => PostViewPageState();
}

class PostViewPageState extends State<PostViewPage> {
  // 用户信息
  String _userNickname = '用户昵称';
  String _userAvatarPlaceholder = 'U';
  Color _userAvatarColor = Colors.blue;
  String? _userAvatarPath; // 添加头像路径
  bool _isLoadingUserInfo = true;
  
  // 图片轮播当前页面索引
  int _currentImageIndex = 0;
  late PageController _pageController;
  
  // 交互状态
  bool _isLiked = false;
  int _likeCount = 42;
  bool _isCollected = false;
  
  // 评论数据（由评论管理器更新）
  List<Map<String, dynamic>> _comments = [];
  
  // 交互功能服务
  late PostInteractionService _interactionService;
  
  // 评论管理器控制器
  final PostCommentManagerController _commentController = PostCommentManagerController();

  // 获取主题色
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
    _interactionService.dispose(); // 清理交互服务
    super.dispose();
  }

  // 初始化交互服务
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

  // 加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      setState(() {
        _userNickname = userInfo['nickname'];
        _userAvatarPlaceholder = userInfo['avatarPlaceholder'];
        _userAvatarColor = userInfo['avatarColor'];
        _userAvatarPath = userInfo['avatarPath']; // 加载头像路径
        _isLoadingUserInfo = false;
      });
    } catch (e) {
      print('加载用户信息失败: $e');
      setState(() {
        _isLoadingUserInfo = false;
      });
    }
  }

  // 处理评论更新回调
  void _onCommentsUpdated(List<Map<String, dynamic>> comments) {
    setState(() {
      _comments = comments;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有传递帖子数据，显示错误页面
    if (widget.postData == null || !widget.postData!.isValid) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '没有找到帖子数据',
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

            // 评论管理组件
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
            
            // 底部留白，为固定的交互栏留出空间
            const SizedBox(height: 100),
          ],
        ),
      ),
      // 固定在底部的交互栏
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

  // 格式化日期
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 获取来源颜色
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