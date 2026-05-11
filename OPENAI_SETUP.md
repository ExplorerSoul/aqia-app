# OpenAI Setup for AQIA

To enable AI-powered interview questions and feedback:

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Add your key using one of these methods:

**Option A: Environment variable (recommended for deployment)**
```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

**Option B: Config file**
Edit `lib/config/keys.dart` and set:
```dart
const String openAiApiKey = 'sk-your-key-here';
```

If no key is configured, the app uses built-in questions and mock feedback.
