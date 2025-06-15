# API密钥安全配置指南

## 概述
为了保护你的API密钥不被意外提交到版本控制系统，本项目采用了分离配置的方式。

## 设置步骤

### 1. 配置API密钥
你的API密钥现在存储在 `lib/config/api_keys.dart` 文件中。这个文件已经被添加到 `.gitignore`，不会被提交到Git仓库。

### 2. 如果需要重新设置
如果你需要修改API密钥：
1. 编辑 `lib/config/api_keys.dart` 文件
2. 将你的实际API密钥替换相应的占位符

### 3. 团队协作
如果有其他开发者需要运行这个项目：
1. 他们需要复制 `lib/config/api_keys.example.dart` 为 `lib/config/api_keys.dart`
2. 在新文件中填入他们自己的API密钥

## 安全最佳实践

### ✅ 推荐做法
- API密钥存储在单独的配置文件中
- 配置文件已添加到 `.gitignore`
- 提供示例配置文件供参考
- 在代码中通过引用获取密钥，而不是硬编码

### ❌ 避免做法
- 不要在代码中直接硬编码API密钥
- 不要将包含真实API密钥的文件提交到版本控制
- 不要在公开的地方分享API密钥
- 不要在日志或错误信息中输出API密钥

## 文件说明

- `lib/config/api_keys.dart` - 实际的API密钥配置（已忽略）
- `lib/config/api_keys.example.dart` - 示例配置文件（会被提交）
- `lib/config/api_config.dart` - API配置类（引用密钥文件）

## 获取API密钥

### Groq API
1. 访问 [Groq Console](https://console.groq.com/keys)
2. 注册账号并登录
3. 创建新的API密钥
4. 将密钥复制到配置文件中

### OpenAI API（如果需要）
1. 访问 [OpenAI Platform](https://platform.openai.com/api-keys)
2. 注册账号并登录
3. 创建新的API密钥
4. 将密钥复制到配置文件中

## 故障排除

如果遇到"API密钥未配置"的错误：
1. 确认 `lib/config/api_keys.dart` 文件存在
2. 确认文件中的API密钥不是占位符文本
3. 确认API密钥格式正确且有效

## 环境变量方式（高级）

如果你更喜欢使用环境变量，可以：
1. 在系统中设置环境变量 `GROQ_API_KEY`
2. 修改 `api_keys.dart` 文件使用 `Platform.environment['GROQ_API_KEY']`

注意：Flutter应用在移动设备上运行时，环境变量方式可能不适用。 