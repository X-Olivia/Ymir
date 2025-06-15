/// API密钥配置文件示例
/// 使用说明：
/// 1. 复制此文件为 api_keys.dart
/// 2. 将下面的占位符替换为你的实际API密钥
/// 3. api_keys.dart 文件已被添加到 .gitignore，不会被提交到版本控制
class ApiKeys {
  // Groq API密钥
  // 获取地址：https://console.groq.com/keys
  static const String groqApiKey = 'your-groq-api-key-here';
  
  // OpenAI API密钥（如果需要）
  // 获取地址：https://platform.openai.com/api-keys
  static const String openaiApiKey = 'your-openai-api-key-here';
  
  // 其他API密钥可以在这里添加
  // static const String otherApiKey = 'your-other-api-key-here';
  
  /// 检查Groq API密钥是否已配置
  static bool get isGroqApiKeyConfigured => 
      groqApiKey.isNotEmpty && groqApiKey != 'your-groq-api-key-here';
  
  /// 检查OpenAI API密钥是否已配置
  static bool get isOpenaiApiKeyConfigured => 
      openaiApiKey.isNotEmpty && openaiApiKey != 'your-openai-api-key-here';
} 