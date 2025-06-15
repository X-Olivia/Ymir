import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  final Color? themeColor;

  const TermsOfServicePage({
    super.key,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务条款'),
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
              '本服务条款自2025年6月14日起生效。',
            ),
            _buildSection(
              '接受条款',
              '通过下载、安装或使用Ymir应用，您表示同意遵守本服务条款。如果您不同意这些条款，请不要使用本应用。',
            ),
            _buildSection(
              '服务描述',
              '''Ymir提供以下服务：

• AI图片分析和描述生成
• 智能文案创作辅助
• 多角色AI聊天互动
• 本地内容管理和存储

本应用主要在您的设备上运行，仅在必要时连接网络以提供AI服务。''',
            ),
            _buildSection(
              '用户责任',
              '''使用本应用时，您同意：

• 仅将应用用于合法目的
• 不上传违法、有害或不当的内容
• 不尝试破解、逆向工程或干扰应用功能
• 遵守所有适用的法律法规
• 对您的设备和账户安全负责''',
            ),
            _buildSection(
              '内容所有权',
              '''• 您保留对上传内容的所有权利
• 您授权我们在提供服务时使用您的内容
• AI生成的内容归您所有
• 我们不声称对用户内容的所有权
• 您有责任确保上传内容不侵犯他人权利''',
            ),
            _buildSection(
              '服务可用性',
              '''• 我们努力保持服务的可用性，但不保证100%无中断
• AI服务依赖第三方提供商，可能偶尔不可用
• 我们可能因维护、更新或其他原因暂停服务
• 本地功能不受网络服务影响''',
            ),
            _buildSection(
              '免责声明',
              '''• 本应用按"现状"提供，不提供任何明示或暗示的保证
• 我们不保证AI生成内容的准确性或适用性
• 您使用AI生成的内容需自行承担风险
• 我们不对因使用应用而产生的任何损失负责''',
            ),
            _buildSection(
              '责任限制',
              '''在法律允许的最大范围内：

• 我们的责任限于您支付的费用（如适用）
• 我们不对间接、偶然或后果性损害负责
• 我们不对数据丢失或设备损坏负责
• 您同意自行承担使用风险''',
            ),
            _buildSection(
              '知识产权',
              '''• Ymir应用及其设计受知识产权法保护
• 您不得复制、修改或分发应用代码
• 应用中的商标和标识归我们所有
• 第三方内容的权利归其各自所有者''',
            ),
            _buildSection(
              '隐私保护',
              '我们重视您的隐私。请查看我们的隐私政策了解详细信息。本服务条款与隐私政策共同构成我们与您之间的完整协议。',
            ),
            _buildSection(
              '服务终止',
              '''• 您可以随时停止使用应用并删除它
• 我们可能因违反条款而终止您的使用权
• 终止后，相关条款仍然有效
• 本地数据在卸载应用时会被删除''',
            ),
            _buildSection(
              '条款修改',
              '我们可能会更新这些服务条款。重大变更时，我们会在应用内通知您。继续使用应用表示您接受修改后的条款。',
            ),
            _buildSection(
              '适用法律',
              '本服务条款受中华人民共和国法律管辖。任何争议应通过友好协商解决，协商不成的，提交有管辖权的人民法院解决。',
            ),
            _buildSection(
              '联系信息',
              '''如果您对本服务条款有任何疑问，请联系我们：

邮箱：xj_olivia@outlook.com


我们会及时回复您的询问。''',
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