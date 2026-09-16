import 'dart:math';
import '../models/chat_model.dart';
import '../services/ai_service.dart';
import '../services/groq_api_service.dart';

/// Chat service
class ChatService {
  static ChatSession? _currentSession;
  static List<Map<String, dynamic>> _selectedAIFriends = [];

  /// Initialize chat service
  static Future<void> init() async {
    _selectedAIFriends = await AIService.getSelectedAIFriends();
  }

  /// Get current chat session
  static ChatSession? get currentSession => _currentSession;

  /// Create new chat session
  static Future<ChatSession> createNewSession() async {
    // Get selected AI friends
    _selectedAIFriends = await AIService.getSelectedAIFriends();
    
    final participants = _selectedAIFriends.map((ai) => ai['name'] as String).toList();
    participants.insert(0, 'Me'); // Add the user
    
    _currentSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Group chat (${participants.length} participants)',
      messages: [],
      participants: participants,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    return _currentSession!;
  }

  /// Send user message
  static ChatMessage sendUserMessage(String content) {
    if (_currentSession == null) {
      throw Exception('No active chat session');
    }

    final message = ChatMessage.user(content: content);
    _currentSession = _currentSession!.addMessage(message);
    
    return message;
  }

  /// Generate AI replies using the live AI API
  static Future<List<ChatMessage>> generateAIReplies(String userMessage) async {
    if (_currentSession == null || _selectedAIFriends.isEmpty) {
      return [];
    }

    final replies = <ChatMessage>[];
    
    // Randomly select 1–3 AI characters to reply
    final shuffledAIs = List<Map<String, dynamic>>.from(_selectedAIFriends)..shuffle();
    final replyCount = min(3, max(1, Random().nextInt(3) + 1));
    final replyingAIs = shuffledAIs.take(replyCount).toList();

    // Get the most recent conversation context (up to 10 messages)
    final recentMessages = _currentSession!.messages.length > 10 
        ? _currentSession!.messages.sublist(_currentSession!.messages.length - 10)
        : _currentSession!.messages;

    // Generate each AI reply asynchronously without waiting for all of them
    for (int i = 0; i < replyingAIs.length; i++) {
      final ai = replyingAIs[i];
      
      // Generate one AI reply asynchronously
      _generateSingleAIReply(userMessage, ai, recentMessages, i);
    }

    return replies; // An empty list is returned immediately, the actual reply is handled via a callback
  }

  /// Generate a single AI reply asynchronously
  static Future<void> _generateSingleAIReply(
    String userMessage, 
    Map<String, dynamic> ai, 
    List<ChatMessage> recentMessages,
    int index
  ) async {
    // Simulate AI thinking time
    await Future.delayed(Duration(milliseconds: 800 + index * 500));
    
    try {
      // Generate a reply with the live AI API
      final reply = await _generateSmartAIReply(userMessage, ai, recentMessages);
      final message = ChatMessage.ai(
        content: reply,
        aiName: ai['name'],
        aiAvatar: ai['avatar'] ?? '',
        aiColor: ai['avatarColor'],
      );
      
      // Add to conversation now
      _currentSession = _currentSession!.addMessage(message);
      
      // Notify the UI through the callback or state management
      _notifyMessageAdded?.call(message);
      
    } catch (e) {
      // Use a fallback reply if the API call fails
      print('AI reply generation failed; using a fallback reply: $e');
      final fallbackReply = _generateFallbackReply(userMessage, ai);
      final message = ChatMessage.ai(
        content: fallbackReply,
        aiName: ai['name'],
        aiAvatar: ai['avatar'] ?? '',
        aiColor: ai['avatarColor'],
      );
      
      // Add to conversation now
      _currentSession = _currentSession!.addMessage(message);
      
      // Notify the UI
      _notifyMessageAdded?.call(message);
    }
  }

  /// Message add callback
  static Function(ChatMessage)? _notifyMessageAdded;

  /// Set message add callback
  static void setMessageAddedCallback(Function(ChatMessage) callback) {
    _notifyMessageAdded = callback;
  }

  /// Clear message add callback
  static void clearMessageAddedCallback() {
    _notifyMessageAdded = null;
  }

  /// Generate an intelligent reply with the AI API
  static Future<String> _generateSmartAIReply(
    String userMessage, 
    Map<String, dynamic> ai, 
    List<ChatMessage> recentMessages
  ) async {
    final aiName = ai['name'] as String;
    final personality = ai['personality'] as String;
    
    // Build conversation context
    String contextPrompt = _buildContextPrompt(recentMessages, aiName);
    
    // Build the character prompt
    String characterPrompt = _buildCharacterPrompt(aiName, personality);
    
    // Choose whether to reply to the user or another AI character
    String targetPrompt = _buildTargetPrompt(userMessage, recentMessages, aiName);
  
    
    // Combine the complete prompt
    String fullPrompt = '''$characterPrompt

$contextPrompt

$targetPrompt

IMPORTANT NOTE:
1. You are participating in a group chat; reply in a natural, conversational tone
2. Do not use quotation marks around your reply
3. Just say what you want to say, just like you would in a normal chat
4. Replies should be concise and natural, no more than 50 characters
5. Use a style that matches the $aiName character

Please reply directly without quotation marks or other formatting symbols.''';

    // Call the Groq API
    final response = await GroqApiService.sendTextRequest(
      message: fullPrompt,
      characterName: 'Chaos Primarch Y', // Use the default character configuration
    );

    if (response.success && response.content?.isNotEmpty == true) {
      String reply = response.content!.trim();
      
      // Clean up replies and remove possible quotes
      reply = reply.replaceAll(RegExp(r'^"'), ''); // Remove opening quotes
      reply = reply.replaceAll(RegExp(r'"$'), ''); // Remove trailing quotes
      reply = reply.replaceAll(RegExp(r'^"'), ''); // Remove an opening typographic quote
      reply = reply.replaceAll(RegExp(r'"$'), ''); // Remove a trailing typographic quote
      
      return reply;
    } else {
      throw Exception('API call failed: ${response.error}');
    }
  }

  /// Build the conversation context prompt
  static String _buildContextPrompt(List<ChatMessage> recentMessages, String currentAI) {
    if (recentMessages.isEmpty) return 'This is the start of the conversation.';
    
    StringBuffer context = StringBuffer('Recent conversation:\n');
    
    // Show only recent 5 messages as context
    final contextMessages = recentMessages.length > 5 
        ? recentMessages.sublist(recentMessages.length - 5)
        : recentMessages;
    
    for (final msg in contextMessages) {
      if (msg.senderName != currentAI) { // Do not include your previous messages
        context.writeln('${msg.senderName}: ${msg.content}');
      }
    }
    
    return context.toString();
  }

  /// Build the character persona prompt
  static String _buildCharacterPrompt(String aiName, String personality) {
    final characterTraits = {
      'Chaos Primarch Y': 'You are Chaos Primarch Y. You approach problems from unusual angles, speak with wit and humor, and often offer surprising insights.',
      'Burn Without Consequences': 'You are Burn Without Consequences: passionate, impulsive, and direct. You encourage others to act boldly.',
      'Subzero Social Circle': 'You are Subzero Social Circle: calm, rational, and quick to temper enthusiasm by pointing out flaws and risks.',
      'Soft Cuddle Ball': 'You are Soft Cuddle Ball: gentle and adorable, speaking sweetly with cute expressions and an affectionate tone.',
      'Middle-earth': 'You are Middle-earth. You notice details others miss and enjoy asking precise, thoughtful questions.',
      'King of Inner Conflict': 'You are the King of Inner Conflict. You often hold opposing views at once and struggle to choose between them.',
      'Clouded Mind': 'You are Clouded Mind. You speak with mystery and depth, leaving others with meaningful ideas to ponder.',
      'Canned Sky': 'You are Canned Sky. You see the big picture and speak with grandeur, confidence, and foresight.',
      'Ridgebone': 'You are Ridgebone. You think logically, support opinions with data and analysis, and speak in a clear, structured way.',
      'Beneath the Red Tide': 'You are Beneath the Red Tide. You are deeply emotional and easily moved, speaking with poetry and feeling.',
    };
    
    return characterTraits[aiName] ?? 'You are $aiName, $personality';
  }

  /// Build reply target prompts
  static String _buildTargetPrompt(String userMessage, List<ChatMessage> recentMessages, String currentAI) {
    // Reply to the user 70% of the time and another AI character 30% of the time
    final random = Random();
    final shouldReplyToUser = random.nextDouble() < 0.7;
    
    if (shouldReplyToUser || recentMessages.length <= 1) {
      return 'The user just said: "$userMessage". Please reply.';
    } else {
      // Find the most recent message from another AI character
      final otherAIMessages = recentMessages
          .where((msg) => !msg.isUser && msg.senderName != currentAI)
          .toList();
      
      if (otherAIMessages.isNotEmpty) {
        final targetMessage = otherAIMessages.last;
        return '${targetMessage.senderName} just said: "${targetMessage.content}". Please reply or comment.';
      } else {
        return 'The user just said: "$userMessage". Please reply.';
      }
    }
  }

  /// Generate a fallback reply when the API fails
  static String _generateFallbackReply(String userMessage, Map<String, dynamic> ai) {
    final aiName = ai['name'] as String;
    
    // Generate a reply matching the AI character's style
    switch (aiName) {
      case 'Chaos Primarch Y':
        return _generateChaosReply(userMessage);
      case 'Burn Without Consequences':
        return _generateFireReply(userMessage);
      case 'Subzero Social Circle':
        return _generateColdReply(userMessage);
      case 'Soft Cuddle Ball':
        return _generateSoftReply(userMessage);
      case 'Middle-earth':
        return _generateDetailReply(userMessage);
      case 'King of Inner Conflict':
        return _generateConflictReply(userMessage);
      case 'Clouded Mind':
        return _generateMysteriousReply(userMessage);
      case 'Canned Sky':
        return _generateSkyReply(userMessage);
      case 'Ridgebone':
        return _generateLogicalReply(userMessage);
      case 'Beneath the Red Tide':
        return _generateEmotionalReply(userMessage);
      default:
        return _generateDefaultReply(userMessage, aiName);
    }
  }

  // Keep the original reply generators as API fallbacks
  static String _generateChaosReply(String message) {
    final replies = [
      'From another perspective, this question is interesting...',
      'I think they’re all good, but this idea is more interesting',
      'This reminds me of an old story...',
      'Interesting, your perspective is unique',
      'Think from another angle, maybe the answer is right in front of you',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateFireReply(String message) {
    final replies = [
      'That’s it! Just do it!',
      'Hahaha, I like your idea!',
      'Now we’re fired up! I’m all for this!',
      'Don’t overthink it—go for it!',
      'That idea has attitude! I love it!',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateColdReply(String message) {
    final replies = [
      'Looking at it rationally, this idea has some problems...',
      'Calm down and think about the consequences first',
      'Hmm... I think we should probably let this one go.',
      'This idea... How should I put it? Creative, but not very practical.',
      'Let me play devil’s advocate: this could...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateSoftReply(String message) {
    final replies = [
      'Ahhh, what a cute idea!',
      'Hugs~ This idea feels so warm.',
      'Softly agree!',
      'I want to pinch your cheeks! This idea is so sweet.',
      'Cuddles~ I support your idea!',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateDetailReply(String message) {
    final replies = [
      'Wait, I noticed a detail...',
      'Your eyes were a little wandering when you were talking. Are you thinking about something else?',
      'There is something strange, why...',
      'I found an interesting detail',
      'If you look carefully, there is a problem here...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateConflictReply(String message) {
    final replies = [
      'M: It’s a good idea. W: But there are risks...',
      'On one hand, I support it; on the other, I’m worried...',
      'What should I do if the left brain says yes and the right brain says no?',
      'Support it! No, oppose it! Never mind—I’m neutral...',
      'This idea... I’m so torn!',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateMysteriousReply(String message) {
    final replies = [
      '...Interesting.',
      'The meaning behind this is worth pondering',
      'This appears to be the case, but in reality...',
      'Is what you said and what you thought the same thing?',
      'The fog disperses and the truth emerges...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateSkyReply(String message) {
    final replies = [
      'This idea feels cinematic!',
      'A mind as vast as the sky!',
      'I like the scale of this!',
      'Broad vision and big ideas!',
      'This is the grand feeling I want!',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateLogicalReply(String message) {
    final replies = [
      'From a logical perspective, the feasibility of this solution is 70%',
      'It is recommended to do a risk assessment first',
      'Data shows the idea has potential',
      'All things considered, I recommend plan B',
      'Rational analysis: 3 advantages, 2 disadvantages',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateEmotionalReply(String message) {
    final replies = [
      'This idea makes my heart flutter...',
      'Thoughts as gentle as ocean waves',
      'My emotions are affected by your words',
      'This atmosphere... so beautiful',
      'My heart melts with your thoughts',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateDefaultReply(String message, String aiName) {
    final replies = [
      'Interesting idea!',
      'I think you can try it',
      'This is a good idea',
      'Support your idea!',
      'Let me think...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  /// Clear current session
  static void clearSession() {
    _currentSession = null;
  }
} 