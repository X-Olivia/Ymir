/// Example API key configuration file
/// Instructions:
/// 1. Copy this file to api_keys.dart
/// 2. Replace the placeholders below with your actual API keys
/// 3. api_keys.dart is listed in .gitignore and will not be committed to version control
class ApiKeys {
  // Groq API key
  // Get one at: https://console.groq.com/keys
  static const String groqApiKey = 'your-groq-api-key-here';
  
  // OpenAI API key (if needed)
  // Get one at: https://platform.openai.com/api-keys
  static const String openaiApiKey = 'your-openai-api-key-here';
  
  // Other API keys can be added here
  // static const String otherApiKey = 'your-other-api-key-here';
  
  /// Checks whether the Groq API key is configured
  static bool get isGroqApiKeyConfigured => 
      groqApiKey.isNotEmpty && groqApiKey != 'your-groq-api-key-here';
  
  /// Checks whether the OpenAI API key is configured
  static bool get isOpenaiApiKeyConfigured => 
      openaiApiKey.isNotEmpty && openaiApiKey != 'your-openai-api-key-here';
} 