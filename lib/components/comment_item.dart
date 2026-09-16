import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// UI component layer


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
              // Top drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Share option
              ListTile(
                leading: Icon(Icons.share, color: themeColor),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareComment(context);
                },
              ),
              // Copy option
              ListTile(
                leading: Icon(Icons.copy, color: themeColor),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  _copyComment(context);
                },
              ),
              // Delete option
              ListTile(
                leading: Icon(Icons.delete, color: themeColor),
                title: Text('Delete'),
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
          content: Text('Comment copied to clipboard'),
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
          content: Text('Share comment: $content'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(comment['id']);
            },
            child: Text('Delete', style: TextStyle(color: themeColor)),
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
                        comment['name'] ?? 'Anonymous User',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment['content'] ?? 'Deleted',
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
                          onTap: () => onReply(commentId, comment['name'] ?? 'Anonymous User'),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Displays replies
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
      // AI character avatar
      final avatarColor = comment['avatarColor'] != null 
          ? Color(comment['avatarColor']) 
          : Colors.blue;
      final avatarPath = comment['avatar'];
      
      // Displays the image when an avatar path exists; otherwise displays text
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
                // Displays a text avatar if the image fails to load
                return Text(
                  comment['name']?[0] ?? 'A',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        );
      } else {
        // Displays a text avatar when no avatar path exists
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

  // Gets the formatted time display
  String _getFormattedTime() {
    final timestampStr = comment['timestamp'];
    if (timestampStr != null && timestampStr.toString().isNotEmpty) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        return _formatTimestamp(timestamp);
      } catch (e) {
        print('Failed to parse timestamp: $e');
      }
    }
    
    // Falls back to the time field when no timestamp exists or parsing fails
    return comment['time'] ?? 'Unknown time';
  }

  // Formats a timestamp
  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
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
          // Avatar
          _buildReplyAvatar(),
          const SizedBox(width: 8),
          // Reply content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply['name'] ?? 'Anonymous User',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reply['replyToUser'] != null) ...[
                      const Text(' replied to ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(
                        reply['replyToUser'] ?? 'someone',
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
                  reply['content'] ?? 'Deleted',
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
                          'Delete',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600], // Consistent with time colours
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

  // Builds the reply avatar
  Widget _buildReplyAvatar() {
    final isMyReply = reply['isMyComment'] == true || reply['name'] == userNickname;
    
    if (isMyReply) {
      // Avatar for the user's own reply
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
      // Uses a text avatar when no avatar path is available
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

  // Gets the formatted reply time
  String _getReplyFormattedTime() {
    final timestampStr = reply['timestamp'];
    if (timestampStr != null && timestampStr.toString().isNotEmpty) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        return _formatReplyTimestamp(timestamp);
      } catch (e) {
        print('Failed to parse reply timestamp: $e');
      }
    }
    
    // Falls back to the time field when no timestamp exists or parsing fails
    return reply['time'] ?? 'Unknown time';
  }

  // Formats a reply timestamp
  String _formatReplyTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
} 