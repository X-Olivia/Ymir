import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//UI组件层


class CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final Map<String, bool> commentLikes;
  final String userNickname;
  final String userAvatarPlaceholder;
  final Color userAvatarColor;
  final Color themeColor;
  final Function(String) onToggleLike;
  final Function(String, String) onReply;
  final Function(String)? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    required this.commentLikes,
    required this.userNickname,
    required this.userAvatarPlaceholder,
    required this.userAvatarColor,
    required this.themeColor,
    required this.onToggleLike,
    required this.onReply,
    this.onDelete,
  });

  void _showCommentOptions(BuildContext context, bool isMyComment) {
    if (!isMyComment) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖动条
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 分享选项
              ListTile(
                leading: Icon(Icons.share, color: themeColor),
                title: const Text('分享'),
                onTap: () {
                  Navigator.pop(context);
                  _shareComment(context);
                },
              ),
              // 复制选项
              ListTile(
                leading: Icon(Icons.copy, color: themeColor),
                title: const Text('复制'),
                onTap: () {
                  Navigator.pop(context);
                  _copyComment(context);
                },
              ),
              // 删除选项
              ListTile(
                leading: Icon(Icons.delete, color: themeColor),
                title: Text('删除'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _copyComment(BuildContext context) async {
    final content = comment['content'] ?? '';
    await Clipboard.setData(ClipboardData(text: content));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('评论已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareComment(BuildContext context) {
    final content = comment['content'] ?? '';
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享评论: $content'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(comment['id']);
            },
            child: Text('删除', style: TextStyle(color: themeColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentId = comment['id'];
    final isLiked = commentLikes[commentId] ?? false;
    final isMyComment = comment['isMyComment'] == true || comment['name'] == userNickname;
    final isAIComment = comment['isAI'] == true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(isMyComment, isAIComment),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: isMyComment ? () => _showCommentOptions(context, isMyComment) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment['name'] ?? '匿名用户',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment['content'] ?? '内容已删除',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Row(
                      children: [
                        Text(
                          _getFormattedTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => onToggleLike(commentId),
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 14,
                                color: isLiked ? Colors.red : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (comment['likes'] ?? 0).toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => onReply(commentId, comment['name'] ?? '匿名用户'),
                          child: Text(
                            '回复',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 显示回复
                  if (comment['replies'] != null && comment['replies'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...comment['replies'].map<Widget>((reply) => ReplyItem(
                      reply: reply, 
                      themeColor: themeColor,
                      userNickname: userNickname,
                      onDelete: onDelete,
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isMyComment, bool isAIComment) {
    if (isMyComment) {
      final avatarPath = comment['avatar'];
      if (avatarPath != null && avatarPath.toString().isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundColor: userAvatarColor,
          child: ClipOval(
            child: Image.asset(
              avatarPath,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  userAvatarPlaceholder,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        );
      } else {
        return CircleAvatar(
          radius: 16,
          backgroundColor: userAvatarColor,
          child: Text(
            userAvatarPlaceholder,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }
    } else {
      // AI角色头像
      final avatarColor = comment['avatarColor'] != null 
          ? Color(comment['avatarColor']) 
          : Colors.blue;
      final avatarPath = comment['avatar'];
      
      // 如果有头像路径，显示图片；否则显示文字
      if (avatarPath != null && avatarPath.toString().isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundColor: avatarColor,
          child: ClipOval(
            child: Image.asset(
              avatarPath,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 如果图片加载失败，显示文字头像
                return Text(
                  comment['name']?[0] ?? 'A',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        );
      } else {
        // 没有头像路径时显示文字头像
        return CircleAvatar(
          radius: 16,
          backgroundColor: avatarColor,
          child: Text(
            comment['name']?[0] ?? 'A',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }
    }
  }

  // 获取格式化的时间显示
  String _getFormattedTime() {
    final timestampStr = comment['timestamp'];
    if (timestampStr != null && timestampStr.toString().isNotEmpty) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        return _formatTimestamp(timestamp);
      } catch (e) {
        print('解析时间戳失败: $e');
      }
    }
    
    // 如果没有timestamp或解析失败，使用time字段作为后备
    return comment['time'] ?? '未知时间';
  }

  // 格式化时间戳
  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}

class ReplyItem extends StatelessWidget {
  final Map<String, dynamic> reply;
  final Color themeColor;
  final String userNickname;
  final Function(String)? onDelete;

  const ReplyItem({
    super.key,
    required this.reply,
    required this.themeColor,
    required this.userNickname,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMyReply = reply['isMyComment'] == true || reply['name'] == userNickname;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          _buildReplyAvatar(),
          const SizedBox(width: 8),
          // 回复内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply['name'] ?? '匿名用户',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reply['replyToUser'] != null) ...[
                      const Text(' 回复 ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(
                        reply['replyToUser'] ?? '某人',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply['content'] ?? '内容已删除',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getReplyFormattedTime(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isMyReply && onDelete != null) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => onDelete?.call(reply['id']),
                        child: Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600], // 与时间颜色保持一致
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建回复头像
  Widget _buildReplyAvatar() {
    final isMyReply = reply['isMyComment'] == true || reply['name'] == userNickname;
    
    if (isMyReply) {
      // 用户自己的回复头像
      final avatarPath = reply['avatar'];
      if (avatarPath != null && avatarPath.toString().isNotEmpty) {
        return CircleAvatar(
          radius: 12,
          backgroundColor: reply['avatarColor'] != null ? Color(reply['avatarColor']) : Colors.blue,
          child: ClipOval(
            child: Image.asset(
              avatarPath,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  reply['avatarPlaceholder'] ?? reply['name']?[0] ?? 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
        );
      } else {
        return CircleAvatar(
          radius: 12,
          backgroundColor: reply['avatarColor'] != null ? Color(reply['avatarColor']) : Colors.blue,
          child: Text(
            reply['avatarPlaceholder'] ?? reply['name']?[0] ?? 'U',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        );
      }
    } else {
      // AI角色的回复头像
      final avatarColor = reply['avatarColor'] != null 
          ? Color(reply['avatarColor']) 
          : Colors.blue;
      final avatarPath = reply['avatar'];
      
      if (avatarPath != null && avatarPath.toString().isNotEmpty) {
        return CircleAvatar(
          radius: 12,
          backgroundColor: avatarColor,
          child: ClipOval(
            child: Image.asset(
              avatarPath,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  reply['name']?[0] ?? 'A',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
        );
      } else {
        return CircleAvatar(
          radius: 12,
          backgroundColor: avatarColor,
          child: Text(
            reply['name']?[0] ?? 'A',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        );
      }
    }
  }

  // 获取回复的格式化时间显示
  String _getReplyFormattedTime() {
    final timestampStr = reply['timestamp'];
    if (timestampStr != null && timestampStr.toString().isNotEmpty) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        return _formatReplyTimestamp(timestamp);
      } catch (e) {
        print('解析回复时间戳失败: $e');
      }
    }
    
    // 如果没有timestamp或解析失败，使用time字段作为后备
    return reply['time'] ?? '未知时间';
  }

  // 格式化回复时间戳
  String _formatReplyTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
} 