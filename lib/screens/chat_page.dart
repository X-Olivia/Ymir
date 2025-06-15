import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/ai_service.dart';
import '../services/user_service.dart';

class ChatPage extends StatefulWidget {
  final Color? themeColor;

  const ChatPage({super.key, this.themeColor});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatSession? _currentSession;
  List<Map<String, dynamic>> _selectedAIFriends = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  // 用户头像相关信息
  String? _userAvatarPath;
  String _userAvatarPlaceholder = 'U';
  Color _userAvatarColor = Colors.blue;

  // 获取当前主题色
  Color get _themeColor => widget.themeColor ?? Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    
    // 设置AI回复回调
    ChatService.setMessageAddedCallback(_onAIMessageAdded);
  }

  @override
  void dispose() {
    // 清除回调
    ChatService.clearMessageAddedCallback();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化聊天
  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 初始化聊天服务
      await ChatService.init();
      
      // 获取用户头像信息
      await _loadUserAvatarInfo();
      
      // 获取选中的AI好友
      _selectedAIFriends = await AIService.getSelectedAIFriends();
      
      // 创建新的聊天会话
      _currentSession = await ChatService.createNewSession();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // 发送欢迎消息
      _sendWelcomeMessage();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('初始化聊天失败: $e');
    }
  }

  /// 加载用户头像信息
  Future<void> _loadUserAvatarInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      setState(() {
        _userAvatarPath = userInfo['avatarPath'];
        _userAvatarPlaceholder = userInfo['avatarPlaceholder'] ?? 'U';
        _userAvatarColor = userInfo['avatarColor'] ?? Colors.blue;
      });
    } catch (e) {
      print('加载用户头像信息失败: $e');
    }
  }

  /// 发送欢迎消息
  void _sendWelcomeMessage() {
    if (_selectedAIFriends.isNotEmpty) {
      final welcomeAI = _selectedAIFriends.first;
      final welcomeMessage = ChatMessage.ai(
        content: '大家好！欢迎来到群聊～有什么想聊的吗？',
        aiName: welcomeAI['name'],
        aiAvatar: welcomeAI['avatar'] ?? '',
        aiColor: welcomeAI['avatarColor'],
      );
      
      setState(() {
        _currentSession = _currentSession?.addMessage(welcomeMessage);
      });
      
      _scrollToBottom();
    }
  }

  /// AI消息添加回调
  void _onAIMessageAdded(ChatMessage message) {
    if (mounted) {
      setState(() {
        _currentSession = ChatService.currentSession;
      });
      _scrollToBottom();
    }
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentSession == null) return;

    // 清空输入框
    _messageController.clear();

    // 发送用户消息
    final userMessage = ChatService.sendUserMessage(content);
    setState(() {
      _currentSession = ChatService.currentSession;
    });

    _scrollToBottom();

    // 显示加载状态
    setState(() {
      _isLoading = true;
    });

    try {
      // 开始生成AI回复（异步，不等待完成）
      await ChatService.generateAIReplies(content);
      
      // 延迟一段时间后隐藏加载状态（给AI回复一些时间）
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('发送消息失败: $e');
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像（左侧）
          if (!isUser) ...[
            _buildAvatar(message),
            const SizedBox(width: 8),
          ],
          
          // 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 发送者名称
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // 消息气泡
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? _themeColor 
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                    border: isUser 
                        ? null 
                        : Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                
                // 时间戳
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 用户头像（右侧）
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  /// 构建AI头像
  Widget _buildAvatar(ChatMessage message) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: message.senderColor,
      ),
      child: message.senderAvatar.isNotEmpty
          ? ClipOval(
              child: Transform.translate(
                offset: const Offset(0, 2),
                child: Transform.scale(
                  scale: 1.1,
                  child: Image.asset(
                    message.senderAvatar,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: message.senderColor,
                        ),
                        child: Center(
                          child: Text(
                            message.senderName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                message.senderName[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  /// 构建用户头像
  Widget _buildUserAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _userAvatarPath == null ? _userAvatarColor : null,
      ),
      child: _userAvatarPath != null
          ? ClipOval(
              child: Transform.translate(
                offset: const Offset(0, 2),
                child: Transform.scale(
                  scale: 1.1,
                  child: Image.asset(
                    _userAvatarPath!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _userAvatarColor,
                        ),
                        child: Center(
                          child: Text(
                            _userAvatarPlaceholder,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _userAvatarPlaceholder,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 输入框
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 发送按钮
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _themeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建群成员列表
  Widget _buildParticipantsList() {
    if (_selectedAIFriends.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 60, // 减少高度，因为不显示名字了
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _selectedAIFriends.length + 1, // +1 for user
        itemBuilder: (context, index) {
          if (index == 0) {
            // 用户自己 - 使用用户设置的头像
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _userAvatarPath == null ? _userAvatarColor : null,
                ),
                child: _userAvatarPath != null
                    ? ClipOval(
                        child: Transform.translate(
                          offset: const Offset(0, 2),
                          child: Transform.scale(
                            scale: 1.1,
                            child: Image.asset(
                              _userAvatarPath!,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _userAvatarColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _userAvatarPlaceholder,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _userAvatarPlaceholder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            );
          }
          
          final ai = _selectedAIFriends[index - 1];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ai['avatarColor'],
              ),
              child: ai['avatar'] != null && ai['avatar'].isNotEmpty
                  ? ClipOval(
                      child: Transform.translate(
                        offset: const Offset(0, 2),
                        child: Transform.scale(
                          scale: 1.1,
                          child: Image.asset(
                            ai['avatar'],
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ai['avatarColor'],
                                ),
                                child: Center(
                                  child: Text(
                                    ai['name'][0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        ai['name'][0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _currentSession?.title ?? '群聊',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _themeColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildParticipantsList(),
        ),
      ),
      body: _isLoading && !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // 消息列表
                Expanded(
                  child: _currentSession == null || _currentSession!.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '开始聊天吧！',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _currentSession!.messages.length,
                          itemBuilder: (context, index) {
                            final message = _currentSession!.messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
                ),
                
                // 加载指示器
                if (_isLoading && _isInitialized)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI正在思考...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 输入区域
                _buildInputArea(),
              ],
            ),
    );
  }
} 