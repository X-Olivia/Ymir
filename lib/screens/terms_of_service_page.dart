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
        title: const Text('Terms of Service'),
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
              'These Terms of Service are effective as of June 14, 2025.',
            ),
            _buildSection(
              'Acceptance of Terms',
              'By downloading, installing, or using the Ymir app, you agree to comply with these Terms of Service. If you do not agree to these terms, do not use the app.',
            ),
            _buildSection(
              'Service Description',
              '''Ymir provides the following services:

• AI image analysis and description generation
• AI-assisted caption writing
• Multi-character AI chat
• Local content management and storage

The app runs primarily on your device and connects to the internet only when necessary to provide AI services.''',
            ),
            _buildSection(
              'User Responsibilities',
              '''When using the app, you agree to:

• Use the app only for lawful purposes
• Not upload illegal, harmful, or inappropriate content
• Not attempt to crack, reverse-engineer, or interfere with the app
• Comply with all applicable laws and regulations
• Take responsibility for the security of your device and account''',
            ),
            _buildSection(
              'Content Ownership',
              '''• You retain all rights to content you upload
• You authorize us to use your content to provide the service
• You own AI-generated content
• We do not claim ownership of user content
• You are responsible for ensuring uploaded content does not infringe the rights of others''',
            ),
            _buildSection(
              'Service Availability',
              '''• We strive to keep the service available but do not guarantee uninterrupted availability
• AI services depend on third-party providers and may occasionally be unavailable
• We may suspend the service for maintenance, updates, or other reasons
• Local features are unaffected by network service availability''',
            ),
            _buildSection(
              'Disclaimer',
              '''• The app is provided "as is," without express or implied warranties
• We do not guarantee the accuracy or suitability of AI-generated content
• You use AI-generated content at your own risk
• We are not liable for losses arising from use of the app''',
            ),
            _buildSection(
              'Limitation of Liability',
              '''To the fullest extent permitted by law:

• Our liability is limited to the fees you paid, if applicable
• We are not liable for indirect, incidental, or consequential damages
• We are not liable for data loss or device damage
• You agree to use the app at your own risk''',
            ),
            _buildSection(
              'Intellectual Property',
              '''• The Ymir app and its design are protected by intellectual property laws
• You may not copy, modify, or distribute the app's code
• Trademarks and logos in the app belong to us
• Rights to third-party content belong to their respective owners''',
            ),
            _buildSection(
              'Privacy',
              'We value your privacy. Please review our Privacy Policy for details. These Terms of Service and the Privacy Policy together constitute the entire agreement between you and us.',
            ),
            _buildSection(
              'Termination',
              '''• You may stop using and delete the app at any time
• We may terminate your right to use the app if you violate these terms
• Relevant provisions remain effective after termination
• Local data is deleted when the app is uninstalled''',
            ),
            _buildSection(
              'Changes to These Terms',
              'We may update these Terms of Service. We will notify you in the app of material changes. Continued use of the app means you accept the revised terms.',
            ),
            _buildSection(
              'Governing Law',
              'These Terms of Service are governed by the laws of the People\'s Republic of China. Any dispute should first be resolved through amicable negotiation. If negotiation fails, the dispute shall be submitted to a people\'s court with jurisdiction.',
            ),
            _buildSection(
              'Contact Information',
              '''If you have any questions about these Terms of Service, please contact us:

Email: xj_olivia@outlook.com


We will respond to your inquiry promptly.''',
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