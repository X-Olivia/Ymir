# YMIR - AI驱动的社交内容创作助手

<div align="center">
  <img src="assets/images/User/IMG_6339.PNG" alt="YMIR Logo" width="120" height="120">
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?style=flat&logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.8.1+-0175C2?style=flat&logo=dart)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-Private-red?style=flat)](LICENSE)
</div>

## 📖 项目简介

YMIR是一款基于Flutter开发的AI驱动社交内容创作助手应用。它集成了多个AI角色，为用户提供图片分析、文案建议、智能评论等功能，帮助用户创作更有趣、更有吸引力的社交媒体内容。

### ✨ 核心特性

- 🤖 **10个独特AI角色** - 每个角色都有独特的性格和表达风格
- 📸 **智能图片分析** - 深度分析图片内容、构图、色彩等元素
- ✍️ **AI文案建议** - 根据图片内容生成个性化配文建议
- 💬 **智能评论系统** - AI角色自动生成有趣的评论互动
- 📝 **草稿管理** - 保存和管理创作中的内容
- 📚 **笔记收藏** - 收藏喜欢的内容和AI建议
- 🎨 **个性化主题** - 多种主题色彩可选
- 💾 **本地数据存储** - 使用Hive数据库确保数据安全

## 🏗️ 项目架构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用配置
├── screens/                  # 页面层
│   ├── splash_screen.dart    # 启动页
│   ├── main_screen.dart      # 主屏幕
│   ├── image_post_page.dart  # 图片发布页
│   ├── caption_suggest_page.dart # 文案建议页
│   ├── ai_character_select_page.dart # AI角色选择页
│   ├── chat_page.dart        # 聊天页面
│   ├── user_settings_page.dart # 用户设置页
│   └── ...
├── services/                 # 服务层
│   ├── ai_service_manager.dart # AI服务管理
│   ├── image_analysis_service.dart # 图片分析服务
│   ├── openai_api_service.dart # OpenAI API服务
│   ├── groq_api_service.dart # Groq API服务
│   ├── draft_service.dart    # 草稿服务
│   ├── notes_service.dart    # 笔记服务
│   ├── chat_service.dart     # 聊天服务
│   └── ...
├── models/                   # 数据模型
│   ├── post_model.dart       # 帖子模型
│   ├── draft_model.dart      # 草稿模型
│   ├── chat_model.dart       # 聊天模型
│   └── ...
├── components/               # 组件层
│   ├── comment_input_modal.dart # 评论输入组件
│   ├── post_comment_manager.dart # 帖子评论管理
│   └── ...
├── widgets/                  # 自定义组件
│   ├── floating_nav_bar.dart # 浮动导航栏
│   ├── water_glass_widget.dart # 水杯动画组件
│   ├── color_slider_widget.dart # 颜色滑块组件
│   └── ...
├── config/                   # 配置文件
│   ├── api_config.dart       # API配置
│   └── ai_characters_config.dart # AI角色配置
├── utils/                    # 工具类
└── constants/                # 常量定义
```

## 🤖 AI角色介绍

YMIR内置了10个独特的AI角色，每个都有不同的性格和表达风格：

| 角色名称 | 性格特点 | 表达风格 |
|---------|---------|---------|
| 🌌 混沌原体Y | 神秘哲学家 | 从不同角度看问题，有点哲学味但不装逼 |
| 🔥 烧起来不顾后果 | 超级热情 | 充满能量，像刚喝了三杯咖啡！ |
| ❄️ 零下社交圈 | 理性直接 | 不绕弯子，实话实说，冷静客观 |
| 🧸 松软贴贴球 | 温柔可爱 | 像小动物撒娇，甜甜的暖暖的 |
| 🔍 中土 | 细节观察家 | 善于发现别人没注意到的小细节 |
| ⚖️ 左右互搏王 | 纠结平衡 | 总是在拉扯中找到平衡点 |
| 🌫️ 阴云之脑 | 神秘谜语人 | 朦胧抽象，说一半留一半 |
| 📷 天空罐头 | 摄影发烧友 | 从视觉角度评价，有冲击力和画面感 |
| 🏔️ 山脊之骨 | 理性分析派 | 逻辑清晰，用词精准，干脆利落 |
| 🌊 红潮之下 | 情绪感受派 | 浪漫带情绪，像波浪轻拍人心 |

## 🚀 主要功能

### 📸 图片发布与分析
- 支持多图片上传和预览
- AI深度分析图片内容、构图、色彩等
- 智能生成标题和描述建议
- 话题标签智能推荐

### ✍️ 文案建议
- 基于图片内容生成个性化配文
- 多个AI角色提供不同风格的建议
- 支持用户自定义话题和描述
- 实时预览和编辑功能

### 💬 智能评论系统
- AI角色自动生成有趣评论
- 支持用户与AI角色互动
- 评论风格与角色性格匹配
- 后台智能评论生成

### 📝 内容管理
- **草稿箱**: 保存未完成的创作内容
- **笔记本**: 收藏喜欢的帖子和AI建议
- **历史记录**: 查看所有创作历史
- **数据同步**: 本地数据安全存储

### 🎨 个性化设置
- 多种主题颜色选择
- AI角色偏好设置
- 用户资料自定义
- 隐私设置管理

## 🛠️ 技术栈

### 前端框架
- **Flutter 3.8.1+** - 跨平台UI框架
- **Dart 3.8.1+** - 编程语言

### 核心依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # UI组件
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.9
  
  # 权限管理
  permission_handler: ^11.3.0
  
  # 图片选择
  wechat_assets_picker: ^9.5.1
  photo_manager: ^3.6.0
  
  # 数据存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
  
  # 网络请求
  http: ^1.1.0
  
  # 加密
  crypto: ^3.0.3
  
  # 系统集成
  android_intent_plus: ^4.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
  flutter_launcher_icons: ^0.13.1
```

### AI服务集成
- **OpenAI GPT-4 Vision** - 图片分析和文本生成
- **Groq API** - 高速AI推理服务
- **自定义AI服务管理器** - 统一管理多个AI服务

### 数据存储
- **Hive** - 高性能本地数据库
- **SharedPreferences** - 用户偏好设置
- **本地文件系统** - 图片和媒体文件存储

## 📱 支持平台

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12.0+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Windows** (Windows 10+)
- ✅ **Linux** (Ubuntu 18.04+)
- ✅ **Web** (现代浏览器)

## 🚀 快速开始

### 环境要求
- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Android Studio / VS Code
- Git

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd ymir
```

2. **安装依赖**
```bash
flutter pub get
```

3. **生成代码**
```bash
flutter packages pub run build_runner build
```

4. **配置API密钥**
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String openaiApiKey = 'your-openai-api-key';
  static const String groqApiKey = 'your-groq-api-key';
  // ... 其他配置
}
```

5. **运行应用**
```bash
flutter run
```

### 构建发布版本

**Android APK**
```bash
flutter build apk --release
```

**iOS IPA**
```bash
flutter build ios --release
```

**桌面应用**
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 📁 项目结构说明

### 核心模块

#### 🎯 服务层 (Services)
- `AIServiceManager`: AI服务统一管理
- `ImageAnalysisService`: 图片分析核心服务
- `DraftService`: 草稿管理服务
- `NotesService`: 笔记管理服务
- `ChatService`: 聊天功能服务

#### 📊 数据模型 (Models)
- `PostModel`: 帖子数据模型
- `DraftModel`: 草稿数据模型（支持Hive持久化）
- `ChatModel`: 聊天消息模型

#### 🎨 UI组件 (Widgets)
- `FloatingNavBar`: 浮动导航栏
- `WaterGlassWidget`: 水球动画组件
- `ColorSliderWidget`: 颜色选择滑块
- `TopicSelectorWidget`: 话题选择器

#### ⚙️ 配置管理 (Config)
- `AICharactersConfig`: AI角色配置管理
- `ApiConfig`: API服务配置

## 🔧 开发指南

### 添加新的AI角色

1. 在 `lib/config/ai_characters_config.dart` 中添加角色配置：
```dart
AICharacterConfig(
  name: '新角色名称',
  description: '角色描述',
  basePersonality: '基础性格设定',
  imageCommentPrompt: '图片评论提示词',
  captionSuggestPrompt: '文案建议提示词',
  avatarColor: Colors.blue,
  avatar: 'assets/images/AI/新角色.png',
  temperature: 0.7,
  maxTokens: 200,
),
```

2. 添加角色头像到 `assets/images/AI/` 目录

3. 更新 `pubspec.yaml` 中的资源配置

### 自定义主题

在 `lib/screens/main_screen.dart` 中修改主题颜色：
```dart
final List<Color> _themeColors = [
  const Color(0xFF2463b3), // 蓝色
  const Color(0xFFa18dc1), // 紫色
  // 添加更多颜色...
];
```

### 扩展API服务

1. 创建新的API服务类继承基础服务
2. 在 `AIServiceManager` 中注册新服务
3. 更新相关配置文件

## 🐛 常见问题

### Q: 应用启动时崩溃
A: 检查是否正确配置了API密钥，确保所有依赖都已正确安装。

### Q: 图片分析功能不工作
A: 确认网络连接正常，API密钥有效，且有足够的API配额。

### Q: AI角色头像不显示
A: 检查 `assets/images/AI/` 目录中是否存在对应的图片文件。

### Q: 数据丢失问题
A: YMIR使用本地存储，数据保存在设备本地。卸载应用会清除所有数据。

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目为私有项目，未经授权不得复制、分发或修改。

---

<div align="center">
  <p>用 ❤️ 和 Flutter 构建</p>
  <p>© 2025 YMIR Team. All rights reserved.</p>
</div> 