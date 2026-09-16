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
        title: const Text('Privacy Policy'),
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
              'Effective Date',
              'This Privacy Policy is effective as of June 14, 2025.',
            ),
            _buildSection(
              'App Overview',
              'Ymir is an AI-powered content creation app whose main features include image analysis, caption generation, and AI chat. The app uses local storage to maximize user privacy.',
            ),
            _buildSection(
              'Information We Collect',
              '''Types of information we collect:

• Information you provide:
  - Your nickname and profile settings
  - Uploaded images (used only for AI analysis)
  - Captions and notes you create

• Information collected automatically:
  - App usage statistics (stored locally)
  - Error logs (stored locally)

Important: All personal data is stored locally on your device. We do not upload this information to our servers.''',
            ),
            _buildSection(
              'Use of API Services',
              '''To provide AI features, we:

• Send images you select to third-party AI service providers for analysis
• Send text to AI services to generate responses
• Use these data transfers solely to provide the service; the data is not stored permanently

The AI service providers we use:
• Follow strict data protection standards
• Do not retain or use your data for other purposes
• Encrypt data in transit''',
            ),
            _buildSection(
              'Data Storage',
              '''• All user data is stored locally on your device
• Sensitive information is protected with encrypted storage
• All local data is deleted when you uninstall the app
• We cannot access any data on your device''',
            ),
            _buildSection(
              'How We Use Permissions',
              '''Permissions requested by the app and how they are used:

• Photo library access:
  - Used only to select images for analysis
  - Your photos are never uploaded or backed up automatically
  - You can revoke this permission at any time in system settings''',
            ),
            _buildSection(
              'Data Sharing',
              '''We do not share your personal information with third parties unless:

• You give your explicit consent
• Required by law or regulation
• Necessary to protect our legitimate rights and interests

Note: Data sent to AI services is used only to provide the service and is not considered data sharing.''',
            ),
            _buildSection(
              'Your Rights',
              '''You have the right to:

• Delete all locally stored data at any time
• Choose not to use features that require a network connection
• Manage app permissions in your device settings
• Contact us to learn how your data is processed''',
            ),
            _buildSection(
              'Security Measures',
              '''We take the following measures to protect your information:

• Encrypted local storage
• Encrypted network transmission
• Data minimization
• Regular security updates''',
            ),
            _buildSection(
              'Children\'s Privacy',
              'This app is suitable for users of all ages. We do not knowingly collect personal information from children under 13. If you are a child\'s guardian and discover that the child has provided us with personal information, please contact us.',
            ),
            _buildSection(
              'Policy Updates',
              'We may update this Privacy Policy from time to time. We will notify you in the app of material changes. By continuing to use the app, you accept the updated policy.',
            ),
            _buildSection(
              'Contact Us',
              '''If you have any questions about this Privacy Policy, please contact us:

Email: xj_olivia@outlook.com

We will respond as soon as possible after receiving your inquiry.''',
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