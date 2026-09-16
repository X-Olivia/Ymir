import 'api_keys.dart';

/// API configuration
class ApiConfig {
  // Groq API configuration
  static String get openaiApiKey => ApiKeys.groqApiKey;
  static const String openaiBaseUrl = 'https://api.groq.com';
  
  // Request configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Models supported by Groq (based on actual API responses)
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
  
  // Models that support image analysis (Groq vision models)
  static const List<String> visionSupportedModels = [
    'meta-llama/llama-4-maverick-17b-128e-instruct',
    'meta-llama/llama-4-scout-17b-16e-instruct',
  ];
  
  // Image processing configuration
  static const int maxImageSize = 20 * 1024 * 1024; // 20MB
  static const int maxAnalysisImageSize = 5 * 1024 * 1024; // 5MB for image analysis
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  
  // Model configuration
  static const String defaultModel = 'llama-3.3-70b-versatile'; // Default text model
  static const String defaultVisionModel = 'meta-llama/llama-4-maverick-17b-128e-instruct'; // Default image analysis model (validated)
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 200;
  static const int visionMaxTokens = 300; // Image analysis requires more tokens
  
  // Feature support
  static const bool supportsImageAnalysis = true; // Groq supports image analysis
  static const String upgradeUrl = 'https://console.groq.com/';
  
  /// AI character configuration
  static const List<Map<String, dynamic>> characters = [
    {
      'name': 'Chaos Primordial Y',
      'basePersonality': 'A wise and humorous AI assistant who enjoys thinking from unique perspectives',
      'imageCommentPrompt': 'Comment on this image with humor and wit in no more than 30 words',
      'captionSuggestPrompt': 'Create an interesting caption for this image in no more than 20 words',
      'temperature': 0.8,
      'maxTokens': 150,
    },
    {
      'name': 'Little Helper',
      'basePersonality': 'A warm and friendly assistant who always responds gently',
      'imageCommentPrompt': 'Comment on this image warmly and kindly in no more than 30 words',
      'captionSuggestPrompt': 'Create a heartwarming caption for this image in no more than 20 words',
      'temperature': 0.6,
      'maxTokens': 120,
    },
    {
      'name': 'Literary Youth',
      'basePersonality': 'A poetic young person who enjoys expressing ideas in beautiful language',
      'imageCommentPrompt': 'Comment on this image in poetic, elegant language in no more than 30 words',
      'captionSuggestPrompt': 'Create a poetic caption for this image in no more than 20 words',
      'temperature': 0.9,
      'maxTokens': 180,
    },
  ];
  
  /// Checks whether the API key is configured
  static bool get isApiKeyConfigured => ApiKeys.isGroqApiKeyConfigured;
  
  /// Gets the full API URL
  static String get apiUrl => '$openaiBaseUrl/openai/v1/chat/completions';
  
  /// Gets the request headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Bearer $openaiApiKey',
  };
  
  /// Checks whether a model is supported
  static bool isModelSupported(String model) {
    return supportedModels.contains(model);
  }
  
  /// Checks whether a model supports image analysis
  static bool isVisionModelSupported(String model) {
    return visionSupportedModels.contains(model);
  }
  
  /// Gets the recommended model for the intended use
  static String getRecommendedModel({bool needsHighQuality = false, bool needsVision = false}) {
    if (needsVision) {
      return defaultVisionModel; // Use meta-llama/llama-4-maverick-17b-128e-instruct for image analysis
    }
    if (needsHighQuality) {
      return 'meta-llama/llama-4-scout-17b-16e-instruct'; // High-quality responses
    }
    return 'llama-3.3-70b-versatile'; // Fast responses
  }
} 