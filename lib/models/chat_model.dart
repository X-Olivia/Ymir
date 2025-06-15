import 'package:flutter/material.dart';

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final String senderName;
  final String senderAvatar;
  final Color senderColor;
  final DateTime timestamp;
  final bool isUser; // 是否是用户发送的消息

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.senderAvatar,
    required this.senderColor,
    required this.timestamp,
    required this.isUser,
  });

  /// 创建用户消息
  factory ChatMessage.user({
    required String content,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderName: '我',
      senderAvatar: '',
      senderColor: Colors.blue,
      timestamp: DateTime.now(),
      isUser: true,
    );
  }

  /// 创建AI消息
  factory ChatMessage.ai({
    required String content,
    required String aiName,
    required String aiAvatar,
    required Color aiColor,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderName: aiName,
      senderAvatar: aiAvatar,
      senderColor: aiColor,
      timestamp: DateTime.now(),
      isUser: false,
    );
  }
}

/// 聊天会话模型
class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final List<String> participants; // 参与者名称列表
  final DateTime createdAt;
  final DateTime lastMessageAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.participants,
    required this.createdAt,
    required this.lastMessageAt,
  });

  /// 添加消息
  ChatSession addMessage(ChatMessage message) {
    return ChatSession(
      id: id,
      title: title,
      messages: [...messages, message],
      participants: participants,
      createdAt: createdAt,
      lastMessageAt: message.timestamp,
    );
  }

  /// 获取最后一条消息
  ChatMessage? get lastMessage {
    return messages.isNotEmpty ? messages.last : null;
  }
} 