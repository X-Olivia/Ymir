import 'package:flutter/material.dart';

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final String senderName;
  final String senderAvatar;
  final Color senderColor;
  final DateTime timestamp;
  final bool isUser; // Whether the user sent the message

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.senderAvatar,
    required this.senderColor,
    required this.timestamp,
    required this.isUser,
  });

  /// Creates a user message
  factory ChatMessage.user({
    required String content,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderName: 'Me',
      senderAvatar: '',
      senderColor: Colors.blue,
      timestamp: DateTime.now(),
      isUser: true,
    );
  }

  /// Creates an AI message
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

/// Chat session model
class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final List<String> participants; // List of participant names
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

  /// Adds a message
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

  /// Gets the last message
  ChatMessage? get lastMessage {
    return messages.isNotEmpty ? messages.last : null;
  }
} 