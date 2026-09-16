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

  // User avatar information
  String? _userAvatarPath;
  String _userAvatarPlaceholder = 'U';
  Color _userAvatarColor = Colors.blue;

  // Get the current theme color
  Color get _themeColor => widget.themeColor ?? Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    
    // Set the AI reply callback
    ChatService.setMessageAddedCallback(_onAIMessageAdded);
  }

  @override
  void dispose() {
    // Clear the callback
    ChatService.clearMessageAddedCallback();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize chat
  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize the chat service
      await ChatService.init();
      
      // Get user avatar information
      await _loadUserAvatarInfo();
      
      // Get selected AI friends
      _selectedAIFriends = await AIService.getSelectedAIFriends();
      
      // Create a new chat session
      _currentSession = await ChatService.createNewSession();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Send a welcome message
      _sendWelcomeMessage();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to initialize chat: $e');
    }
  }

  /// Load user avatar information
  Future<void> _loadUserAvatarInfo() async {
    try {
      final userInfo = await UserService.getUserInfo();
      setState(() {
        _userAvatarPath = userInfo['avatarPath'];
        _userAvatarPlaceholder = userInfo['avatarPlaceholder'] ?? 'U';
        _userAvatarColor = userInfo['avatarColor'] ?? Colors.blue;
      });
    } catch (e) {
      print('Failed to load user avatar information: $e');
    }
  }

  /// Send a welcome message
  void _sendWelcomeMessage() {
    if (_selectedAIFriends.isNotEmpty) {
      final welcomeAI = _selectedAIFriends.first;
      final welcomeMessage = ChatMessage.ai(
        content: 'Hi everyone! Welcome to the group chat. What would you like to talk about?',
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

  /// Callback invoked when an AI message is added
  void _onAIMessageAdded(ChatMessage message) {
    if (mounted) {
      setState(() {
        _currentSession = ChatService.currentSession;
      });
      _scrollToBottom();
    }
  }

  /// Send a message
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentSession == null) return;

    // Clear the input field
    _messageController.clear();

    // Send the user message
    final userMessage = ChatService.sendUserMessage(content);
    setState(() {
      _currentSession = ChatService.currentSession;
    });

    _scrollToBottom();

    // Show the loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Start generating AI replies asynchronously
      await ChatService.generateAIReplies(content);
      
      // Hide the loading state after allowing time for AI replies
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
      _showErrorSnackBar('Failed to send message: $e');
    }
  }

  /// Scroll to the bottom
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

  /// Show an error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Build a message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar (left)
          if (!isUser) ...[
            _buildAvatar(message),
            const SizedBox(width: 8),
          ],
          
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name
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
                
                // Message bubble
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
                
                // Timestamp
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
          
          // User avatar (right)
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  /// Build an AI avatar
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

  /// Build the user avatar
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

  /// Format a timestamp
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Build the input area
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
            // Input field
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
                    hintText: 'Type a message...',
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
            
            // Send button
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

  /// Build the group member list
  Widget _buildParticipantsList() {
    if (_selectedAIFriends.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 60, // Reduced because names are hidden
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _selectedAIFriends.length + 1, // +1 for user
        itemBuilder: (context, index) {
          if (index == 0) {
            // Current user - use the avatar from user settings
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
          _currentSession?.title ?? 'Group Chat',
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
                // Message list
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
                                'Start chatting!',
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
                
                // Loading indicator
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
                          'AI is thinking...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Input area
                _buildInputArea(),
              ],
            ),
    );
  }
} 