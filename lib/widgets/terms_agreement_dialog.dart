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
        'Welcome to Ymir',
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
            'Before you begin, please read and agree to our Terms of Service and Privacy Policy.',
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
                const TextSpan(text: 'By selecting "Agree and Continue," you confirm that you have read and agree to our '),
                TextSpan(
                  text: 'Terms of Service',
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
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
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
                const TextSpan(text: '.'),
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
              'Important:\n• This app primarily runs locally on your device\n• It connects to the internet only when you use AI features\n• Your personal data is stored securely on your device',
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
            'Decline',
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
            'Agree and Continue',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
} 