import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final Color? themeColor;

  const PrivacyPolicyPage({
    super.key,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: effectiveThemeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '生效日期',
              '本隐私政策自2025年6月14日起生效。',
            ),
            _buildSection(
              '应用概述',
              'Ymir是一款AI驱动的内容创作应用，主要功能包括图片分析、文案生成和AI聊天。本应用采用本地存储设计，最大程度保护用户隐私。',
            ),
            _buildSection(
              '信息收集',
              '''我们收集的信息类型：

• 用户主动提供的信息：
  - 用户昵称和个人资料设置
  - 上传的图片（仅用于AI分析）
  - 创建的文案和笔记内容

• 自动收集的信息：
  - 应用使用统计（本地存储）
  - 错误日志（本地存储）

重要说明：所有个人数据均存储在您的设备本地，我们不会将这些信息上传到我们的服务器。''',
            ),
            _buildSection(
              'API服务使用',
              '''为提供AI功能，我们会：

• 将您选择的图片发送给第三方AI服务提供商进行分析
• 发送文本内容给AI服务以生成回复
• 这些数据传输仅用于提供服务，不会被永久存储

我们使用的AI服务提供商：
• 遵循严格的数据保护标准
• 不会保留或使用您的数据进行其他目的
• 传输过程采用加密保护''',
            ),
            _buildSection(
              '数据存储',
              '''• 所有用户数据存储在设备本地
• 使用加密存储保护敏感信息
• 卸载应用时，所有本地数据将被删除
• 我们无法访问您设备上的任何数据''',
            ),
            _buildSection(
              '权限使用',
              '''应用请求的权限及用途：

• 照片库访问权限：
  - 仅用于选择要分析的图片
  - 不会自动上传或备份您的照片
  - 您可以随时在系统设置中撤销此权限''',
            ),
            _buildSection(
              '数据共享',
              '''我们不会与第三方共享您的个人信息，除非：

• 获得您的明确同意
• 法律法规要求
• 保护我们的合法权益

注意：发送给AI服务的数据仅用于提供服务，不构成数据共享。''',
            ),
            _buildSection(
              '用户权利',
              '''您拥有以下权利：

• 随时删除本地存储的所有数据
• 选择不使用需要网络连接的功能
• 在设备设置中管理应用权限
• 联系我们了解数据处理情况''',
            ),
            _buildSection(
              '安全措施',
              '''我们采取以下措施保护您的信息：

• 本地加密存储
• 网络传输加密
• 最小化数据收集原则
• 定期安全更新''',
            ),
            _buildSection(
              '儿童隐私',
              '本应用适合所有年龄段用户使用。我们不会故意收集13岁以下儿童的个人信息。如果您是儿童的监护人，发现儿童向我们提供了个人信息，请联系我们。',
            ),
            _buildSection(
              '政策更新',
              '我们可能会不时更新本隐私政策。重大变更时，我们会在应用内通知您。继续使用应用即表示您接受更新后的政策。',
            ),
            _buildSection(
              '联系我们',
              '''如果您对本隐私政策有任何疑问，请联系我们：

邮箱：xj_olivia@outlook.com

我们会在收到询问后尽快回复。''',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 