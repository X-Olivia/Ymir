import 'dart:math';
import '../models/chat_model.dart';
import '../services/ai_service.dart';
import '../services/groq_api_service.dart';

/// 聊天服务
class ChatService {
  static ChatSession? _currentSession;
  static List<Map<String, dynamic>> _selectedAIFriends = [];

  /// 初始化聊天服务
  static Future<void> init() async {
    _selectedAIFriends = await AIService.getSelectedAIFriends();
  }

  /// 获取当前聊天会话
  static ChatSession? get currentSession => _currentSession;

  /// 创建新的聊天会话
  static Future<ChatSession> createNewSession() async {
    // 获取选中的AI好友
    _selectedAIFriends = await AIService.getSelectedAIFriends();
    
    final participants = _selectedAIFriends.map((ai) => ai['name'] as String).toList();
    participants.insert(0, '我'); // 添加用户自己
    
    _currentSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '群聊 (${participants.length}人)',
      messages: [],
      participants: participants,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    return _currentSession!;
  }

  /// 发送用户消息
  static ChatMessage sendUserMessage(String content) {
    if (_currentSession == null) {
      throw Exception('没有活跃的聊天会话');
    }

    final message = ChatMessage.user(content: content);
    _currentSession = _currentSession!.addMessage(message);
    
    return message;
  }

  /// 生成AI回复 - 升级版本，使用真实AI API
  static Future<List<ChatMessage>> generateAIReplies(String userMessage) async {
    if (_currentSession == null || _selectedAIFriends.isEmpty) {
      return [];
    }

    final replies = <ChatMessage>[];
    
    // 随机选择1-3个AI进行回复
    final shuffledAIs = List<Map<String, dynamic>>.from(_selectedAIFriends)..shuffle();
    final replyCount = min(3, max(1, Random().nextInt(3) + 1));
    final replyingAIs = shuffledAIs.take(replyCount).toList();

    // 获取最近的对话上下文（最多10条消息）
    final recentMessages = _currentSession!.messages.length > 10 
        ? _currentSession!.messages.sublist(_currentSession!.messages.length - 10)
        : _currentSession!.messages;

    // 异步生成每个AI的回复，不等待全部完成
    for (int i = 0; i < replyingAIs.length; i++) {
      final ai = replyingAIs[i];
      
      // 异步生成单个AI回复
      _generateSingleAIReply(userMessage, ai, recentMessages, i);
    }

    return replies; // 立即返回空列表，实际回复通过回调处理
  }

  /// 生成单个AI回复（异步处理）
  static Future<void> _generateSingleAIReply(
    String userMessage, 
    Map<String, dynamic> ai, 
    List<ChatMessage> recentMessages,
    int index
  ) async {
    // 模拟AI思考时间
    await Future.delayed(Duration(milliseconds: 800 + index * 500));
    
    try {
      // 使用真实AI API生成回复
      final reply = await _generateSmartAIReply(userMessage, ai, recentMessages);
      final message = ChatMessage.ai(
        content: reply,
        aiName: ai['name'],
        aiAvatar: ai['avatar'] ?? '',
        aiColor: ai['avatarColor'],
      );
      
      // 立即添加到会话中
      _currentSession = _currentSession!.addMessage(message);
      
      // 通知UI更新（通过回调或状态管理）
      _notifyMessageAdded?.call(message);
      
    } catch (e) {
      // 如果API调用失败，使用备用回复
      print('AI回复生成失败，使用备用回复: $e');
      final fallbackReply = _generateFallbackReply(userMessage, ai);
      final message = ChatMessage.ai(
        content: fallbackReply,
        aiName: ai['name'],
        aiAvatar: ai['avatar'] ?? '',
        aiColor: ai['avatarColor'],
      );
      
      // 立即添加到会话中
      _currentSession = _currentSession!.addMessage(message);
      
      // 通知UI更新
      _notifyMessageAdded?.call(message);
    }
  }

  /// 消息添加回调
  static Function(ChatMessage)? _notifyMessageAdded;

  /// 设置消息添加回调
  static void setMessageAddedCallback(Function(ChatMessage) callback) {
    _notifyMessageAdded = callback;
  }

  /// 清除消息添加回调
  static void clearMessageAddedCallback() {
    _notifyMessageAdded = null;
  }

  /// 使用AI API生成智能回复
  static Future<String> _generateSmartAIReply(
    String userMessage, 
    Map<String, dynamic> ai, 
    List<ChatMessage> recentMessages
  ) async {
    final aiName = ai['name'] as String;
    final personality = ai['personality'] as String;
    
    // 构建对话上下文
    String contextPrompt = _buildContextPrompt(recentMessages, aiName);
    
    // 构建角色人设提示
    String characterPrompt = _buildCharacterPrompt(aiName, personality);
    
    // 决定回复目标（用户消息 vs 其他AI消息）
    String targetPrompt = _buildTargetPrompt(userMessage, recentMessages, aiName);
  
    
    // 组合完整提示
    String fullPrompt = '''$characterPrompt

$contextPrompt

$targetPrompt

重要提示：
1. 你现在正在参与一个群聊对话，请用自然的聊天语气回复
2. 不要使用引号包围你的回复内容
3. 直接说出你想说的话，就像平时聊天一样
4. 回复要简洁自然，不超过50字
5. 用符合${aiName}角色特点的语言风格

请直接回复，不要加引号或其他格式符号。''';

    // 调用Groq API
    final response = await GroqApiService.sendTextRequest(
      message: fullPrompt,
      characterName: '混沌原体Y', // 使用默认角色配置
    );

    if (response.success && response.content?.isNotEmpty == true) {
      String reply = response.content!.trim();
      
      // 清理回复内容，移除可能的引号
      reply = reply.replaceAll(RegExp(r'^"'), ''); // 移除开头的引号
      reply = reply.replaceAll(RegExp(r'"$'), ''); // 移除结尾的引号
      reply = reply.replaceAll(RegExp(r'^"'), ''); // 移除开头的中文引号
      reply = reply.replaceAll(RegExp(r'"$'), ''); // 移除结尾的中文引号
      
      return reply;
    } else {
      throw Exception('API调用失败: ${response.error}');
    }
  }

  /// 构建对话上下文提示
  static String _buildContextPrompt(List<ChatMessage> recentMessages, String currentAI) {
    if (recentMessages.isEmpty) return '这是对话的开始。';
    
    StringBuffer context = StringBuffer('最近的对话内容：\n');
    
    // 只显示最近5条消息作为上下文
    final contextMessages = recentMessages.length > 5 
        ? recentMessages.sublist(recentMessages.length - 5)
        : recentMessages;
    
    for (final msg in contextMessages) {
      if (msg.senderName != currentAI) { // 不包括自己之前的消息
        context.writeln('${msg.senderName}: ${msg.content}');
      }
    }
    
    return context.toString();
  }

  /// 构建角色人设提示
  static String _buildCharacterPrompt(String aiName, String personality) {
    final characterTraits = {
      '混沌原体Y': '你是混沌原体Y，喜欢从独特角度思考问题，语言风趣幽默，经常有出人意料的见解。',
      '烧起来不顾后果': '你是烧起来不顾后果，性格热血冲动，说话直接爽快，喜欢鼓励别人勇敢行动。',
      '零下社交圈': '你是零下社交圈，性格冷静理性，喜欢泼冷水，会指出计划中的问题和风险。',
      '松软贴贴球': '你是松软贴贴球，性格温柔可爱，说话甜腻，喜欢用可爱的语气和表情。',
      '中土': '你是中土，善于观察细节，会注意到别人忽略的小地方，喜欢提出细致的问题。',
      '左右互搏王': '你是左右互搏王，内心矛盾纠结，经常表达相互冲突的观点，难以做决定。',
      '阴云之脑': '你是阴云之脑，说话神秘深沉，喜欢说一些意味深长的话，给人思考的空间。',
      '天空罐头': '你是天空罐头，格局宏大，喜欢从大局角度看问题，说话有气势和远见。',
      '山脊之骨': '你是山脊之骨，逻辑思维强，喜欢用数据和分析来支持观点，说话条理清晰。',
      '红潮之下': '你是红潮之下，情感丰富，容易被感动，说话充满诗意和情感色彩。',
    };
    
    return characterTraits[aiName] ?? '你是$aiName，$personality';
  }

  /// 构建回复目标提示
  static String _buildTargetPrompt(String userMessage, List<ChatMessage> recentMessages, String currentAI) {
    // 70%概率回复用户消息，30%概率回复其他AI消息
    final random = Random();
    final shouldReplyToUser = random.nextDouble() < 0.7;
    
    if (shouldReplyToUser || recentMessages.length <= 1) {
      return '用户刚刚说："$userMessage"，请对此进行回复。';
    } else {
      // 找到最近的非用户消息（其他AI的消息）
      final otherAIMessages = recentMessages
          .where((msg) => !msg.isUser && msg.senderName != currentAI)
          .toList();
      
      if (otherAIMessages.isNotEmpty) {
        final targetMessage = otherAIMessages.last;
        return '${targetMessage.senderName}刚刚说："${targetMessage.content}"，请对此进行回复或评论。';
      } else {
        return '用户刚刚说："$userMessage"，请对此进行回复。';
      }
    }
  }

  /// 生成备用回复（API失败时使用）
  static String _generateFallbackReply(String userMessage, Map<String, dynamic> ai) {
    final aiName = ai['name'] as String;
    
    // 根据AI角色特点生成不同风格的回复
    switch (aiName) {
      case '混沌原体Y':
        return _generateChaosReply(userMessage);
      case '烧起来不顾后果':
        return _generateFireReply(userMessage);
      case '零下社交圈':
        return _generateColdReply(userMessage);
      case '松软贴贴球':
        return _generateSoftReply(userMessage);
      case '中土':
        return _generateDetailReply(userMessage);
      case '左右互搏王':
        return _generateConflictReply(userMessage);
      case '阴云之脑':
        return _generateMysteriousReply(userMessage);
      case '天空罐头':
        return _generateSkyReply(userMessage);
      case '山脊之骨':
        return _generateLogicalReply(userMessage);
      case '红潮之下':
        return _generateEmotionalReply(userMessage);
      default:
        return _generateDefaultReply(userMessage, aiName);
    }
  }

  // 保留原有的备用回复方法（作为API失败时的后备方案）
  static String _generateChaosReply(String message) {
    final replies = [
      '从另一个角度看，这个问题很有意思...',
      '我看，个个都好，但这个想法更有趣',
      '这让我想到了一个古老的故事...',
      '有意思，你的视角很独特',
      '换个角度思考，也许答案就在眼前',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateFireReply(String message) {
    final replies = [
      '就是这样！直接干就完了！',
      '哈哈哈，我喜欢你这个想法！',
      '燃起来了！这个必须支持！',
      '别想那么多，冲就对了！',
      '这个想法够拽！我喜欢！',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateColdReply(String message) {
    final replies = [
      '理性分析一下，这个想法有点问题...',
      '冷静点，先想想后果',
      'emmm...我觉得还是算了吧',
      '这个想法...怎么说呢，挺有创意的（但不太靠谱）',
      '拆台一下，这样做可能会...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateSoftReply(String message) {
    final replies = [
      '啊啊啊好可爱的想法！',
      '抱抱～这个想法很温暖呢',
      '软软的赞同！',
      '想捏脸！这个想法太甜了',
      '贴贴～支持你的想法',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateDetailReply(String message) {
    final replies = [
      '等等，我注意到一个细节...',
      '你说话的时候眼神有点飘，是在想别的吗？',
      '有个奇怪的地方，为什么...',
      '我发现了一个有趣的细节',
      '仔细观察的话，这里有个问题...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateConflictReply(String message) {
    final replies = [
      'M：这个想法不错；W：但是有风险...',
      '一方面支持，另一方面担心...',
      '左脑说可以，右脑说不行，怎么办？',
      '支持！不对，反对！算了，中立...',
      '这个想法...好纠结啊！',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateMysteriousReply(String message) {
    final replies = [
      '......有意思。',
      '这背后的含义，值得深思',
      '表面如此，实则...',
      '你说的，和你想的，是一回事吗？',
      '雾气散去，真相浮现...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateSkyReply(String message) {
    final replies = [
      '这个想法很有大场面的感觉！',
      '像天空一样广阔的思路！',
      '这个格局，我喜欢！',
      '视野开阔，想法宏大！',
      '这就是我要的大气感！',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateLogicalReply(String message) {
    final replies = [
      '从逻辑角度分析，这个方案可行性为70%',
      '建议先做风险评估',
      '数据显示这个想法有潜力',
      '综合考虑，建议采用方案B',
      '理性分析：优点3个，缺点2个',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateEmotionalReply(String message) {
    final replies = [
      '这个想法让我心潮澎湃...',
      '像海浪一样温柔的想法',
      '情绪被你的话语牵动了',
      '这氛围...太美了',
      '心都被你的想法融化了',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  static String _generateDefaultReply(String message, String aiName) {
    final replies = [
      '有趣的想法！',
      '我觉得可以试试',
      '这个想法不错呢',
      '支持你的想法！',
      '让我想想...',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  /// 清空当前会话
  static void clearSession() {
    _currentSession = null;
  }
} 