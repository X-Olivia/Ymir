import 'package:flutter/material.dart';
import '../services/ai_service.dart';
// Comment modal component


class CommentInputModal extends StatefulWidget {
  final TextEditingController controller;
  final String? replyingToCommentId;
  final String? replyingToUserName;
  final Color themeColor;
  final VoidCallback onSubmit;
  final VoidCallback onCancelReply;

  const CommentInputModal({
    super.key,
    required this.controller,
    this.replyingToCommentId,
    this.replyingToUserName,
    required this.themeColor,
    required this.onSubmit,
    required this.onCancelReply,
  });

  static void show({
    required BuildContext context,
    required TextEditingController controller,
    String? replyingToCommentId,
    String? replyingToUserName,
    required Color themeColor,
    required VoidCallback onSubmit,
    required VoidCallback onCancelReply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentInputModal(
        controller: controller,
        replyingToCommentId: replyingToCommentId,
        replyingToUserName: replyingToUserName,
        themeColor: themeColor,
        onSubmit: onSubmit,
        onCancelReply: onCancelReply,
      ),
    );
  }

  @override
  State<CommentInputModal> createState() => _CommentInputModalState();
}

class _CommentInputModalState extends State<CommentInputModal> {
  List<Map<String, dynamic>> _aiFriends = [];
  bool _showEmojiKeyboard = false;
  bool _showAIFriendsList = false;
  
  // Frequently used emoji
  final List<String> _emojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
    '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
    '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
    '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
    '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
    '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯',
    '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
    '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈',
    '👿', '👹', '👺', '🤡', '💩', '👻', '💀', '☠️', '👽', '👾',
    '🤖', '🎃', '😺', '😸', '😹', '😻', '😼', '😽', '🙀', '😿',
    '😾', '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️',
    '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️',
    '👍', '👎', '👊', '✊', '🤛', '🤜', '👏', '🙌', '👐', '🤝',
    '🙏', '✍️', '💅', '🤳', '💪', '🦾', '🦿', '🦵', '🦶', '👂',
    '🦻', '👃', '🧠', '🫀', '🫁', '🦷', '🦴', '👀', '👁️', '👅'
  ];

  @override
  void initState() {
    super.initState();
    _loadAIFriends();
  }

  Future<void> _loadAIFriends() async {
    final friends = await AIService.getSelectedAIFriends();
    setState(() {
      _aiFriends = friends;
    });
  }

  void _insertAtSymbol() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, '@');
    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );
    
    setState(() {
      _showAIFriendsList = true;
    });
  }

  void _insertAIFriend(String friendName) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    // Finds the last @ sign
    final lastAtIndex = text.lastIndexOf('@', selection.start - 1);
    if (lastAtIndex != -1) {
      final beforeAt = text.substring(0, lastAtIndex);
      final afterCursor = text.substring(selection.start);
      final newText = '$beforeAt@$friendName $afterCursor';
      
      widget.controller.value = widget.controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: lastAtIndex + friendName.length + 2),
      );
    }
    
    setState(() {
      _showAIFriendsList = false;
    });
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
                
                // Reply hint (if any)
                if (widget.replyingToCommentId != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to ${widget.replyingToUserName}',
                            style: TextStyle(
                              color: widget.themeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            widget.onCancelReply();
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: widget.themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // First row: input field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      autofocus: true,
                      maxLines: null,
                      onChanged: (text) {
                        setState(() {
                          // Checks whether @ was entered
                          if (text.endsWith('@')) {
                            _showAIFriendsList = true;
                          } else if (!text.contains('@')) {
                            _showAIFriendsList = false;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: widget.replyingToCommentId != null 
                            ? 'Reply to ${widget.replyingToUserName}...'
                            : 'Say something...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (widget.controller.text.trim().isNotEmpty) {
                          widget.onSubmit();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
                
                // AI friend list (when visible)
                if (_showAIFriendsList && _aiFriends.isNotEmpty) ...[
                  Container(
                    height: 140,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: _aiFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _aiFriends[index];
                        return GestureDetector(
                          onTap: () => _insertAIFriend(friend['name']),
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: friend['avatarColor'],
                                  child: ClipOval(
                                    child: Image.asset(
                                      friend['avatar'] ?? '',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Text(
                                          friend['name'][0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  friend['name'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                // Emoji keyboard (when visible)
                if (_showEmojiKeyboard) ...[
                  Container(
                    height: 200,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _emojis.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _insertEmoji(_emojis[index]),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _emojis[index],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                // Second row: function buttons and send button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // @ button
                      _buildFunctionButton(
                        icon: Icons.alternate_email,
                        onTap: _insertAtSymbol,
                      ),
                      const SizedBox(width: 16),
                      
                      // Emoji button
                      _buildFunctionButton(
                        icon: _showEmojiKeyboard ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        onTap: () {
                          setState(() {
                            _showEmojiKeyboard = !_showEmojiKeyboard;
                            if (_showEmojiKeyboard) {
                              _showAIFriendsList = false;
                            }
                          });
                        },
                      ),
                      
                      const Spacer(),
                      
                      // Send button
                      GestureDetector(
                        onTap: () {
                          if (widget.controller.text.trim().isNotEmpty) {
                            widget.onSubmit();
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.controller.text.trim().isEmpty 
                                ? Colors.grey[300] 
                                : widget.themeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Send',
                            style: TextStyle(
                              color: widget.controller.text.trim().isEmpty 
                                  ? Colors.grey[600] 
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
      ),
    );
  }
} 