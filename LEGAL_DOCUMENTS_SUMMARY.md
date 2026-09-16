# Ymir Legal Documents Summary

## 📋 Document Overview

Legal documents have been created to reflect Ymir's nature as a **standalone app that connects to the internet only for API requests**, including:

1. **Privacy Policy** (`lib/screens/privacy_policy_page.dart`)
2. **Terms of Service** (`lib/screens/terms_of_service_page.dart`)
3. **User Agreement Confirmation Dialog** (`lib/widgets/terms_agreement_dialog.dart`)

## 🔒 Privacy Policy Highlights

### Data Collection Minimization
- **Local Storage First**: All user data is stored locally on the device
- **Transparent API Usage**: Clearly states that data is sent to third parties only when AI features are used
- **No Server Storage**: Emphasizes that we do not store users' personal data on our servers

### Permission Usage
- **Photo Library Permission**: Used only to select images for AI analysis
- **Network Permission**: Used only for AI API requests
- **User Control**: Users can revoke permissions at any time

### Data Security
- **Encrypted Storage**: Local data is protected with encryption
- **Encrypted Transmission**: API requests are encrypted using HTTPS
- **Data Deletion**: All data is automatically deleted when the app is uninstalled

## 📜 Terms of Service Highlights

### Scope of Service
- **AI Features**: Image analysis, caption generation, and AI chat
- **Local Features**: Content management and draft storage
- **Network Dependency**: Clearly states that AI features require an internet connection

### User Responsibilities
- **Lawful Use**: Users must not upload illegal content
- **Content Responsibility**: Users are responsible for the content they upload
- **Device Security**: Users are responsible for the security of their devices and data

### Disclaimers
- **AI Accuracy**: The accuracy of AI-generated content is not guaranteed
- **Service Availability**: Uninterrupted service is not guaranteed
- **Limitation of Liability**: The developer's liability is limited

## 🎯 Provisions Specific to a Standalone App

### 1. Local Data Storage
```
• All user data is stored locally on the device
• Sensitive information is protected using encrypted storage
• All local data is deleted when the app is uninstalled
• We cannot access any data on your device
```

### 2. Transparent API Usage
```
• Images you select are sent to third-party AI service providers for analysis
• Text content is sent to AI services to generate responses
• These transfers are used only to provide the service and are not stored permanently
```

### 3. Principle of Least Privilege
```
• Photo library access: Used only to select images for analysis
• Your photos are never uploaded or backed up automatically
• You can revoke this permission in system settings at any time
```

## 🔧 Technical Implementation

### Page Integration
- **Privacy Settings Page**: Navigation links to legal documents have been added
- **First Use**: The user agreement confirmation dialog can optionally be shown
- **Anytime Access**: Users can view the legal documents at any time

### User Experience
- **Clear Navigation**: Legal documents are directly accessible from privacy settings
- **Clickable Links**: Users can jump directly from the agreement dialog to the detailed terms
- **Localized Language**: Uses the target users' preferred language

## ⚖️ Legal Compliance

### App Store Requirements
- ✅ **Privacy Policy**: Meets App Store privacy policy requirements
- ✅ **Data Usage Disclosure**: Clearly explains how data is collected and used
- ✅ **Third-Party Services**: Discloses the use of AI API services

### Data Protection Regulations
- ✅ **GDPR Compatible**: The terms are compatible with GDPR requirements
- ✅ **User Rights**: Clearly defines users' control over their data
- ✅ **Transparency**: Clearly explains how data is processed

### Child Protection
- ✅ **Age Appropriate**: Rated 4+ and suitable for all users

## 📝 Content Requiring Customization

Update the following information before release:

1. **Contact Email**:
   - xj_olivia@outlook.com


3. **Effective Date**:
   - Adjust the date based on the actual release date

4. **AI Service Providers**:
   - Name specific AI services where applicable

## 🚀 Recommendations

1. **First Launch**: Consider displaying the user agreement confirmation when the app first launches
2. **Regular Updates**: Update legal documents promptly as features change
3. **User Notifications**: Notify users in the app of significant changes
4. **Legal Advice**: Consult a qualified legal professional if you have questions

---
*Created: June 2025*
*Applicable Version: Ymir 1.0.0*