import 'api_keys.dart';

/// API配置类
class ApiConfig {
  // Groq API配置
  static String get openaiApiKey => ApiKeys.groqApiKey;
  static const String openaiBaseUrl = 'https://api.groq.com';
  
  // 请求配置
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Groq支持的模型（基于实际API返回）
  static const List<String> supportedModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'llama3-70b-8192',
    'llama3-8b-8192',
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'meta-llama/llama-4-maverick-17b-128e-instruct',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
    'deepseek-r1-distill-llama-70b',
    'qwen-qwq-32b',
    'compound-beta',
    'mistral-saba-24b',
  ];
  
  // 支持图片分析的模型（Groq的视觉模型）
  static const List<String> visionSupportedModels = [
    'meta-llama/llama-4-maverick-17b-128e-instruct',
    'meta-llama/llama-4-scout-17b-16e-instruct',
  ];
  
  // 图片处理配置
  static const int maxImageSize = 20 * 1024 * 1024; // 20MB
  static const int maxAnalysisImageSize = 5 * 1024 * 1024; // 5MB for image analysis
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  
  // 模型配置
  static const String defaultModel = 'llama-3.3-70b-versatile'; // 默认文本模型
  static const String defaultVisionModel = 'meta-llama/llama-4-maverick-17b-128e-instruct'; // 图片分析默认模型（已验证）
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 200;
  static const int visionMaxTokens = 300; // 图片分析需要更多token
  
  // 功能支持状态
  static const bool supportsImageAnalysis = true; // Groq支持图片分析
  static const String upgradeUrl = 'https://console.groq.com/';
  
  /// AI角色配置
  static const List<Map<String, dynamic>> characters = [
    {
      'name': '混沌原体Y',
      'basePersonality': '智慧幽默的AI助手，喜欢从独特角度思考问题',
      'imageCommentPrompt': '请用幽默风趣的语言评论这张图片，不超过30字',
      'captionSuggestPrompt': '请为这张图片生成一个有趣的标题，不超过20字',
      'temperature': 0.8,
      'maxTokens': 150,
    },
    {
      'name': '小助手',
      'basePersonality': '温暖友善的助手，总是用温柔的语气回应',
      'imageCommentPrompt': '请用温暖友善的语言评论这张图片，不超过30字',
      'captionSuggestPrompt': '请为这张图片生成一个温馨的标题，不超过20字',
      'temperature': 0.6,
      'maxTokens': 120,
    },
    {
      'name': '文艺青年',
      'basePersonality': '富有诗意的文艺青年，喜欢用优美的语言表达',
      'imageCommentPrompt': '请用诗意优美的语言评论这张图片，不超过30字',
      'captionSuggestPrompt': '请为这张图片生成一个富有诗意的标题，不超过20字',
      'temperature': 0.9,
      'maxTokens': 180,
    },
  ];
  
  /// 检查API密钥是否已配置
  static bool get isApiKeyConfigured => ApiKeys.isGroqApiKeyConfigured;
  
  /// 获取完整的API URL
  static String get apiUrl => '$openaiBaseUrl/openai/v1/chat/completions';
  
  /// 获取请求头
  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Bearer $openaiApiKey',
  };
  
  /// 检查模型是否支持
  static bool isModelSupported(String model) {
    return supportedModels.contains(model);
  }
  
  /// 检查模型是否支持图片分析
  static bool isVisionModelSupported(String model) {
    return visionSupportedModels.contains(model);
  }
  
  /// 获取推荐模型（根据用途）
  static String getRecommendedModel({bool needsHighQuality = false, bool needsVision = false}) {
    if (needsVision) {
      return defaultVisionModel; // 图片分析使用meta-llama/llama-4-maverick-17b-128e-instruct
    }
    if (needsHighQuality) {
      return 'meta-llama/llama-4-scout-17b-16e-instruct'; // 高质量回复
    }
    return 'llama-3.3-70b-versatile'; // 快速回复
  }
} 