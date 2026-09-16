# YMIR - AI-Powered Social Content Creation Assistant

<div align="center">
  <img src="assets/images/User/IMG_6339.PNG" alt="YMIR Logo" width="120" height="120">
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?style=flat&logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.8.1+-0175C2?style=flat&logo=dart)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-Private-red?style=flat)](LICENSE)
</div>

## 📖 Overview

YMIR is an AI-powered social content creation assistant built with Flutter. It integrates multiple AI characters to provide image analysis, caption suggestions, intelligent comments, and other features that help users create more engaging social media content.

### ✨ Key Features

- 🤖 **10 Unique AI Characters** - Each has a distinct personality and voice
- 📸 **Intelligent Image Analysis** - In-depth analysis of content, composition, color, and more
- ✍️ **AI Caption Suggestions** - Personalized caption ideas based on image content
- 💬 **Intelligent Comment System** - AI characters automatically generate engaging comments
- 📝 **Draft Management** - Save and manage work in progress
- 📚 **Saved Notes** - Save favorite content and AI suggestions
- 🎨 **Personalized Themes** - Choose from multiple theme colors
- 💾 **Local Data Storage** - Keep data secure with the Hive database

## 🏗️ Project Architecture

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration
├── screens/                  # Presentation layer
│   ├── splash_screen.dart    # Splash screen
│   ├── main_screen.dart      # Main screen
│   ├── image_post_page.dart  # Image post page
│   ├── caption_suggest_page.dart # Caption suggestions page
│   ├── ai_character_select_page.dart # AI character selection page
│   ├── chat_page.dart        # Chat page
│   ├── user_settings_page.dart # User settings page
│   └── ...
├── services/                 # Service layer
│   ├── ai_service_manager.dart # AI service management
│   ├── image_analysis_service.dart # Image analysis service
│   ├── openai_api_service.dart # OpenAI API service
│   ├── groq_api_service.dart # Groq API service
│   ├── draft_service.dart    # Draft service
│   ├── notes_service.dart    # Notes service
│   ├── chat_service.dart     # Chat service
│   └── ...
├── models/                   # Data models
│   ├── post_model.dart       # Post model
│   ├── draft_model.dart      # Draft model
│   ├── chat_model.dart       # Chat model
│   └── ...
├── components/               # Component layer
│   ├── comment_input_modal.dart # Comment input component
│   ├── post_comment_manager.dart # Post comment management
│   └── ...
├── widgets/                  # Custom widgets
│   ├── floating_nav_bar.dart # Floating navigation bar
│   ├── water_glass_widget.dart # Water glass animation widget
│   ├── color_slider_widget.dart # Color slider widget
│   └── ...
├── config/                   # Configuration files
│   ├── api_config.dart       # API configuration
│   └── ai_characters_config.dart # AI character configuration
├── utils/                    # Utilities
└── constants/                # Constants
```

## 🤖 AI Characters

YMIR includes 10 unique AI characters, each with a different personality and voice:

| Character | Personality | Voice |
|---------|---------|---------|
| 🌌 Primordial Chaos Y | Mysterious philosopher | Considers different perspectives; philosophical without being pretentious |
| 🔥 Burn Without Consequence | Extremely enthusiastic | Bursting with energy, like three cups of coffee |
| ❄️ Subzero Social Circle | Rational and direct | Straightforward, honest, calm, and objective |
| 🧸 Soft Cuddle Ball | Gentle and adorable | Sweet and warm, like an affectionate little animal |
| 🔍 Middle-earth | Detail observer | Spots subtle details others miss |
| ⚖️ King of Inner Debate | Deliberative and balanced | Always finds balance amid competing impulses |
| 🌫️ Clouded Mind | Mysterious riddler | Hazy and abstract, always leaving something unsaid |
| 📷 Canned Sky | Photography enthusiast | Evaluates visuals with impact and vivid imagery |
| 🏔️ Ridgebone | Rational analyst | Clear logic, precise wording, and concise delivery |
| 🌊 Beneath the Red Tide | Emotionally perceptive | Romantic and expressive, like waves gently touching the heart |

## 🚀 Main Features

### 📸 Image Posting and Analysis
- Upload and preview multiple images
- In-depth AI analysis of image content, composition, color, and more
- Intelligent title and description suggestions
- Smart hashtag recommendations

### ✍️ Caption Suggestions
- Generate personalized captions from image content
- Receive suggestions in different styles from multiple AI characters
- Customize topics and descriptions
- Preview and edit in real time

### 💬 Intelligent Comment System
- AI characters automatically generate engaging comments
- Users can interact with AI characters
- Comment styles match character personalities
- Intelligent background comment generation

### 📝 Content Management
- **Drafts**: Save unfinished content
- **Notebook**: Save favorite posts and AI suggestions
- **History**: View all creation history
- **Data Sync**: Store data securely on the device

### 🎨 Personalization
- Multiple theme colors
- AI character preferences
- Customizable user profile
- Privacy settings management

## 🛠️ Technology Stack

### Front-End Framework
- **Flutter 3.8.1+** - Cross-platform UI framework
- **Dart 3.8.1+** - Programming language

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # UI components
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.9
  
  # Permission management
  permission_handler: ^11.3.0
  
  # Image selection
  wechat_assets_picker: ^9.5.1
  photo_manager: ^3.6.0
  
  # Data storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
  
  # Network requests
  http: ^1.1.0
  
  # Cryptography
  crypto: ^3.0.3
  
  # System integration
  android_intent_plus: ^4.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
  flutter_launcher_icons: ^0.13.1
```

### AI Service Integration
- **OpenAI GPT-4 Vision** - Image analysis and text generation
- **Groq API** - High-speed AI inference service
- **Custom AI Service Manager** - Unified management of multiple AI services

### Data Storage
- **Hive** - High-performance local database
- **SharedPreferences** - User preferences
- **Local File System** - Image and media file storage

## 📱 Supported Platforms

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12.0+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Windows** (Windows 10+)
- ✅ **Linux** (Ubuntu 18.04+)
- ✅ **Web** (modern browsers)

## 🚀 Quick Start

### Requirements
- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Android Studio / VS Code
- Git

### Installation

1. **Clone the Project**
```bash
git clone <repository-url>
cd ymir
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Generate Code**
```bash
flutter packages pub run build_runner build
```

4. **Configure API Keys**
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String openaiApiKey = 'your-openai-api-key';
  static const String groqApiKey = 'your-groq-api-key';
  // ... Other configuration
}
```

5. **Run the App**
```bash
flutter run
```

### Build a Release

**Android APK**
```bash
flutter build apk --release
```

**iOS IPA**
```bash
flutter build ios --release
```

**Desktop Apps**
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 📁 Project Structure

### Core Modules

#### 🎯 Services
- `AIServiceManager`: Unified AI service management
- `ImageAnalysisService`: Core image analysis service
- `DraftService`: Draft management service
- `NotesService`: Notes management service
- `ChatService`: Chat service

#### 📊 Data Models
- `PostModel`: Post data model
- `DraftModel`: Draft data model with Hive persistence
- `ChatModel`: Chat message model

#### 🎨 UI Widgets
- `FloatingNavBar`: Floating navigation bar
- `WaterGlassWidget`: Water sphere animation widget
- `ColorSliderWidget`: Color selection slider
- `TopicSelectorWidget`: Topic selector

#### ⚙️ Configuration
- `AICharactersConfig`: AI character configuration management
- `ApiConfig`: API service configuration

## 🔧 Development Guide

### Add a New AI Character

1. Add the character configuration to `lib/config/ai_characters_config.dart`:
```dart
AICharacterConfig(
  name: 'New Character Name',
  description: 'Character description',
  basePersonality: 'Base personality',
  imageCommentPrompt: 'Image comment prompt',
  captionSuggestPrompt: 'Caption suggestion prompt',
  avatarColor: Colors.blue,
  avatar: 'assets/images/AI/new_character.png',
  temperature: 0.7,
  maxTokens: 200,
),
```

2. Add the character avatar to `assets/images/AI/`

3. Update the asset configuration in `pubspec.yaml`

### Customize the Theme

Modify the theme colors in `lib/screens/main_screen.dart`:
```dart
final List<Color> _themeColors = [
  const Color(0xFF2463b3), // Blue
  const Color(0xFFa18dc1), // Purple
  // Add more colors...
];
```

### Extend API Services

1. Create a new API service class that extends the base service
2. Register the new service with `AIServiceManager`
3. Update the relevant configuration files

## 🐛 Troubleshooting

### Q: The app crashes on startup
A: Verify that the API keys are configured correctly and all dependencies are installed.

### Q: Image analysis is not working
A: Confirm that the network connection works, the API key is valid, and sufficient API quota remains.

### Q: AI character avatars are not displayed
A: Check that the corresponding image files exist in `assets/images/AI/`.

### Q: Data loss
A: YMIR uses local storage, so data remains on the device. Uninstalling the app deletes all data.

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This is a private project. Unauthorized copying, distribution, or modification is prohibited.

---

<div align="center">
  <p>Built with ❤️ and Flutter</p>
  <p>© 2025 YMIR Team. All rights reserved.</p>
</div> 