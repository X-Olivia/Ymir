# Secure API Key Configuration Guide

## Overview
This project uses a separate configuration file to prevent your API keys from being accidentally committed to version control.

## Setup

### 1. Configure API Keys
Your API keys are stored in `lib/config/api_keys.dart`. This file has been added to `.gitignore` and will not be committed to the Git repository.

### 2. Resetting Keys
To change an API key:
1. Edit `lib/config/api_keys.dart`
2. Replace the corresponding placeholder with your actual API key

### 3. Team Collaboration
Other developers who need to run this project should:
1. Copy `lib/config/api_keys.example.dart` to `lib/config/api_keys.dart`
2. Enter their own API keys in the new file

## Security Best Practices

### ✅ Recommended
- Store API keys in a separate configuration file
- Add the configuration file to `.gitignore`
- Provide an example configuration file for reference
- Reference keys from code instead of hard-coding them

### ❌ Avoid
- Do not hard-code API keys directly in source code
- Do not commit files containing real API keys to version control
- Do not share API keys publicly
- Do not include API keys in logs or error messages

## File Reference

- `lib/config/api_keys.dart` - Actual API key configuration (ignored)
- `lib/config/api_keys.example.dart` - Example configuration file (committed)
- `lib/config/api_config.dart` - API configuration class (references the key file)

## Obtaining API Keys

### Groq API
1. Visit the [Groq Console](https://console.groq.com/keys)
2. Create an account and sign in
3. Create a new API key
4. Copy the key into the configuration file

### OpenAI API (If Needed)
1. Visit the [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account and sign in
3. Create a new API key
4. Copy the key into the configuration file

## Troubleshooting

If you encounter an "API key not configured" error:
1. Confirm that `lib/config/api_keys.dart` exists
2. Confirm that the API key in the file is not placeholder text
3. Confirm that the API key has the correct format and is valid

## Environment Variable Approach (Advanced)

If you prefer to use environment variables:
1. Set the `GROQ_API_KEY` environment variable on your system
2. Modify `api_keys.dart` to use `Platform.environment['GROQ_API_KEY']`

Note: Environment variables may not be suitable when a Flutter app runs on a mobile device.