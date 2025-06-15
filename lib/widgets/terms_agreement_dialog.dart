import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../screens/privacy_policy_page.dart';
import '../screens/terms_of_service_page.dart';

class TermsAgreementDialog extends StatelessWidget {
  final Color? themeColor;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TermsAgreementDialog({
    super.key,
    this.themeColor,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? Theme.of(context).primaryColor;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        '欢迎使用 Ymir',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '在开始使用之前，请阅读并同意我们的服务条款和隐私政策。',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: '点击"同意并继续"即表示您已阅读并同意我们的 '),
                TextSpan(
                  text: '服务条款',
                  style: TextStyle(
                    color: effectiveThemeColor,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TermsOfServicePage(
                            themeColor: themeColor,
                          ),
                        ),
                      );
                    },
                ),
                const TextSpan(text: ' 和 '),
                TextSpan(
                  text: '隐私政策',
                  style: TextStyle(
                    color: effectiveThemeColor,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivacyPolicyPage(
                            themeColor: themeColor,
                          ),
                        ),
                      );
                    },
                ),
                const TextSpan(text: '。'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '重要提示：\n• 本应用主要在您的设备本地运行\n• 仅在使用AI功能时连接网络\n• 您的个人数据安全存储在本地',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDecline,
          child: Text(
            '不同意',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveThemeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            '同意并继续',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
} 